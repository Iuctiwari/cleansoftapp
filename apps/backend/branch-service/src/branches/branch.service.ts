import { Inject, Injectable } from '@nestjs/common';
import { AUTO_BRANCH_CODE_RETRIES, nextAvailableBranchCode } from '@nexoraa/utils';
import { Permissions, hasPermission, isBranchManagerRole, isOwnerRole } from '@nexoraa/shared';

import { PlatformError } from '../platform/platform.errors';
import type { PaginatedResult, TrustedContext } from '../platform/platform.types';
import { generateBranchId } from './branch.mongo.repository';
import {
  BRANCH_LIMIT_PROVIDER,
  BRANCH_METRICS_GATEWAY,
  BRANCH_REPOSITORY,
  MANAGER_ELIGIBILITY_SERVICE,
  ORDERS_GATEWAY,
  type BranchLimitProvider,
  type BranchMetricsGateway,
  type BranchQueryFilters,
  type BranchRecord,
  type BranchRepository,
  type BranchStatistics,
  type BranchView,
  type BranchUpdatePatch,
  type CreateBranchInput,
  type ManagerEligibilityService,
  type OrdersGateway,
  type UpdateBranchInput,
} from './branch.types';

function assertTenantContext(
  context: TrustedContext,
): asserts context is Extract<TrustedContext, { kind: 'tenant' }> {
  if (context.kind !== 'tenant' || !context.tenantId) {
    throw new PlatformError({
      code: 'branch.tenant_context_required',
      category: 'forbidden',
      messageKey: 'errors.branch.tenant_context_required',
    });
  }
}

function assertOwner(context: Extract<TrustedContext, { kind: 'tenant' }>): void {
  if (!isOwnerRole(context.roleCode)) {
    throw new PlatformError({
      code: 'branch.owner_required',
      category: 'forbidden',
      messageKey: 'errors.branch.owner_required',
    });
  }
}

function isBranchManager(context: Extract<TrustedContext, { kind: 'tenant' }>): boolean {
  return isBranchManagerRole(context.roleCode);
}

function assertRead(context: Extract<TrustedContext, { kind: 'tenant' }>): void {
  if (
    !(isOwnerRole(context.roleCode) || isBranchManagerRole(context.roleCode)) ||
    !hasPermission(context.roleCode, context.permissions, Permissions.branchesRead)
  ) {
    throw new PlatformError({
      code: 'branch.read_forbidden',
      category: 'forbidden',
      messageKey: 'errors.branch.read_forbidden',
    });
  }
}

function throwNotFound(): never {
  // Same message whether the branch doesn't exist or belongs to another
  // tenant — a tenant-safe 404 never confirms foreign-tenant existence.
  throw new PlatformError({
    code: 'branch.not_found',
    category: 'not_found',
    messageKey: 'errors.branch.not_found',
  });
}

function normalizeCode(code?: string): string | undefined {
  const trimmed = code?.trim();
  return trimmed && trimmed.length > 0 ? trimmed.toUpperCase() : undefined;
}

@Injectable()
export class BranchService {
  constructor(
    @Inject(BRANCH_REPOSITORY) private readonly branchRepository: BranchRepository,
    @Inject(MANAGER_ELIGIBILITY_SERVICE)
    private readonly managerEligibilityService: ManagerEligibilityService,
    @Inject(BRANCH_LIMIT_PROVIDER) private readonly branchLimitProvider: BranchLimitProvider,
    @Inject(ORDERS_GATEWAY) private readonly ordersGateway: OrdersGateway,
    @Inject(BRANCH_METRICS_GATEWAY)
    private readonly branchMetricsGateway: BranchMetricsGateway,
  ) {}

  /** No trusted context needed — internal/system-level query (see
   *  PlatformAdminInternalGuard), used by platform-admin-service's Company
   *  Admin panel to show a tenant's branch count. */
  getActiveBranchCount(tenantId: string): Promise<number> {
    return this.branchRepository.countActiveByTenant(tenantId);
  }

  async listBranches(
    context: TrustedContext,
    filters: BranchQueryFilters,
    page: { page: number; pageSize: number },
  ): Promise<PaginatedResult<BranchView>> {
    assertTenantContext(context);
    assertRead(context);

    // A Branch Manager only ever sees branches assigned to them, regardless
    // of what the caller asked for — this is enforced server-side, not just
    // hidden in the UI.
    const effectiveFilters: BranchQueryFilters = isBranchManager(context)
      ? { ...filters, branchId: context.branchId }
      : filters;

    const result = await this.branchRepository.list(context.tenantId, effectiveFilters, page);
    return { ...result, items: await this.enrich(context.tenantId, result.items) };
  }

  async getBranch(context: TrustedContext, branchId: string): Promise<BranchView> {
    assertTenantContext(context);
    assertRead(context);
    const branch = await this.branchRepository.findByBranchIdAndTenant(branchId, context.tenantId);
    if (!branch || (isBranchManager(context) && branch.branchId !== context.branchId)) {
      throwNotFound();
    }
    return (await this.enrich(context.tenantId, [branch]))[0];
  }

