import { createTenantEnforcementGuard } from '@nexoraa/tenant-enforcement-client';

import type { ExpenseRequest } from './expense.guard';

/**
 * Phase 6 of the Nexoraa Company Admin Panel. Calls platform-admin-service's
 * internal enforcement endpoint (kill-switch: ENFORCE_TENANT_GUARDS, default
 * false — see @nexoraa/tenant-enforcement-client for the full contract).
 * tenantId is read from `expenseScope`, populated by ExpenseScopeGuard, which
 * runs first (controller-scoped guards execute before route-scoped ones).
 */
export const ExpenseEnforcementGuard = createTenantEnforcementGuard<ExpenseRequest>(
  (request) => request.expenseScope?.tenantId,
);
