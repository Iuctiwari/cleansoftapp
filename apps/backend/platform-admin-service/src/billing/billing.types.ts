import type { BillingCycle, SubscriptionPlanKey } from '../subscription/subscription.types';

/** Sentinel actorAdminUserId for SubscriptionHistory entries written by the
 *  Razorpay webhook handler rather than by a human admin action. */
export const RAZORPAY_WEBHOOK_ACTOR_ID = 'system:razorpay-webhook';

export enum BillingAttemptStatus {
  CREATED = 'CREATED',
  PAID = 'PAID',
  FAILED = 'FAILED',
}

export interface BillingAttemptRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly razorpayOrderId: string;
  readonly razorpayPaymentId?: string;
  readonly amountInPaise: number;
  readonly currency: string;
  readonly billingCycle: BillingCycle;
  readonly planKeyAtCreation: SubscriptionPlanKey;
  readonly status: BillingAttemptStatus;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export const BILLING_ATTEMPT_REPOSITORY = Symbol('BILLING_ATTEMPT_REPOSITORY');

export interface CreateBillingAttemptInput {
  readonly tenantId: string;
  readonly razorpayOrderId: string;
  readonly amountInPaise: number;
  readonly currency: string;
  readonly billingCycle: BillingCycle;
  readonly planKeyAtCreation: SubscriptionPlanKey;
}

export interface BillingAttemptRepository {
  create(input: CreateBillingAttemptInput): Promise<BillingAttemptRecord>;
  findByRazorpayOrderId(razorpayOrderId: string): Promise<BillingAttemptRecord | null>;
  markPaid(id: string, razorpayPaymentId: string): Promise<void>;
  markFailed(id: string): Promise<void>;
  /** Newest first — a tenant's payment/billing history for the Company Admin Clients tab. */
  listByTenantId(tenantId: string): Promise<readonly BillingAttemptRecord[]>;
}

// ─── Charge gateway abstraction ─────────────────────────────────────────────
// Everything above/below this line that calls Razorpay does so ONLY through
// this interface. Today's implementation (RazorpayOrderService) uses the
// Orders API — one order per billing cycle, manually triggered. If this later
// moves to the Subscriptions API (auto-recurring), only that implementation
// changes; BillingService and callers never see the difference.

export interface CreateChargeInput {
  readonly tenantId: string;
  readonly amountInPaise: number;
  readonly currency: string;
  readonly billingCycle: BillingCycle;
  readonly receipt: string;
  readonly notes?: Record<string, string>;
}

export interface CreatedCharge {
  readonly gatewayOrderId: string;
  readonly status: string;
}

export const BILLING_CHARGE_GATEWAY = Symbol('BILLING_CHARGE_GATEWAY');

export interface BillingChargeGateway {
  createChargeForCycle(input: CreateChargeInput): Promise<CreatedCharge>;
}

// ─── Razorpay webhook payload shapes (only the fields we read) ─────────────
// Sourced from https://razorpay.com/docs/webhooks/payloads/payments/ — not
// guessed. Deliberately loose/partial: we only declare fields this service
// actually consumes, not Razorpay's full payload.

export interface RazorpayWebhookPaymentEntity {
  readonly id: string;
  readonly order_id: string;
  readonly amount: number;
  readonly currency: string;
  readonly status: string;
  readonly error_code?: string | null;
  readonly error_description?: string | null;
  readonly error_reason?: string | null;
}

export interface RazorpayWebhookEnvelope {
  readonly entity?: string;
  readonly event: string;
  readonly payload?: {
    readonly payment?: {
      readonly entity?: RazorpayWebhookPaymentEntity;
    };
  };
}