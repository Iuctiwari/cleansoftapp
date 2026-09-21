import type {
  BillingCycle,
  SubscriptionPlanKey,
  TenantSubscriptionStatus,
} from '../subscription/subscription.types';

/** A plan as shown to a tenant — the admin-facing SubscriptionPlanRecord minus `id`/timestamps. */
export interface TenantPlanSummary {
  readonly planKey: SubscriptionPlanKey;
  readonly displayName: string;
  readonly monthlyPriceInPaise: number;
  readonly annualPriceInPaise: number;
  readonly trialDays: number;
  readonly includedModuleKeys: readonly string[];
  readonly maxBranches: number;
  readonly maxStaff: number;
  readonly maxMonthlyOrders: number;
}

export interface TenantSubscriptionSummary {
  readonly planKey: SubscriptionPlanKey;
  readonly status: TenantSubscriptionStatus;
  readonly billingCycle: BillingCycle;
  readonly startDate: Date;
  readonly endDate?: Date;
  readonly trialEndsAt?: Date;
  readonly autoRenew: boolean;
  /** Days until endDate (or trialEndsAt when no endDate is set yet) — null when neither is set. */
  readonly daysRemaining: number | null;
}

export interface TenantSubscriptionStatusResponse {
  readonly hasSubscription: boolean;
  readonly subscription?: TenantSubscriptionSummary;
  readonly plan?: TenantPlanSummary;
}
