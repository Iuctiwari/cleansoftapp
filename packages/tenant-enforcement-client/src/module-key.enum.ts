/**
 * Mirrors platform-admin-service's own ModuleKey enum
 * (apps/backend/platform-admin-service/src/module-access/module-key.enum.ts).
 * Duplicated here deliberately — same rationale as Phase 1's TenantBusinessType
 * duplication: no other mechanism exists in this repo for a service to import
 * types from another service's source tree, and this list is small and stable.
 * If platform-admin-service adds a new ModuleKey, update this file to match.
 */
export enum ModuleKey {
  ORDER_MANAGEMENT = 'ORDER_MANAGEMENT',
  PAYMENTS = 'PAYMENTS',
  EXPENSES = 'EXPENSES',
  CASH_REGISTER = 'CASH_REGISTER',
  MULTI_BRANCH = 'MULTI_BRANCH',
  CUSTOMER_CRM = 'CUSTOMER_CRM',
  WHATSAPP_NOTIFICATIONS = 'WHATSAPP_NOTIFICATIONS',
  ADVANCED_REPORTS = 'ADVANCED_REPORTS',
  CUSTOM_THEME_BRANDING = 'CUSTOM_THEME_BRANDING',
}