  async statistics(
    context: TrustedContext,
    filters: BranchQueryFilters,
  ): Promise<BranchStatistics> {
    assertTenantContext(context);
    assertRead(context);
    const effectiveFilters: BranchQueryFilters = isBranchManager(context)
      ? { ...filters, branchId: context.branchId }
      : filters;
    // Branch subscriptions are intentionally bounded and the existing list
    // query remains the source of truth for access/status filtering.
    const branches = await this.branchRepository.list(context.tenantId, effectiveFilters, {
      page: 1,
      pageSize: 10_000,
    });
    const metrics = await this.branchMetricsGateway.getMetrics(
      context.tenantId,
      branches.items.map((branch) => branch.branchId),
    );
    let totalStaff = 0;
    let totalOrders = 0;
    let ordersToday = 0;
    for (const value of metrics.values()) {
      totalStaff += value.totalStaff;
      totalOrders += value.totalOrders;
      ordersToday += value.ordersToday;
    }
    return { totalBranches: branches.total, totalStaff, totalOrders, ordersToday };
  }

  async createBranch(context: TrustedContext, input: CreateBranchInput): Promise<BranchView> {
    assertTenantContext(context);
    assertOwner(context);

    const tenantId = context.tenantId;
    const requestedCode = normalizeCode(input.code);

    const activeCount = await this.branchRepository.countActiveByTenant(tenantId);
    const branchLimit = await this.branchLimitProvider.getBranchLimit(tenantId);
    if (activeCount >= branchLimit) {
      throw new PlatformError({
        code: 'branch.limit_exceeded',
        category: 'forbidden',
        messageKey: 'errors.branch.limit_exceeded',
        statusCode: 402,
      });
    }

    if (requestedCode) {
      const existing = await this.branchRepository.findByCodeAndTenant(requestedCode, tenantId);
      if (existing) {
        throw new PlatformError({
          code: 'branch.code_already_exists',
          category: 'conflict',
          messageKey: 'errors.branch.code_already_exists',
          fields: [{ field: 'code', code: 'branch.code_already_exists' }],
        });
      }
    }

    if (input.managerId) {
      await this.managerEligibilityService.assertEligible(input.managerId, tenantId);
    }

    for (let attempt = 0; attempt < AUTO_BRANCH_CODE_RETRIES; attempt += 1) {
      const code =
        requestedCode ??
        nextAvailableBranchCode(await this.branchRepository.listCodesByTenant(tenantId));
      const now = new Date().toISOString();
      const record: BranchRecord = {
        branchId: generateBranchId(),
        tenantId,
        branchName: input.branchName.trim(),
        code,
        streetAddress: input.streetAddress?.trim() ?? '',
        city: input.city?.trim() ?? '',
        state: input.state?.trim() ?? '',
        country: input.country?.trim() ?? '',
        postalCode: input.postalCode?.trim() ?? '',
        phone: input.phone.trim(),
        email: input.email.trim().toLowerCase(),
        openingTime: input.openingTime,
        closingTime: input.closingTime,
        managerId: input.managerId,
        isHeadOffice: false,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      };

      try {
        const created = await this.branchRepository.create(record);
        return (await this.enrich(context.tenantId, [created]))[0];
      } catch (error) {
        if (requestedCode || !this.isDuplicateKeyError(error)) {
          throw this.mapDuplicateKeyError(error);
        }
      }
    }

    throw new PlatformError({
      code: 'branch.code_already_exists',
      category: 'conflict',
      messageKey: 'errors.branch.code_already_exists',
      fields: [{ field: 'code', code: 'branch.code_already_exists' }],
    });
  }

