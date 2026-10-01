import { Inject, Injectable } from '@nestjs/common';
import { nextAvailableBranchCode } from '@nexoraa/utils';

import { generateTenantId, generateUserId, hashPassword, slugify } from './tenant.crypto';
import { duplicateKeyToTenantError, TenantError } from './tenant.errors';
import {
  TENANT_REPOSITORY,
  TENANT_CATALOG_PROVISIONER,
  type BranchRecord,
  type CompleteTenantOnboardingInput,
  type CompleteTenantOnboardingOutput,
  type RegisterTenantInput,
  type RegisterTenantOutput,
  type TenantCatalogProvisioner,
  type TenantListPage,
  type TenantListQuery,
  type TenantOwnerRecord,
  type TenantRecord,
  type TenantRepository,
  type UpdateTenantProfileInput,
} from './tenant.types';

// Permissions granted to every new tenant owner by default.
const OWNER_DEFAULT_PERMISSIONS: readonly string[] = Object.freeze([
  'orders:read',
  'orders:write',
  'customers:read',
  'customers:write',
  'payments:read',
  'reports:read',
  'audit:read',
]);

function assertTermsAgreed(agreed: boolean): void {
  if (!agreed) {
    throw new TenantError({
      code: 'tenant.terms_not_agreed',
      category: 'validation',
      messageKey: 'errors.tenant.terms_not_agreed',
    });
  }
}

function assertStrongPassword(password: string): void {
  const checks = [
    { field: 'password', code: 'tenant.password_min_length', ok: password.length >= 8 },
    { field: 'password', code: 'tenant.password_uppercase', ok: /[A-Z]/.test(password) },
    { field: 'password', code: 'tenant.password_lowercase', ok: /[a-z]/.test(password) },
    { field: 'password', code: 'tenant.password_number', ok: /\d/.test(password) },
    { field: 'password', code: 'tenant.password_special', ok: /[^A-Za-z0-9]/.test(password) },
  ];

  const failures = checks.filter((c) => !c.ok).map((c) => ({ field: c.field, code: c.code }));

  if (failures.length > 0) {
    throw new TenantError({
      code: 'tenant.password_policy_failed',
      category: 'validation',
      messageKey: 'errors.tenant.password_policy_failed',
      fields: failures,
    });
  }
}

/**
 * Generates a unique slug by appending a numeric suffix if the base slug
 * is already taken. Tries up to 99 variants before giving up.
 */
async function resolveUniqueSlug(base: string, repository: TenantRepository): Promise<string> {
  const existing = await repository.findBySlug(base);
  if (!existing) return base;

  for (let i = 2; i <= 99; i++) {
    const candidate = `${base}-${i}`;
    const taken = await repository.findBySlug(candidate);
    if (!taken) return candidate;
  }

  // Extremely unlikely — fall back to a random suffix.
  return `${base}-${generateTenantId().slice(0, 6)}`;
}

@Injectable()
export class TenantService {
  constructor(
    @Inject(TENANT_REPOSITORY)
    private readonly tenantRepository: TenantRepository,
    @Inject(TENANT_CATALOG_PROVISIONER)
    private readonly catalogProvisioner: TenantCatalogProvisioner,
  ) {}

  // ─── Registration ──────────────────────────────────────────────────────────

