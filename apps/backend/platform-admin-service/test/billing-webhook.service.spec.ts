/* eslint-disable @typescript-eslint/unbound-method, @typescript-eslint/no-unsafe-assignment */
import { createHmac } from 'node:crypto';

import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { BillingWebhookService } from '../src/billing/billing-webhook.service';
import {
  BillingAttemptStatus,
  RAZORPAY_WEBHOOK_ACTOR_ID,
  type BillingAttemptRecord,
  type BillingAttemptRepository,
} from '../src/billing/billing.types';
import {
  BillingCycle,
  SubscriptionHistoryAction,
  SubscriptionPlanKey,
  TenantSubscriptionStatus,
  type SubscriptionHistoryRecord,
  type SubscriptionHistoryRepository,
  type TenantSubscriptionRecord,
  type TenantSubscriptionRepository,
} from '../src/subscription/subscription.types';

const WEBHOOK_SECRET = '9282a1e03a861954d1f1fa296ff68ef173d279eadaeaec20';
const TENANT_ID = '64f0c18f7c4d2f0012ab3400';
const ORDER_ID = 'order_DESlLckIVRkHWj';
const PAYMENT_ID = 'pay_DESlfW9H8K9uqM';
const EVENT_ID = 'evt_1a2b3c4d5e6f';

function sign(rawBody: Buffer): string {
  return createHmac('sha256', WEBHOOK_SECRET).update(rawBody).digest('hex');
}

// Real payment.captured shape, per https://razorpay.com/docs/webhooks/payloads/payments/
function paymentCapturedBody(): Buffer {
  return Buffer.from(
    JSON.stringify({
      entity: 'event',
      account_id: 'acc_BFQ7uQEaa7j2z7',
      event: 'payment.captured',
      contains: ['payment'],
      created_at: 1567674606,
      payload: {
        payment: {
          entity: {
            id: PAYMENT_ID,
            entity: 'payment',
            amount: 99900,
            currency: 'INR',
            status: 'captured',
            order_id: ORDER_ID,
            method: 'netbanking',
            captured: true,
            error_code: null,
            error_description: null,
            created_at: 1567674599,
          },
        },
      },
    }),
  );
}

// Real payment.failed shape, per the same doc.
function paymentFailedBody(): Buffer {
  return Buffer.from(
    JSON.stringify({
      entity: 'event',
      account_id: 'acc_BFQ7uQEaa7j2z7',
      event: 'payment.failed',
      contains: ['payment'],
      created_at: 1567610215,
      payload: {
        payment: {
          entity: {
            id: 'pay_DEAU825sJlCbGa',
            entity: 'payment',
            amount: 50000,
            currency: 'INR',
            status: 'failed',
            order_id: ORDER_ID,
            method: 'netbanking',
            captured: false,
            error_code: 'BAD_REQUEST_ERROR',
            error_description: 'Payment failed',
            error_reason: 'payment_failed',
            created_at: 1567610214,
          },
        },
      },
    }),
  );
}

function buildAttempt(overrides: Partial<BillingAttemptRecord> = {}): BillingAttemptRecord {
  return {
    id: 'attempt-1',
    tenantId: TENANT_ID,
    razorpayOrderId: ORDER_ID,
    amountInPaise: 99900,
    currency: 'INR',
    billingCycle: BillingCycle.MONTHLY,
    planKeyAtCreation: SubscriptionPlanKey.PRO,
    status: BillingAttemptStatus.CREATED,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  };
}

function buildSubscription(
  overrides: Partial<TenantSubscriptionRecord> = {},
): TenantSubscriptionRecord {
  return {
    id: 'sub-1',
    tenantId: TENANT_ID,
    planKey: SubscriptionPlanKey.PRO,
    status: TenantSubscriptionStatus.TRIALING,
    startDate: new Date('2026-01-01'),
    billingCycle: BillingCycle.MONTHLY,
    autoRenew: false,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  };
}

