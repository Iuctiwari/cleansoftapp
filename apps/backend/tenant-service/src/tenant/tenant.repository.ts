import { Injectable } from '@nestjs/common';

import type {
  BranchRecord,
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
}
