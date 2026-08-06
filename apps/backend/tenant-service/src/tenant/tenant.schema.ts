/**
 * Schema definitions for the tenant domain.
 * These describe the future MongoDB collection structure.
 * The current implementation uses in-memory storage (InMemoryTenantRepository).
 */

export const TenantSchema = {
  collection: 'tenants',
  fields: {
    tenantId: 'string',
    tenantSlug: 'string',
    businessName: 'string',
    businessType: [
      'laundry',
      'dry_cleaning',
      'tailoring',
      'shoe_cleaning',
      'appliance_repair',
      'mobile_repair',
      'vehicle_wash',
      'salon',
      'general',
      'custom',
    ],
    ownerName: 'string',
    ownerEmail: 'string',
    ownerPhone: 'string',
    ownerUserId: 'string',
    taxEnabled: 'boolean',
    defaultTaxPct: 'number',
    subscriptionPlanId: 'string',
    status: ['active', 'pending', 'disabled'],
    createdAtUtc: 'utc-iso',
    updatedAtUtc: 'utc-iso',
  },
  indexes: [
    { tenantId: 1, unique: true },
    { tenantSlug: 1, unique: true },
    { ownerEmail: 1, unique: true },
    { ownerPhone: 1, unique: true },
    { status: 1 },
  ],
} as const;

export const BranchSchema = {
  collection: 'branches',
  fields: {
    branchId: 'string',
    tenantId: 'string',
    branchName: 'string',
    streetAddress: 'string',
    city: 'string',
    state: 'string',
    country: 'string',
    postalCode: 'string',
    phone: 'string',
    email: 'string',
    isHeadOffice: 'boolean',
    status: ['active', 'inactive', 'closed'],
    createdAtUtc: 'utc-iso',
    updatedAtUtc: 'utc-iso',
  },
  indexes: [{ branchId: 1, unique: true }, { tenantId: 1 }],
} as const;

export const TenantServiceSchema = {
  collection: 'tenantServices',
  fields: {
    tenantServiceId: 'string',
    tenantId: 'string',
    serviceType: [
      'laundry',
      'dry_cleaning',
      'tailoring',
      'shoe_cleaning',
      'appliance_repair',
      'mobile_repair',
      'vehicle_wash',
      'salon',
      'general',
      'custom',
    ],
    isEnabled: 'boolean',
    createdAtUtc: 'utc-iso',
  },
  indexes: [{ tenantServiceId: 1, unique: true }, { tenantId: 1 }],
} as const;

export const TenantOwnerSchema = {
  collection: 'tenantOwners',
  fields: {
    userId: 'string',
    tenantId: 'string',
    tenantSlug: 'string',
    tenantName: 'string',
    displayName: 'string',
    email: 'string',
    mobileNumber: 'string',
    passwordHash: 'string',
    roleCode: 'string',
    permissions: 'string[]',
    status: ['active', 'disabled'],
    accessVersion: 'number',
    createdAtUtc: 'utc-iso',
  },
  indexes: [{ userId: 1, unique: true }, { email: 1, unique: true }, { tenantId: 1 }],
} as const;
