import type { PaginatedResult, TrustedContext } from '../platform/platform.types';

export type BranchStatus = 'active' | 'inactive' | 'closed';

// Role codes as issued today by auth-service (see auth-service's seed
// accounts / TenantOwnerAuthMongoose.roleCode). 'branch_manager' does not
// exist in seed data yet — User Management (out of scope here) owns role
// assignment — but the check is written to recognize it once it does.
export const OWNER_ROLE_CODE = 'tenant_owner';
export const BRANCH_MANAGER_ROLE_CODE = 'branch_manager';

export interface BranchRecord {
  readonly branchId: string;
  readonly tenantId: string;
  readonly branchName: string;
  readonly code?: string;
  readonly streetAddress: string;
  readonly city: string;
  readonly state: string;
  readonly country: string;
  readonly postalCode: string;
  readonly phone: string;
  readonly email: string;
  readonly openingTime?: string;
  readonly closingTime?: string;
  readonly managerId?: string;
  readonly isHeadOffice: boolean;
  readonly status: BranchStatus;
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface BranchMetrics {
  readonly totalStaff: number;
  readonly totalOrders: number;
  readonly ordersToday: number;
}

export interface BranchView extends BranchRecord, BranchMetrics {
  readonly managerName?: string;
}

export interface BranchStatistics extends BranchMetrics {
  readonly totalBranches: number;
}

// Deliberately has no tenantId field — the service always derives tenantId
// from the trusted context, never from caller input, so there is nothing
// here to accidentally trust from the request body.
export interface CreateBranchInput {
  readonly branchName: string;
  readonly code?: string;
  readonly streetAddress?: string;
  readonly city?: string;
  readonly state?: string;
  readonly country?: string;
  readonly postalCode?: string;
  readonly phone: string;
  readonly email: string;
  readonly openingTime?: string;
  readonly closingTime?: string;
  readonly managerId?: string;
}

export interface UpdateBranchInput {
  readonly branchName?: string;
  readonly code?: string;
  readonly streetAddress?: string;
  readonly city?: string;
  readonly state?: string;
  readonly country?: string;
  readonly postalCode?: string;
  readonly phone?: string;
  readonly email?: string;
  readonly openingTime?: string;
  readonly closingTime?: string;
  readonly managerId?: string | null;
  readonly status?: 'active' | 'inactive';
}

export interface BranchQueryFilters {
  readonly branchId?: string;
  readonly status?: BranchStatus;
  readonly managerId?: string;
}

// A field set to `null` means "clear this field" ($unset); a field left
// `undefined` (i.e. omitted) means "leave unchanged". Only `managerId` is
// ever cleared today, but the type stays generic for future optional fields.
export type BranchUpdatePatch = {
  -readonly [K in keyof BranchRecord]?: BranchRecord[K] | null;
};

export interface BranchRepository {
  findByBranchIdAndTenant(branchId: string, tenantId: string): Promise<BranchRecord | null>;
  findByCodeAndTenant(code: string, tenantId: string): Promise<BranchRecord | null>;
  listCodesByTenant(tenantId: string): Promise<readonly string[]>;
  list(
    tenantId: string,
    filters: BranchQueryFilters,
    page: { page: number; pageSize: number },
  ): Promise<PaginatedResult<BranchRecord>>;
  countActiveByTenant(tenantId: string): Promise<number>;
  create(record: BranchRecord): Promise<BranchRecord>;
  update(branchId: string, tenantId: string, patch: BranchUpdatePatch): Promise<BranchRecord>;
}

export const BRANCH_REPOSITORY = Symbol('BRANCH_REPOSITORY');

/**
 * Manager eligibility check. Branch Management writes only `branches.managerId`
 * — it never mutates a user record. This is the "existing project pattern"
 * substitute for a dedicated UsersPublicService (see
 * implementation_guide/phases/phase-05-branch/02-prompt.md §3.1), which does
 * not exist yet because User Management (NEX-136's sibling ticket) has not
 * been implemented. Backed today by a read-only projection of auth-service's
 * `tenantOwners` collection — the only queryable tenant-user store that
 * currently exists.
 */
export interface ManagerEligibilityService {
  assertEligible(userId: string, tenantId: string): Promise<void>;
}

export const MANAGER_ELIGIBILITY_SERVICE = Symbol('MANAGER_ELIGIBILITY_SERVICE');

/**
 * Subscription branch-limit lookup. No subscription-plan collection with a
 * `branchLimit` field exists anywhere in the repository yet (subscriptionPlanId
 * on TenantRecord is a documented placeholder — see tenant.service.ts). This
 * interface is the seam a real tenant-service `getPlanLimits()` call plugs
 * into later; the current implementation is a configurable stand-in, not a
 * real subscription check.
 */
export interface BranchLimitProvider {
  getBranchLimit(tenantId: string): Promise<number>;
}

export const BRANCH_LIMIT_PROVIDER = Symbol('BRANCH_LIMIT_PROVIDER');

/** Read-only unresolved-order lookup used by branch deactivation checks. */
export interface OrdersGateway {
  countNonTerminalByBranch(tenantId: string, branchId: string): Promise<number>;
}

export const ORDERS_GATEWAY = Symbol('ORDERS_GATEWAY');

/**
 * Read-only operational projection used by Branch Management. It aggregates
 * the existing users/orders collections through the shared Mongoose
 * connection; it does not register schemas, create collections, or write
 * data owned by another service.
 */
export interface BranchMetricsGateway {
  getMetrics(
    tenantId: string,
    branchIds: readonly string[],
  ): Promise<ReadonlyMap<string, BranchMetrics>>;
  getManagerNames(
    tenantId: string,
    managerIds: readonly string[],
  ): Promise<ReadonlyMap<string, string>>;
}

export const BRANCH_METRICS_GATEWAY = Symbol('BRANCH_METRICS_GATEWAY');

export interface BranchAuthorizationContext {
  readonly trustedContext: TrustedContext;
}
