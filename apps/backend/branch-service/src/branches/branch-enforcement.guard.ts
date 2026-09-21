import { createTenantEnforcementGuard } from '@nexoraa/tenant-enforcement-client';

import type { RequestWithPlatformContext } from '../platform/platform.request';

/**
 * Phase 6 of the Nexoraa Company Admin Panel. Calls platform-admin-service's
 * internal enforcement endpoint (kill-switch: ENFORCE_TENANT_GUARDS, default
 * false — see @nexoraa/tenant-enforcement-client for the full contract).
 * tenantId is read from `trustedContext`, populated by TrustedContextMiddleware.
 * Only the tenant-kind context carries a tenantId; the platform-kind variant
 * does not, so this optional-chains through safely (platform callers never
 * hit these tenant-scoped write routes in practice, but the guard must not
 * throw if they did).
 */
export const BranchEnforcementGuard = createTenantEnforcementGuard<RequestWithPlatformContext>(
  (request) =>
    request.trustedContext && 'tenantId' in request.trustedContext
      ? request.trustedContext.tenantId
      : undefined,
);
