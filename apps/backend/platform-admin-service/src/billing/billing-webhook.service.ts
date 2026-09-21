import { createHmac, timingSafeEqual } from 'node:crypto';

import { BadRequestException, Inject, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import {
  SUBSCRIPTION_HISTORY_REPOSITORY,
  TENANT_SUBSCRIPTION_REPOSITORY,
  SubscriptionHistoryAction,
  TenantSubscriptionStatus,
  type SubscriptionHistoryRepository,
  type TenantSubscriptionRepository,
} from '../subscription/subscription.types';
import { addBillingCycle } from './billing.util';
import {
  BILLING_ATTEMPT_REPOSITORY,
  RAZORPAY_WEBHOOK_ACTOR_ID,
  type BillingAttemptRepository,
  type RazorpayWebhookEnvelope,
  type RazorpayWebhookPaymentEntity,
} from './billing.types';

/**
 * Verifies and processes inbound Razorpay webhooks. Signature verification is
 * reimplemented here (HMAC-SHA256 over the raw body, compared with
 * crypto.timingSafeEqual) rather than using the razorpay package's own
 * Razorpay.validateWebhookSignature — that helper compares with plain `===`,
 * which leaks timing information; timingSafeEqual matches the pattern
 * auth-service already uses for its own token comparisons
 * (apps/backend/auth-service/src/auth/auth.crypto.ts secureEqual).
 */
@Injectable()
export class BillingWebhookService {
  private readonly logger = new Logger(BillingWebhookService.name);

  constructor(
    private readonly configService: ConfigService,
    @Inject(BILLING_ATTEMPT_REPOSITORY) private readonly billingAttempts: BillingAttemptRepository,
    @Inject(TENANT_SUBSCRIPTION_REPOSITORY)
    private readonly subscriptions: TenantSubscriptionRepository,
    @Inject(SUBSCRIPTION_HISTORY_REPOSITORY)
    private readonly history: SubscriptionHistoryRepository,
  ) {}

  /**
   * Verifies the signature and, only if valid, dispatches the event. Throws
   * BadRequestException (→ HTTP 400) on any signature failure — the payload
   * is never inspected, parsed as an event, or acted on before this passes.
   */
  async processWebhook(
    rawBody: Buffer,
    signatureHeader: string | undefined,
    eventIdHeader: string | undefined,
  ): Promise<void> {
    if (!signatureHeader || !this.isValidSignature(rawBody, signatureHeader)) {
      this.logger.warn(
        `Rejected Razorpay webhook: invalid or missing signature (eventId=${eventIdHeader ?? 'unknown'})`,
      );
      throw new BadRequestException('Invalid webhook signature');
    }

    if (!eventIdHeader) {
      this.logger.warn('Rejected Razorpay webhook: missing x-razorpay-event-id header');
      throw new BadRequestException('Missing x-razorpay-event-id header');
    }

    let envelope: RazorpayWebhookEnvelope;
    try {
      envelope = JSON.parse(rawBody.toString('utf8')) as RazorpayWebhookEnvelope;
    } catch {
      throw new BadRequestException('Invalid webhook payload');
    }

    await this.handleEvent(envelope, eventIdHeader);
  }

  private isValidSignature(rawBody: Buffer, signatureHeader: string): boolean {
    const secret = this.configService.getOrThrow<string>('RAZORPAY_WEBHOOK_SECRET');
    const expectedHex = createHmac('sha256', secret).update(rawBody).digest('hex');

    const expectedBuffer = Buffer.from(expectedHex, 'utf8');
    const actualBuffer = Buffer.from(signatureHeader, 'utf8');
    if (expectedBuffer.length !== actualBuffer.length) return false;

    return timingSafeEqual(expectedBuffer, actualBuffer);
  }

  private async handleEvent(envelope: RazorpayWebhookEnvelope, eventId: string): Promise<void> {
    switch (envelope.event) {
      case 'payment.captured':
        await this.handlePaymentCaptured(envelope, eventId);
        return;
      case 'payment.failed':
        await this.handlePaymentFailed(envelope, eventId);
        return;
      case 'order.paid':
        // order.paid fires alongside payment.captured for the same payment
        // (Razorpay docs: both are triggered when the order's payment is
        // captured). Acting on both would double-extend the subscription.
        // payment.captured carries the fuller payload (payment id + amount),
        // so that event is the one this service acts on; order.paid is
        // acknowledged only, never a second time processed.
        this.logger.log(
          `Acknowledged order.paid (handled via payment.captured) eventId=${eventId}`,
        );
        return;
      default:
        this.logger.log(
          `Ignoring unhandled Razorpay webhook event="${envelope.event}" eventId=${eventId}`,
        );
        return;
    }
  }

  private async handlePaymentCaptured(
    envelope: RazorpayWebhookEnvelope,
    eventId: string,
  ): Promise<void> {
    const payment = this.requirePaymentEntity(envelope, eventId, 'payment.captured');
    if (!payment) return;

    const attempt = await this.billingAttempts.findByRazorpayOrderId(payment.order_id);
    if (!attempt) {
      this.logger.warn(
        `payment.captured for unrecognized razorpayOrderId=${payment.order_id}; eventId=${eventId}`,
      );
      return;
    }

    const subscription = await this.subscriptions.findByTenantId(attempt.tenantId);
    if (!subscription) {
      this.logger.warn(
        `payment.captured for tenantId=${attempt.tenantId} with no TenantSubscription; eventId=${eventId}`,
      );
      return;
    }

    const now = new Date();
    const base = subscription.endDate && subscription.endDate > now ? subscription.endDate : now;
    const newEndDate = addBillingCycle(base, attempt.billingCycle);

    const recorded = await this.history.appendIfEventNotProcessed(
      {
        tenantId: attempt.tenantId,
        action: SubscriptionHistoryAction.PAYMENT_SUCCESS,
        previousValue: { status: subscription.status, endDate: subscription.endDate ?? null },
        newValue: {
          status: TenantSubscriptionStatus.ACTIVE,
          endDate: newEndDate,
          razorpayPaymentId: payment.id,
          razorpayOrderId: payment.order_id,
          amountInPaise: payment.amount,
        },
        actorAdminUserId: RAZORPAY_WEBHOOK_ACTOR_ID,
      },
      eventId,
    );

    if (!recorded) {
      this.logger.log(`Duplicate webhook delivery ignored (already processed) eventId=${eventId}`);
      return;
    }

    await this.subscriptions.upsert(attempt.tenantId, {
      status: TenantSubscriptionStatus.ACTIVE,
      endDate: newEndDate,
    });
    await this.billingAttempts.markPaid(attempt.id, payment.id);
  }

  private async handlePaymentFailed(
    envelope: RazorpayWebhookEnvelope,
    eventId: string,
  ): Promise<void> {
    const payment = this.requirePaymentEntity(envelope, eventId, 'payment.failed');
    if (!payment) return;

    const attempt = await this.billingAttempts.findByRazorpayOrderId(payment.order_id);
    if (!attempt) {
      this.logger.warn(
        `payment.failed for unrecognized razorpayOrderId=${payment.order_id}; eventId=${eventId}`,
      );
      return;
    }

    const recorded = await this.history.appendIfEventNotProcessed(
      {
        tenantId: attempt.tenantId,
        action: SubscriptionHistoryAction.PAYMENT_FAILED,
        newValue: {
          razorpayOrderId: payment.order_id,
          razorpayPaymentId: payment.id,
          failureReason:
            payment.error_description ?? payment.error_reason ?? payment.error_code ?? 'unknown',
        },
        actorAdminUserId: RAZORPAY_WEBHOOK_ACTOR_ID,
      },
      eventId,
    );

    if (!recorded) {
      this.logger.log(`Duplicate webhook delivery ignored (already processed) eventId=${eventId}`);
      return;
    }

    // Per plan: do NOT change TenantSubscription.status here. Grace-period
    // expiry -> PAST_DUE is a separate, not-yet-built decision (see
    // billing.module.ts for why).
    await this.billingAttempts.markFailed(attempt.id);
  }

  private requirePaymentEntity(
    envelope: RazorpayWebhookEnvelope,
    eventId: string,
    eventName: string,
  ): RazorpayWebhookPaymentEntity | null {
    const payment = envelope.payload?.payment?.entity;
    if (!payment) {
      this.logger.warn(`${eventName} webhook missing payment entity; eventId=${eventId}`);
      return null;
    }
    return payment;
  }
}
