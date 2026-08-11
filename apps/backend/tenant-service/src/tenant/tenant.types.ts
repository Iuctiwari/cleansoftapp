export type TenantBusinessType =
  | 'laundry'
  | 'dry_cleaning'
  | 'tailoring'
  | 'shoe_cleaning'
  | 'appliance_repair'
  | 'mobile_repair'
  | 'vehicle_wash'
  | 'salon'
  | 'general'
  | 'custom';

export type TenantStatus = 'PendingVerification' | 'Active' | 'Suspended' | 'Cancelled';
export type BranchStatus = 'active' | 'inactive' | 'closed';

export interface TenantRecord {
  readonly tenantId: string;
  readonly slug: string;
  readonly businessName: string;
  readonly businessType: TenantBusinessType;
  readonly ownerName: string;
  readonly ownerEmail: string;
  readonly ownerPhone: string;
  readonly ownerUserId: string;
  readonly taxEnabled: boolean;
  readonly defaultTaxPct: number;
  readonly subscriptionPlanId: string;
  readonly status: TenantStatus;
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface BranchRecord {
  readonly branchId: string;
  readonly tenantId: string;
  readonly branchName: string;
  readonly streetAddress: string;
  readonly city: string;
  readonly state: string;
  readonly country: string;
  readonly postalCode: string;
  readonly phone: string;
  readonly email: string;
  readonly isHeadOffice: boolean;
  readonly status: BranchStatus;
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface TenantServiceRecord {
  readonly tenantServiceId: string;
  readonly tenantId: string;
  readonly serviceType: TenantBusinessType;
  readonly isEnabled: boolean;
  readonly createdAt: string;
}

export interface TenantOwnerRecord {
  readonly userId: string;
  readonly tenantId: string;
  readonly slug: string;
  readonly tenantName: string;
  readonly displayName: string;
  readonly email: string;
  readonly mobileNumber: string;
  readonly passwordHash: string;
  readonly roleCode: string;
  readonly permissions: readonly string[];
  readonly status: 'active' | 'disabled';
  readonly accessVersion: number;
  readonly createdAt: string;
}

export interface RegisterTenantInput {
  readonly businessName: string;
  readonly businessType: TenantBusinessType;
  readonly ownerName: string;
  readonly email: string;
  readonly mobileNumber: string;
  readonly password: string;
  readonly agreedToTerms: boolean;
}

export interface RegisterTenantOutput {
  readonly tenantId: string;
  readonly slug: string;
  readonly ownerUserId: string;
  readonly businessName: string;
  readonly message: string;
}

export interface CompleteTenantOnboardingInput {
  readonly businessName: string;
  readonly businessType: TenantBusinessType;
  readonly ownerName: string;
  readonly email: string;
  readonly mobileNumber: string;
  readonly branch: {
    readonly branchName: string;
    readonly streetAddress: string;
    readonly city: string;
    readonly postalCode: string;
    readonly phone: string;
    readonly email: string;
  };
  readonly services: readonly TenantBusinessType[];
  readonly staff: readonly string[];
}

export interface CompleteTenantOnboardingOutput {
  readonly tenantId: string;
  readonly message: string;
}

export interface TenantRepository {
  /** Find a tenant owner by normalised email (for uniqueness checks and login). */
  findByEmail(email: string): Promise<TenantOwnerRecord | null>;

  /** Find a tenant record by slug (for uniqueness checks). */
  findBySlug(slug: string): Promise<TenantRecord | null>;

  /** Find a tenant record by its unique tenantId. */
  findById(tenantId: string): Promise<TenantRecord | null>;

  /** List all branches for a given tenant. */
  listBranches(tenantId: string): Promise<BranchRecord[]>;

  /** Update the tenant lifecycle status. */
  updateStatus(tenantId: string, status: TenantStatus): Promise<void>;

  /** Atomically create tenant, owner, head-office branch, and initial services. */
  createTenant(
    tenant: TenantRecord,
    owner: TenantOwnerRecord,
    branch: BranchRecord,
    services: TenantServiceRecord[],
  ): Promise<RegisterTenantOutput>;

  /** Atomically update all records created during tenant onboarding. */
  completeOnboarding(
    tenantId: string,
    input: CompleteTenantOnboardingInput,
  ): Promise<CompleteTenantOnboardingOutput>;
}

export const TENANT_REPOSITORY = Symbol('TENANT_REPOSITORY');
