import { createTenantEnforcementGuard } from '@nexoraa/tenant-enforcement-client';

import type { PaymentRequest } from './payment.types';

/**
 * Phase 6 of the Nexoraa Company Admin Panel. Calls platform-admin-service's
 * internal enforcement endpoint (kill-switch: ENFORCE_TENANT_GUARDS, default
 * false — see @nexoraa/tenant-enforcement-client for the full contract).
 * tenantId is read from `paymentScope`, populated directly by
 * PaymentAuthenticationMiddleware (this service has no separate scope guard).
 */
export const PaymentEnforcementGuard = createTenantEnforcementGuard<PaymentRequest>(
  (request) => request.paymentScope?.tenantId,
);
