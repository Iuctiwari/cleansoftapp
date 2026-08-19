import { Injectable } from '@nestjs/common';

import { generateTenantId } from './tenant.crypto';
import type {
  BranchRecord,
  CatalogProvisioningCandidate,
  CompleteTenantOnboardingInput,
  CompleteTenantOnboardingOutput,
  RegisterTenantOutput,
  TenantOwnerRecord,
  TenantRecord,
  TenantRepository,
  TenantServiceRecord,
  TenantStatus,
} from './tenant.types';

/**
 * In-memory implementation of TenantRepository.
 * Used as a lightweight substitute in unit tests and local runs without MongoDB.
 * Data is lost on process restart.
 */
@Injectable()
export class InMemoryTenantRepository implements TenantRepository {
  // tenantId -> TenantRecord
  private readonly tenants = new Map<string, TenantRecord>();

  // userId -> TenantOwnerRecord
  private readonly owners = new Map<string, TenantOwnerRecord>();

  // branchId -> BranchRecord
  private readonly branches = new Map<string, BranchRecord>();

  // tenantServiceId -> TenantServiceRecord
  private readonly services = new Map<string, TenantServiceRecord>();

  // slug -> tenantId (for uniqueness checks)
  private readonly slugIndex = new Map<string, string>();

  // normalised email -> userId (for uniqueness checks)
  private readonly emailIndex = new Map<string, string>();

  findByEmail(email: string): Promise<TenantOwnerRecord | null> {
    const normalised = email.trim().toLowerCase();
    const userId = this.emailIndex.get(normalised);
    if (!userId) return Promise.resolve(null);
    return Promise.resolve(this.owners.get(userId) ?? null);
  }

  findBySlug(slug: string): Promise<TenantRecord | null> {
    const tenantId = this.slugIndex.get(slug);
    if (!tenantId) return Promise.resolve(null);
    return Promise.resolve(this.tenants.get(tenantId) ?? null);
  }

  findById(tenantId: string): Promise<TenantRecord | null> {
    return Promise.resolve(this.tenants.get(tenantId) ?? null);
  }

  listBranches(tenantId: string): Promise<BranchRecord[]> {
    return Promise.resolve([...this.branches.values()].filter((b) => b.tenantId === tenantId));
  }

  listCatalogProvisioningCandidates(): Promise<CatalogProvisioningCandidate[]> {
    return Promise.resolve(
      [...this.tenants.values()].map((tenant) => ({
        tenantId: tenant.tenantId,
        ownerUserId: tenant.ownerUserId,
        businessTypes: [
          ...new Set(
            [...this.services.values()]
              .filter((service) => service.tenantId === tenant.tenantId && service.isEnabled)
              .map((service) => service.serviceType),
          ),
        ],
      })),
    );
  }

  updateStatus(tenantId: string, status: TenantStatus): Promise<void> {
    const existing = this.tenants.get(tenantId);
    if (!existing) return Promise.resolve();
    this.tenants.set(tenantId, {
      ...existing,
      status,
      updatedAt: new Date().toISOString(),
    });
    return Promise.resolve();
  }

  createTenant(
    tenant: TenantRecord,
    owner: TenantOwnerRecord,
    branch: BranchRecord,
    services: TenantServiceRecord[],
  ): Promise<RegisterTenantOutput> {
    this.tenants.set(tenant.tenantId, tenant);
    this.owners.set(owner.userId, owner);
    this.branches.set(branch.branchId, branch);

    for (const service of services) {
      this.services.set(service.tenantServiceId, service);
    }

    this.slugIndex.set(tenant.slug, tenant.tenantId);
    this.emailIndex.set(owner.email, owner.userId);

    return Promise.resolve({
      tenantId: tenant.tenantId,
      slug: tenant.slug,
      ownerUserId: owner.userId,
      businessName: tenant.businessName,
      message: 'Account created successfully',
    });
  }

  completeOnboarding(
    tenantId: string,
    input: CompleteTenantOnboardingInput,
  ): Promise<CompleteTenantOnboardingOutput> {
    const tenant = this.tenants.get(tenantId);
    const owner = [...this.owners.values()].find((item) => item.tenantId === tenantId);
    const branch = [...this.branches.values()].find(
      (item) => item.tenantId === tenantId && item.isHeadOffice,
    );
    if (!tenant || !owner || !branch) {
      return Promise.reject(new Error('Required onboarding record is missing'));
    }

    const now = new Date().toISOString();
    this.tenants.set(tenantId, {
      ...tenant,
      businessName: input.businessName,
      businessType: input.businessType,
      ownerName: input.ownerName,
      ownerEmail: input.email,
      ownerPhone: input.mobileNumber,
      updatedAt: now,
    });
    this.owners.set(owner.userId, {
      ...owner,
      tenantName: input.businessName,
      displayName: input.ownerName,
      email: input.email,
      mobileNumber: input.mobileNumber,
    });
    this.branches.set(branch.branchId, {
      ...branch,
      branchName: input.branch.branchName,
      streetAddress: input.branch.streetAddress,
      city: input.branch.city,
      state: '',
      country: '',
      postalCode: input.branch.postalCode,
      phone: input.branch.phone,
      email: input.branch.email,
      updatedAt: now,
    });

    for (const serviceType of input.services) {
      const existing = [...this.services.values()].find(
        (service) => service.tenantId === tenantId && service.serviceType === serviceType,
      );
      if (!existing) {
        const tenantServiceId = generateTenantId();
        this.services.set(tenantServiceId, {
          tenantServiceId,
          tenantId,
          serviceType,
          isEnabled: true,
          createdAt: now,
        });
      }
    }

    return Promise.resolve({
      tenantId,
      message: 'Onboarding completed successfully',
    });
  }
}
