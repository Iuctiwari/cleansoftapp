export const TENANT_STATUS_LOOKUP = Symbol('TENANT_STATUS_LOOKUP');

/**
 * Read-only cross-service lookup of tenant-service's own Tenant.status field.
 * Implementations MUST return null (never throw) on "not found" AND on any
 * connectivity/timeout failure — TenantStatusGuard treats null as "unknown,
 * fail open," the same way it treats a missing TenantSubscription record.
 */
export interface TenantStatusLookup {
  getTenantStatus(tenantId: string): Promise<string | null>;
}

/**
 * tenant-service's own Tenant.status enum values that indicate the tenant
 * account itself has been suspended/cancelled at the platform level (distinct
 * from — and in addition to — this service's own TenantSubscription.status).
 * Sourced from apps/backend/tenant-service/src/tenant/tenant.types.ts —
 * read-only reference, tenant-service is not modified.
 */
export const TENANT_SERVICE_BLOCKING_STATUSES: readonly string[] = ['Suspended', 'Cancelled'];
