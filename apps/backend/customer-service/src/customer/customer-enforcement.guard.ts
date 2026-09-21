import { createTenantEnforcementGuard } from '@nexoraa/tenant-enforcement-client';

import type { CustomerRequest } from './customer.guard';

/**
 * Phase 6 of the Nexoraa Company Admin Panel. Calls platform-admin-service's
 * internal enforcement endpoint (kill-switch: ENFORCE_TENANT_GUARDS, default
 * false — see @nexoraa/tenant-enforcement-client for the full contract).
 * tenantId is read from `customerScope`, populated by CustomerScopeGuard,
 * which runs first (controller-scoped guards execute before route-scoped ones).
 */
export const CustomerEnforcementGuard = createTenantEnforcementGuard<CustomerRequest>(
  (request) => request.customerScope?.tenantId,
);
