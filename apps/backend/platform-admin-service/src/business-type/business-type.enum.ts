/**
 * Mirrors tenant-service's TenantBusinessType union
 * (apps/backend/tenant-service/src/tenant/tenant.types.ts). Duplicated here
 * deliberately: no shared-types package in this repo (packages/types,
 * packages/shared) currently defines this enum, and tenant-service itself
 * already duplicates it internally rather than centralizing it. If tenant-service
 * adds a new business type, this list must be updated by hand to match.
 */
export enum TenantBusinessType {
  LAUNDRY = 'laundry',
  DRY_CLEANING = 'dry_cleaning',
  TAILORING = 'tailoring',
  SHOE_CLEANING = 'shoe_cleaning',
  APPLIANCE_REPAIR = 'appliance_repair',
  MOBILE_REPAIR = 'mobile_repair',
  VEHICLE_WASH = 'vehicle_wash',
  SALON = 'salon',
  GENERAL = 'general',
  CUSTOM = 'custom',
}