describe('BillingWebhookService', () => {
  function buildConfigService(): ConfigService {
    return { getOrThrow: () => WEBHOOK_SECRET } as unknown as ConfigService;
  }

  function buildService(
    billingAttemptOverrides: Partial<BillingAttemptRepository> = {},
    subscriptionOverrides: Partial<TenantSubscriptionRepository> = {},
    historyOverrides: Partial<SubscriptionHistoryRepository> = {},
  ): {
    service: BillingWebhookService;
    billingAttempts: BillingAttemptRepository;
    subscriptions: TenantSubscriptionRepository;
    history: SubscriptionHistoryRepository;
  } {
    const billingAttempts: BillingAttemptRepository = {
      create: jest.fn(),
      findByRazorpayOrderId: jest.fn().mockResolvedValue(buildAttempt()),
      markPaid: jest.fn().mockResolvedValue(undefined),
      markFailed: jest.fn().mockResolvedValue(undefined),
      listByTenantId: jest.fn().mockResolvedValue([]),
      ...billingAttemptOverrides,
    };
    const subscriptions: TenantSubscriptionRepository = {
      findByTenantId: jest.fn().mockResolvedValue(buildSubscription()),
      upsert: jest
        .fn()
        .mockImplementation((tenantId: string, input: Partial<TenantSubscriptionRecord>) =>
          Promise.resolve(buildSubscription({ tenantId, ...input })),
        ),
      findManyByTenantIds: jest.fn().mockResolvedValue([]),
      search: jest.fn().mockResolvedValue([]),
      countAllGroupedByPlanKey: jest.fn().mockResolvedValue({}),
      ...subscriptionOverrides,
    };
    const history: SubscriptionHistoryRepository = {
      append: jest.fn(),
      listByTenantId: jest.fn().mockResolvedValue([]),
      appendIfEventNotProcessed: jest
        .fn()
        .mockImplementation((entry: Omit<SubscriptionHistoryRecord, 'id' | 'timestamp'>) =>
          Promise.resolve({ id: 'history-1', timestamp: new Date(), ...entry }),
        ),
      ...historyOverrides,
    };

    const service = new BillingWebhookService(
      buildConfigService(),
      billingAttempts,
      subscriptions,
      history,
    );

    return { service, billingAttempts, subscriptions, history };
  }

  it('(a) a valid payment.captured webhook updates TenantSubscription and writes SubscriptionHistory correctly', async () => {
    const { service, subscriptions, history } = buildService(
      {},
      {
        findByTenantId: jest
          .fn()
          .mockResolvedValue(
            buildSubscription({ status: TenantSubscriptionStatus.TRIALING, endDate: undefined }),
          ),
      },
    );
    const body = paymentCapturedBody();

    await service.processWebhook(body, sign(body), EVENT_ID);

    expect(history.appendIfEventNotProcessed).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: TENANT_ID,
        action: SubscriptionHistoryAction.PAYMENT_SUCCESS,
        actorAdminUserId: RAZORPAY_WEBHOOK_ACTOR_ID,
        newValue: expect.objectContaining({
          status: TenantSubscriptionStatus.ACTIVE,
          razorpayPaymentId: PAYMENT_ID,
          razorpayOrderId: ORDER_ID,
          amountInPaise: 99900,
        }),
      }),
      EVENT_ID,
    );
    expect(subscriptions.upsert).toHaveBeenCalledWith(
      TENANT_ID,
      expect.objectContaining({
        status: TenantSubscriptionStatus.ACTIVE,
        endDate: expect.any(Date),
      }),
    );
  });

  it('(b) a webhook with an INVALID signature is rejected with 400 and changes nothing in the database', async () => {
    const { service, billingAttempts, subscriptions, history } = buildService();
    const body = paymentCapturedBody();

    await expect(
      service.processWebhook(body, 'deadbeef'.repeat(8), EVENT_ID),
    ).rejects.toBeInstanceOf(BadRequestException);

    expect(billingAttempts.findByRazorpayOrderId).not.toHaveBeenCalled();
    expect(subscriptions.upsert).not.toHaveBeenCalled();
    expect(history.appendIfEventNotProcessed).not.toHaveBeenCalled();
  });

  it('rejects a webhook with a missing signature header', async () => {
    const { service, subscriptions } = buildService();
    const body = paymentCapturedBody();

    await expect(service.processWebhook(body, undefined, EVENT_ID)).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(subscriptions.upsert).not.toHaveBeenCalled();
  });

  it('(c) the same valid webhook event id processed twice results in exactly one mutation', async () => {
    let processed = false;
    const { service, subscriptions, billingAttempts, history } = buildService(
      {},
      {},
      {
        appendIfEventNotProcessed: jest
          .fn()
          .mockImplementation((entry: Omit<SubscriptionHistoryRecord, 'id' | 'timestamp'>) => {
            if (processed) return Promise.resolve(null); // simulates the real duplicate-key fail-open
            processed = true;
            return Promise.resolve({ id: 'history-1', timestamp: new Date(), ...entry });
          }),
      },
    );
    const body = paymentCapturedBody();
    const signature = sign(body);

    await service.processWebhook(body, signature, EVENT_ID);
    await service.processWebhook(body, signature, EVENT_ID);

    expect(history.appendIfEventNotProcessed).toHaveBeenCalledTimes(2);
    expect(subscriptions.upsert).toHaveBeenCalledTimes(1);
    expect(billingAttempts.markPaid).toHaveBeenCalledTimes(1);
  });

  it('(d) a payment.failed webhook writes a PAYMENT_FAILED history record and does NOT change TenantSubscription.status', async () => {
    const { service, subscriptions, history } = buildService();
    const body = paymentFailedBody();

    await service.processWebhook(body, sign(body), EVENT_ID);

    expect(history.appendIfEventNotProcessed).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: TENANT_ID,
        action: SubscriptionHistoryAction.PAYMENT_FAILED,
        actorAdminUserId: RAZORPAY_WEBHOOK_ACTOR_ID,
        newValue: expect.objectContaining({
          razorpayOrderId: ORDER_ID,
          razorpayPaymentId: 'pay_DEAU825sJlCbGa',
          failureReason: 'Payment failed',
        }),
      }),
      EVENT_ID,
    );
    expect(subscriptions.upsert).not.toHaveBeenCalled();
  });

  it('order.paid is acknowledged but never separately processed (avoids double-extension)', async () => {
    const { service, subscriptions, history } = buildService();
    const body = Buffer.from(JSON.stringify({ event: 'order.paid', payload: {} }));

    await service.processWebhook(body, sign(body), EVENT_ID);

    expect(history.appendIfEventNotProcessed).not.toHaveBeenCalled();
    expect(subscriptions.upsert).not.toHaveBeenCalled();
  });
});
