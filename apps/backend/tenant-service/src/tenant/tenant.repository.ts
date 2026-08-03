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

  async findByEmail(email: string): Promise<TenantOwnerRecord | null> {
    const normalised = email.trim().toLowerCase();
    const userId = this.emailIndex.get(normalised);
    if (!userId) return null;
    return this.owners.get(userId) ?? null;
  }

  async findBySlug(slug: string): Promise<TenantRecord | null> {
    const tenantId = this.slugIndex.get(slug);
    if (!tenantId) return null;
    return this.tenants.get(tenantId) ?? null;
  }

  async findById(tenantId: string): Promise<TenantRecord | null> {
    return this.tenants.get(tenantId) ?? null;
  }

  async listBranches(tenantId: string): Promise<BranchRecord[]> {
    return [...this.branches.values()].filter((b) => b.tenantId === tenantId);
  }

  async updateStatus(tenantId: string, status: TenantStatus): Promise<void> {
    const existing = this.tenants.get(tenantId);
    if (!existing) return;
    this.tenants.set(tenantId, {
      ...existing,
      status,
      updatedAtUtc: new Date().toISOString(),
    });
  }

  async createTenant(
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

    this.slugIndex.set(tenant.tenantSlug, tenant.tenantId);
    this.emailIndex.set(owner.email, owner.userId);

    return {
      tenantId: tenant.tenantId,
      tenantSlug: tenant.tenantSlug,
      ownerUserId: owner.userId,
      businessName: tenant.businessName,
      message: 'Account created successfully',
    };
  }
}
