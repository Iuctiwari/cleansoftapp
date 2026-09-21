import type { ModuleKey } from './module-key.enum';

export const TENANT_MODULE_ACCESS_REPOSITORY = Symbol('TENANT_MODULE_ACCESS_REPOSITORY');

export interface TenantModuleAccessRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly moduleKey: ModuleKey;
  readonly isEnabled: boolean;
  readonly customLimit?: unknown;
  readonly overriddenByAdminUserId?: string;
  readonly updatedAt: Date;
}

export interface TenantModuleAccessRepository {
  /** Returns null when no explicit record exists — callers must fail open on null. */
  findAccess(tenantId: string, moduleKey: ModuleKey): Promise<TenantModuleAccessRecord | null>;
  listForTenant(tenantId: string): Promise<readonly TenantModuleAccessRecord[]>;
  setAccess(
    tenantId: string,
    moduleKey: ModuleKey,
    input: { isEnabled: boolean; customLimit?: unknown; overriddenByAdminUserId?: string },
  ): Promise<TenantModuleAccessRecord>;
}

/**
 * Minimal shape a host request must expose for ModuleGuard/TenantStatusGuard to
 * operate. These guards are not wired onto any real route in this phase — the
 * exact mechanism by which a future route populates `tenantId` (decoded tenant
 * JWT, upstream middleware, etc.) is a Phase 6 decision. Absence of tenantId is
 * treated as a host-wiring problem, not a tenant billing problem, so it fails open.
 */
export interface TenantScopedRequest {
  readonly method: string;
  readonly tenantId?: string;
  readonly headers?: Readonly<Record<string, string | string[] | undefined>>;
}
