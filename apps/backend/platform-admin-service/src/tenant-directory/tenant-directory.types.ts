/**
 * Sourced from tenant-service's internal HTTP endpoint (GET /internal/tenants,
 * /internal/tenants/:tenantId — see TenantInternalController there), not a
 * direct database read. Deliberately does NOT include subscriptionPlanId (a
 * known-dangling placeholder there — see Phase 2's report) or enrich with
 * this service's own TenantSubscription data; the tenant-subscriptions
 * endpoints already own that, and joining it in here for every row of a list
 * would add N+1 queries for a "minimal" addition. Callers select a tenant
 * here, then call the existing subscription/theme/module endpoints with its
 * tenantId.
 */
export interface TenantDirectoryEntry {
  readonly tenantId: string;
  readonly slug: string;
  readonly businessName: string;
  readonly businessType: string;
  readonly ownerName: string;
  readonly ownerEmail: string;
  readonly ownerPhone: string;
  readonly status: string;
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface TenantDirectoryQuery {
  /** Case-insensitive partial match on businessName, ownerEmail, or slug. */
  readonly search?: string;
  /** Exact match against tenant-service's own Tenant.status values. */
  readonly status?: string;
  readonly page?: number;
  readonly limit?: number;
}

export interface TenantDirectoryPage {
  readonly items: readonly TenantDirectoryEntry[];
  readonly page: number;
  readonly limit: number;
  readonly total: number;
}

/**
 * TenantDirectoryEntry enriched with this service's own TenantSubscription
 * data (planKey/status/daysRemaining) — undefined/null fields mean the
 * tenant has no subscription record yet (today's default state).
 */
export interface TenantOverviewEntry extends TenantDirectoryEntry {
  readonly planKey?: string;
  readonly subscriptionStatus?: string;
  /** Days until endDate (or trialEndsAt while trialing); null if neither is set. */
  readonly daysRemaining?: number | null;
}

export interface TenantOverviewQuery {
  /** Exact single-tenant lookup — when set, every other filter is ignored. */
  readonly tenantId?: string;
  /** Case-insensitive partial match on businessName or ownerName. */
  readonly search?: string;
  /** tenant-service's own onboarding status (PendingVerification/Active/Suspended/Cancelled). */
  readonly onboardingStatus?: string;
  /** TenantSubscriptionStatus (TRIALING/ACTIVE/PAST_DUE/EXPIRED/SUSPENDED/CANCELED). */
  readonly subscriptionStatus?: string;
  readonly planKey?: string;
  readonly page?: number;
  readonly limit?: number;
}

export interface TenantOverviewPage {
  readonly items: readonly TenantOverviewEntry[];
  readonly page: number;
  readonly limit: number;
  readonly total: number;
}

export const TENANT_DIRECTORY_REPOSITORY = Symbol('TENANT_DIRECTORY_REPOSITORY');

export interface TenantDirectoryRepository {
  /** Throws (never silently returns an empty page) if tenant-service can't
   *  be reached — an admin list silently showing "0 tenants" on a
   *  connectivity blip would be actively misleading. */
  list(query: TenantDirectoryQuery): Promise<TenantDirectoryPage>;
  /** Fetches a specific set of tenants by id, unpaginated — used to enrich a
   *  known set of tenantIds (e.g. everyone on one subscription plan). */
  listByTenantIds(tenantIds: readonly string[]): Promise<readonly TenantDirectoryEntry[]>;
}