  async registerTenant(input: RegisterTenantInput): Promise<RegisterTenantOutput> {
    assertTermsAgreed(input.agreedToTerms);
    assertStrongPassword(input.password);

    const normalisedEmail = input.email.trim().toLowerCase();

    // Guard: email must be unique across all tenant owners.
    const existingOwner = await this.tenantRepository.findByEmail(normalisedEmail);
    if (existingOwner) {
      throw new TenantError({
        code: 'tenant.email_already_registered',
        category: 'conflict',
        messageKey: 'errors.tenant.email_already_registered',
        fields: [{ field: 'email', code: 'tenant.email_already_registered' }],
      });
    }

    const tenantId = generateTenantId();
    const userId = generateUserId();
    const branchId = generateTenantId();
    const tenantServiceId = generateTenantId();

    const baseSlug = slugify(input.businessName);
    const slug = await resolveUniqueSlug(baseSlug, this.tenantRepository);
    const now = new Date().toISOString();

    const tenant: TenantRecord = {
      tenantId,
      slug,
      businessName: input.businessName.trim(),
      businessType: input.businessType,
      ownerName: input.ownerName.trim(),
      ownerEmail: normalisedEmail,
      ownerPhone: input.mobileNumber.trim(),
      ownerUserId: userId,
      taxEnabled: true,
      defaultTaxPct: 0,
      subscriptionPlanId: '60d5ecb8b392d7001f3e3a45', // Placeholder — to be replaced by subscription service
      status: 'Active',
      createdAt: now,
      updatedAt: now,
    };

    const owner: TenantOwnerRecord = {
      userId,
      tenantId,
      slug,
      tenantName: input.businessName.trim(),
      displayName: input.ownerName.trim(),
      email: normalisedEmail,
      mobileNumber: input.mobileNumber.trim(),
      passwordHash: hashPassword(input.password),
      roleCode: 'tenant_owner',
      permissions: OWNER_DEFAULT_PERMISSIONS,
      status: 'active',
      accessVersion: 1,
      createdAt: now,
    };

    // This is always the tenant's first branch (tenantId is brand new), so
    // there are no existing codes to avoid — reuses the same generator
    // branch-service's createBranch uses for every subsequently created
    // branch, just with an empty existing-codes list.
    const headOfficeBranchCode = nextAvailableBranchCode([]);

    const headOfficeBranch: BranchRecord = {
      branchId,
      tenantId,
      branchName: 'Head Office',
      code: headOfficeBranchCode,
      streetAddress: '',
      city: '',
      state: '',
      country: '',
      postalCode: '',
      phone: input.mobileNumber.trim(),
      email: normalisedEmail,
      isHeadOffice: true,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    };

    const defaultService = {
      tenantServiceId,
      tenantId,
      serviceType: input.businessType,
      isEnabled: true,
      createdAt: now,
    };

    try {
      return await this.tenantRepository.createTenant(tenant, owner, headOfficeBranch, [
        defaultService,
      ]);
    } catch (error) {
      // The email is pre-checked above, but the owner's phone is only enforced
      // by the unique ownerPhone / mobileNumber indexes (a re-used phone used to
      // surface as a 500 "could not complete registration").
      throw duplicateKeyToTenantError(error) ?? error;
    }
  }

  async completeOnboarding(
    tenantId: string,
    input: CompleteTenantOnboardingInput,
  ): Promise<CompleteTenantOnboardingOutput> {
    const tenant = await this.getTenantById(tenantId);

    const normalisedEmail = input.email.trim().toLowerCase();
    const existingOwner = await this.tenantRepository.findByEmail(normalisedEmail);
    if (existingOwner && existingOwner.tenantId !== tenantId) {
      throw new TenantError({
        code: 'tenant.email_already_registered',
        category: 'conflict',
        messageKey: 'errors.tenant.email_already_registered',
        fields: [{ field: 'email', code: 'tenant.email_already_registered' }],
      });
    }

    const businessTypes = [...new Set([input.businessType, ...input.services])];
    const result = await this.tenantRepository.completeOnboarding(tenantId, {
      businessName: input.businessName.trim(),
      businessType: input.businessType,
      ownerName: input.ownerName.trim(),
      email: normalisedEmail,
      mobileNumber: input.mobileNumber.trim(),
      branch: {
        branchName: input.branch.branchName.trim(),
        streetAddress: input.branch.streetAddress.trim(),
        city: input.branch.city.trim(),
        postalCode: input.branch.postalCode.trim(),
        phone: input.branch.phone.trim(),
        email: input.branch.email.trim().toLowerCase(),
      },
      services: businessTypes,
      staff: input.staff.map((staff) => ({
        ...(staff.mobileNumber?.trim() ? { mobileNumber: staff.mobileNumber.trim() } : {}),
        ...(staff.email?.trim() ? { email: staff.email.trim().toLowerCase() } : {}),
      })),
    });
    await this.catalogProvisioner.provision({
      tenantId,
      ownerUserId: tenant.ownerUserId,
      businessTypes,
    });
    return result;
  }

