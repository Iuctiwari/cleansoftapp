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
  readonly code?: string;
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
  readonly staff: readonly {
    readonly mobileNumber?: string;
    readonly email?: string;
  }[];
}

export interface CompleteTenantOnboardingOutput {
  readonly tenantId: string;
  readonly message: string;
}

export interface CatalogProvisioningCandidate {
  readonly tenantId: string;
  readonly ownerUserId: string;
  readonly businessTypes: readonly TenantBusinessType[];
}

export interface TenantCatalogProvisioner {
  provision(candidate: CatalogProvisioningCandidate): Promise<void>;
}

export const TENANT_CATALOG_PROVISIONER = Symbol('TENANT_CATALOG_PROVISIONER');

export interface UpdateTenantProfileInput {
  readonly ownerName?: string;
  readonly mobileNumber?: string;
  readonly businessName?: string;
  readonly location?: string;
}

export interface TenantListQuery {
  /** Case-insensitive partial match on businessName, ownerName, ownerEmail, or slug. */
  readonly search?: string;
  readonly status?: TenantStatus;
  /** Exact-match bulk lookup (e.g. "everyone on this subscription plan"); when set, ignores paging. */
  readonly tenantIds?: readonly string[];
  readonly page?: number;
  readonly limit?: number;
}

export interface TenantListPage {
  readonly items: readonly TenantRecord[];
  readonly page: number;
  readonly limit: number;
  readonly total: number;
}

/**
 * What marketplace-service needs to list a shop to customers: the trusted
 * business identity, enabled services and branches. Internal API only.
 */
export interface TenantMarketplaceProfile {
  readonly tenantId: string;
  readonly businessName: string;
  readonly businessType: TenantBusinessType;
  readonly ownerName: string;
  readonly ownerPhone: string;
  readonly status: TenantStatus;
  readonly services: readonly TenantBusinessType[];
  readonly branches: readonly BranchRecord[];
}

export interface TenantRepository {
  /** Find a tenant owner by normalised email (for uniqueness checks and login). */
  findByEmail(email: string): Promise<TenantOwnerRecord | null>;

  /** Find a tenant record by slug (for uniqueness checks). */
  findBySlug(slug: string): Promise<TenantRecord | null>;

  /** Find a tenant record by its unique tenantId. */
  findById(tenantId: string): Promise<TenantRecord | null>;

  /** Paginated/searchable tenant list — backs the internal endpoint platform-admin-service calls. */
  listAll(query: TenantListQuery): Promise<TenantListPage>;

  /** List all branches for a given tenant. */
  listBranches(tenantId: string): Promise<BranchRecord[]>;

  /** The tenant's enabled service types (laundry, salon, …). */
  listEnabledServiceTypes(tenantId: string): Promise<TenantBusinessType[]>;

  /** List existing tenants and only their enabled business capabilities for catalog backfill. */
  listCatalogProvisioningCandidates(): Promise<CatalogProvisioningCandidate[]>;

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

  /** Update tenant owner profile information. */
  updateProfile(tenantId: string, input: UpdateTenantProfileInput): Promise<void>;
}

export const TENANT_REPOSITORY = Symbol('TENANT_REPOSITORY');