  async updateBranch(
    context: TrustedContext,
    branchId: string,
    input: UpdateBranchInput,
  ): Promise<BranchView> {
    assertTenantContext(context);
    if (!isOwnerRole(context.roleCode) && !isBranchManager(context)) assertOwner(context);

    const existing = await this.branchRepository.findByBranchIdAndTenant(
      branchId,
      context.tenantId,
    );
    if (!existing || (isBranchManager(context) && existing.branchId !== context.branchId)) {
      throwNotFound();
    }
    if (
      isBranchManager(context) &&
      !hasPermission(context.roleCode, context.permissions, Permissions.branchesWrite)
    ) {
      assertOwner(context);
    }

    const patch: BranchUpdatePatch = { updatedAt: new Date().toISOString() };

    if (input.branchName !== undefined) patch.branchName = input.branchName.trim();
    if (input.streetAddress !== undefined) patch.streetAddress = input.streetAddress.trim();
    if (input.city !== undefined) patch.city = input.city.trim();
    if (input.state !== undefined) patch.state = input.state.trim();
    if (input.country !== undefined) patch.country = input.country.trim();
    if (input.postalCode !== undefined) patch.postalCode = input.postalCode.trim();
    if (input.phone !== undefined) patch.phone = input.phone.trim();
    if (input.email !== undefined) patch.email = input.email.trim().toLowerCase();
    if (input.openingTime !== undefined) patch.openingTime = input.openingTime;
    if (input.closingTime !== undefined) patch.closingTime = input.closingTime;
    if (input.status !== undefined && !isBranchManager(context)) patch.status = input.status;

    if (input.status === 'inactive' && existing.status === 'active') {
      const [openOrders, activeCount] = await Promise.all([
        this.ordersGateway.countNonTerminalByBranch(context.tenantId, branchId),
        this.branchRepository.countActiveByTenant(context.tenantId),
      ]);
      if (openOrders > 0) {
        throw new PlatformError({
          code: 'branch.has_unresolved_orders',
          category: 'conflict',
          messageKey: 'errors.branch.has_unresolved_orders',
        });
      }
      if (activeCount <= 1) {
        throw new PlatformError({
          code: 'branch.last_active_branch',
          category: 'conflict',
          messageKey: 'errors.branch.last_active_branch',
        });
      }
    }

    if (input.code !== undefined && !isBranchManager(context)) {
      const code = normalizeCode(input.code);
      if (code && code !== existing.code) {
        const codeOwner = await this.branchRepository.findByCodeAndTenant(code, context.tenantId);
        if (codeOwner && codeOwner.branchId !== branchId) {
          throw new PlatformError({
            code: 'branch.code_already_exists',
            category: 'conflict',
            messageKey: 'errors.branch.code_already_exists',
            fields: [{ field: 'code', code: 'branch.code_already_exists' }],
          });
        }
      }
      patch.code = code;
    }

    if (
      !isBranchManager(context) &&
      input.managerId !== undefined &&
      input.managerId !== existing.managerId
    ) {
      if (input.managerId === null) {
        patch.managerId = null;
      } else {
        await this.managerEligibilityService.assertEligible(input.managerId, context.tenantId);
        patch.managerId = input.managerId;
      }
    }

    try {
      const updated = await this.branchRepository.update(branchId, context.tenantId, patch);
      return (await this.enrich(context.tenantId, [updated]))[0];
    } catch (error) {
      throw this.mapDuplicateKeyError(error);
    }
  }

  async deactivateBranch(context: TrustedContext, branchId: string): Promise<BranchView> {
    assertTenantContext(context);
    assertOwner(context);

    const existing = await this.branchRepository.findByBranchIdAndTenant(
      branchId,
      context.tenantId,
    );
    if (!existing) {
      throwNotFound();
    }

    if (existing.status === 'inactive') {
      throw new PlatformError({
        code: 'branch.already_inactive',
        category: 'conflict',
        messageKey: 'errors.branch.already_inactive',
      });
    }

    const openOrders = await this.ordersGateway.countNonTerminalByBranch(
      context.tenantId,
      branchId,
    );
    if (openOrders > 0) {
      throw new PlatformError({
        code: 'branch.has_unresolved_orders',
        category: 'conflict',
        messageKey: 'errors.branch.has_unresolved_orders',
      });
    }

    const activeCount = await this.branchRepository.countActiveByTenant(context.tenantId);
    if (activeCount <= 1) {
      throw new PlatformError({
        code: 'branch.last_active_branch',
        category: 'conflict',
        messageKey: 'errors.branch.last_active_branch',
      });
    }

    const updated = await this.branchRepository.update(branchId, context.tenantId, {
      status: 'inactive',
      updatedAt: new Date().toISOString(),
    });
    return (await this.enrich(context.tenantId, [updated]))[0];
  }

  private async enrich(
    tenantId: string,
    branches: readonly BranchRecord[],
  ): Promise<readonly BranchView[]> {
    const [metrics, managerNames] = await Promise.all([
      this.branchMetricsGateway.getMetrics(
        tenantId,
        branches.map((branch) => branch.branchId),
      ),
      this.branchMetricsGateway.getManagerNames(
        tenantId,
        branches.flatMap((branch) => (branch.managerId ? [branch.managerId] : [])),
      ),
    ]);
    return branches.map((branch) => ({
      ...branch,
      ...(branch.managerId && managerNames.has(branch.managerId)
        ? { managerName: managerNames.get(branch.managerId) }
        : {}),
      ...(metrics.get(branch.branchId) ?? {
        ordersToday: 0,
        totalOrders: 0,
        totalStaff: 0,
      }),
    }));
  }

  private mapDuplicateKeyError(error: unknown): PlatformError {
    if (error instanceof PlatformError) {
      return error;
    }

    if (this.isDuplicateKeyError(error)) {
      return new PlatformError({
        code: 'branch.code_already_exists',
        category: 'conflict',
        messageKey: 'errors.branch.code_already_exists',
        fields: [{ field: 'code', code: 'branch.code_already_exists' }],
      });
    }

    return new PlatformError({
      code: 'branch.internal',
      category: 'internal',
      messageKey: 'errors.internal',
      cause: error instanceof Error ? error : undefined,
    });
  }

  private isDuplicateKeyError(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      (error as { code?: unknown }).code === 11000
    );
  }
}
