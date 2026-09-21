import { Inject, Injectable } from '@nestjs/common';

import { ModuleKey } from './module-key.enum';
import {
  TENANT_MODULE_ACCESS_REPOSITORY,
  type TenantModuleAccessRepository,
} from './module-access.types';

export interface ModuleMatrixEntry {
  readonly moduleKey: ModuleKey;
  readonly isEnabled: boolean;
  readonly customLimit?: unknown;
  readonly overriddenByAdminUserId?: string;
  readonly updatedAt?: Date;
}

@Injectable()
export class TenantModuleAccessService {
  constructor(
    @Inject(TENANT_MODULE_ACCESS_REPOSITORY)
    private readonly repository: TenantModuleAccessRepository,
  ) {}

  /**
   * Returns EVERY ModuleKey, not just the ones with explicit records — a
   * module with no record is enabled by default (the same fail-open rule
   * ModuleGuard itself enforces, Phase 2), so the matrix UI must show it as
   * enabled too, not omit it.
   */
  async getMatrix(tenantId: string): Promise<readonly ModuleMatrixEntry[]> {
    const records = await this.repository.listForTenant(tenantId);
    const byKey = new Map(records.map((record) => [record.moduleKey, record]));

    return Object.values(ModuleKey).map((moduleKey) => {
      const record = byKey.get(moduleKey);
      if (!record) return { moduleKey, isEnabled: true };
      return {
        moduleKey,
        isEnabled: record.isEnabled,
        customLimit: record.customLimit,
        overriddenByAdminUserId: record.overriddenByAdminUserId,
        updatedAt: record.updatedAt,
      };
    });
  }

  async setModule(
    tenantId: string,
    moduleKey: ModuleKey,
    input: { isEnabled: boolean; customLimit?: unknown },
    actorAdminUserId: string,
  ): Promise<ModuleMatrixEntry> {
    const record = await this.repository.setAccess(tenantId, moduleKey, {
      ...input,
      overriddenByAdminUserId: actorAdminUserId,
    });
    return {
      moduleKey: record.moduleKey,
      isEnabled: record.isEnabled,
      customLimit: record.customLimit,
      overriddenByAdminUserId: record.overriddenByAdminUserId,
      updatedAt: record.updatedAt,
    };
  }
}
