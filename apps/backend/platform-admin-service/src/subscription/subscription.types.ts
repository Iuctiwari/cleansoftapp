export enum SubscriptionPlanKey {
  FREE_TRIAL = 'FREE_TRIAL',
  STARTER = 'STARTER',
  PRO = 'PRO',
  ENTERPRISE = 'ENTERPRISE',
  CUSTOM = 'CUSTOM',
}

export enum TenantSubscriptionStatus {
  TRIALING = 'TRIALING',
  ACTIVE = 'ACTIVE',
  PAST_DUE = 'PAST_DUE',
  EXPIRED = 'EXPIRED',
  SUSPENDED = 'SUSPENDED',
  CANCELED = 'CANCELED',
}

/**
 * Enforcement mode locked in for Phase 2: "Read-Only Mode" — a tenant outside
 * good standing keeps read access but is blocked from write operations. Any
 * status not in this list is treated as not-in-good-standing.
 */
export const GOOD_STANDING_SUBSCRIPTION_STATUSES: readonly TenantSubscriptionStatus[] = [
  TenantSubscriptionStatus.TRIALING,
  TenantSubscriptionStatus.ACTIVE,
];

export enum BillingCycle {
  MONTHLY = 'MONTHLY',
  ANNUAL = 'ANNUAL',
}

export enum SubscriptionHistoryAction {
  PLAN_ASSIGNED = 'PLAN_ASSIGNED',
  PLAN_CHANGED = 'PLAN_CHANGED',
  STATUS_CHANGED = 'STATUS_CHANGED',
  EXTENDED = 'EXTENDED',
  PAYMENT_SUCCESS = 'PAYMENT_SUCCESS',
  PAYMENT_FAILED = 'PAYMENT_FAILED',
}

export interface SubscriptionPlanRecord {
  readonly id: string;
  readonly planKey: SubscriptionPlanKey;
  readonly displayName: string;
  readonly monthlyPriceInPaise: number;
  readonly annualPriceInPaise: number;
  readonly maxBranches: number;
  readonly maxStaff: number;
  readonly maxMonthlyOrders: number;
  readonly trialDays: number;
  readonly includedModuleKeys: readonly string[];
  readonly isActive: boolean;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface TenantSubscriptionRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly planKey: SubscriptionPlanKey;
  readonly status: TenantSubscriptionStatus;
  readonly startDate: Date;
  readonly endDate?: Date;
  readonly trialEndsAt?: Date;
  readonly branchLimit?: number;
  readonly staffLimit?: number;
  readonly monthlyOrderLimit?: number;
  readonly billingCycle: BillingCycle;
  readonly autoRenew: boolean;
  readonly notes?: string;
  readonly updatedByAdminUserId?: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface SubscriptionHistoryRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly action: SubscriptionHistoryAction;
  readonly previousValue?: Record<string, unknown>;
  readonly newValue: Record<string, unknown>;
  readonly actorAdminUserId: string;
  readonly reason?: string;
  /** Set only for webhook-driven entries — the Razorpay `x-razorpay-event-id`
   *  that produced this record. Enforced unique (when present) so the same
   *  webhook delivery can never produce two history records. */
  readonly razorpayEventId?: string;
  readonly timestamp: Date;
}

export const TENANT_SUBSCRIPTION_REPOSITORY = Symbol('TENANT_SUBSCRIPTION_REPOSITORY');
export const SUBSCRIPTION_HISTORY_REPOSITORY = Symbol('SUBSCRIPTION_HISTORY_REPOSITORY');

export interface TenantSubscriptionRepository {
  /** Returns null when no record exists — callers must fail open on null. */
  findByTenantId(tenantId: string): Promise<TenantSubscriptionRecord | null>;
  upsert(
    tenantId: string,
    input: Partial<Omit<TenantSubscriptionRecord, 'id' | 'tenantId' | 'createdAt' | 'updatedAt'>>,
  ): Promise<TenantSubscriptionRecord>;
  /** Batch lookup for enriching a page of tenants with their subscription — one query, not N. */
  findManyByTenantIds(tenantIds: readonly string[]): Promise<readonly TenantSubscriptionRecord[]>;
  /** Used by the Company Admin overview (filter by plan/status) and by
   *  plan-deletion's "tenants still assigned" check. */
  search(filter: {
    readonly planKey?: SubscriptionPlanKey;
    readonly status?: TenantSubscriptionStatus;
  }): Promise<readonly TenantSubscriptionRecord[]>;
  /** One aggregate query for the subscription-plan list's "tenants on this plan" counts. */
  countAllGroupedByPlanKey(): Promise<Readonly<Record<string, number>>>;
}

export interface SubscriptionHistoryRepository {
  append(
    entry: Omit<SubscriptionHistoryRecord, 'id' | 'timestamp'>,
  ): Promise<SubscriptionHistoryRecord>;
  listByTenantId(tenantId: string): Promise<readonly SubscriptionHistoryRecord[]>;
  /**
   * Idempotent write for webhook-driven entries: records `entry` tagged with
   * `razorpayEventId`, or returns null if a record for that event id already
   * exists (this exact webhook delivery was already processed). Callers MUST
   * treat null as "skip — do not apply any further mutation for this event."
   */
  appendIfEventNotProcessed(
    entry: Omit<SubscriptionHistoryRecord, 'id' | 'timestamp' | 'razorpayEventId'>,
    razorpayEventId: string,
  ): Promise<SubscriptionHistoryRecord | null>;
}
