import { Inject, Injectable } from '@nestjs/common';

import { generateTenantId, generateUserId, hashPassword, slugify } from './tenant.crypto';
import { TenantError } from './tenant.errors';
import {
  TENANT_REPOSITORY,
  type BranchRecord,
  type CompleteTenantOnboardingInput,
  type CompleteTenantOnboardingOutput,
  type RegisterTenantInput,
  type RegisterTenantOutput,
  type TenantOwnerRecord,
  type TenantRecord,
  type TenantRepository,
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

    const headOfficeBranch: BranchRecord = {
      branchId,
      tenantId,
      branchName: 'Head Office',
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

    return this.tenantRepository.createTenant(tenant, owner, headOfficeBranch, [defaultService]);
  }

  async completeOnboarding(
    tenantId: string,
    input: CompleteTenantOnboardingInput,
  ): Promise<CompleteTenantOnboardingOutput> {
    await this.getTenantById(tenantId);

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

    return this.tenantRepository.completeOnboarding(tenantId, {
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
      services: [...input.services],
      staff: [],
    });
  }

  // ─── Queries ───────────────────────────────────────────────────────────────

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