  async provisionExistingCatalogs(): Promise<number> {
    const candidates = await this.tenantRepository.listCatalogProvisioningCandidates();
    let provisioned = 0;
    for (const candidate of candidates) {
      if (candidate.businessTypes.length === 0) continue;
      await this.catalogProvisioner.provision(candidate);
      provisioned++;
    }
    return provisioned;
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

  /** Internal/system-level — no ownership check (see PlatformAdminInternalGuard). */
  listAllForAdmin(query: TenantListQuery): Promise<TenantListPage> {
    return this.tenantRepository.listAll(query);
  }

  async getTenantById(tenantId: string): Promise<TenantRecord> {
    const tenant = await this.tenantRepository.findById(tenantId);
    if (!tenant) {
      throw new TenantError({
        code: 'tenant.not_found',
        category: 'not_found',
        messageKey: 'errors.tenant.not_found',
      });
    }
    return tenant;
  }

  async listBranches(tenantId: string): Promise<BranchRecord[]> {
    // Ensure tenant exists before listing branches.
    await this.getTenantById(tenantId);
    return this.tenantRepository.listBranches(tenantId);
  }

  async updateProfile(tenantId: string, input: UpdateTenantProfileInput): Promise<TenantRecord> {
    const current = await this.getTenantById(tenantId);

    // The Edit Profile screen re-sends every field, including ones the user did
    // not touch. Only write values that actually changed: re-writing an
    // unchanged phone number can still collide with the unique ownerPhone /
    // owner mobileNumber indexes (e.g. the same number on another test
    // account) and must never block saving a new name or location.
    const changed = (next: string | undefined, previous: string | undefined) =>
      next !== undefined && next.trim() !== '' && next.trim() !== (previous ?? '').trim()
        ? next.trim()
        : undefined;
    const update: UpdateTenantProfileInput = {
      ownerName: changed(input.ownerName, current.ownerName),
      mobileNumber: changed(input.mobileNumber, current.ownerPhone),
      businessName: changed(input.businessName, current.businessName),
      // Location maps to the head office's city (no uniqueness), so keep it as sent.
      location: input.location?.trim() || undefined,
    };

    if (Object.values(update).some((value) => value !== undefined)) {
      await this.tenantRepository.updateProfile(tenantId, update);
    }
    return this.getTenantById(tenantId);
  }

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  async suspendTenant(tenantId: string): Promise<void> {
    const tenant = await this.tenantRepository.findById(tenantId);
    if (!tenant) {
      throw new TenantError({
        code: 'tenant.not_found',
        category: 'not_found',
        messageKey: 'errors.tenant.not_found',
      });
    }
    if (tenant.status === 'Suspended') {
      throw new TenantError({
        code: 'tenant.already_suspended',
        category: 'conflict',
        messageKey: 'errors.tenant.already_suspended',
      });
    }
    await this.tenantRepository.updateStatus(tenantId, 'Suspended');
  }

  async reactivateTenant(tenantId: string): Promise<void> {
    const tenant = await this.tenantRepository.findById(tenantId);
    if (!tenant) {
      throw new TenantError({
        code: 'tenant.not_found',
        category: 'not_found',
        messageKey: 'errors.tenant.not_found',
      });
    }
    if (tenant.status === 'Active') {
      throw new TenantError({
        code: 'tenant.already_active',
        category: 'conflict',
        messageKey: 'errors.tenant.already_active',
      });
    }
    await this.tenantRepository.updateStatus(tenantId, 'Active');
  }
}
