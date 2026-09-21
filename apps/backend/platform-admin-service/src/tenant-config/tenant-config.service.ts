import { Inject, Injectable } from '@nestjs/common';

import { ModuleKey } from '../module-access/module-key.enum';
import {
  TENANT_MODULE_ACCESS_REPOSITORY,
  type TenantModuleAccessRepository,
} from '../module-access/module-access.types';
import { ThemeService } from '../theme/theme.service';
import type { EffectiveTenantTheme } from '../theme/theme.types';

export interface ActiveTenantConfig {
  readonly theme: EffectiveTenantTheme;
  readonly enabledModuleKeys: readonly ModuleKey[];
}

@Injectable()
export class TenantConfigService {
  constructor(
    private readonly themeService: ThemeService,
    @Inject(TENANT_MODULE_ACCESS_REPOSITORY)
    private readonly moduleAccess: TenantModuleAccessRepository,
  ) {}

  /**
   * The single boot-time call the Flutter app will use for both theme and
   * module gating. Module-key resolution mirrors ModuleGuard's own fail-open
   * rule exactly (Phase 2): every module is enabled unless an explicit
   * TenantModuleAccess record says otherwise — same source of truth, so this
   * list can never disagree with what ModuleGuard would actually allow.
   */
  async getActiveConfig(tenantId: string): Promise<ActiveTenantConfig> {
    const [theme, records] = await Promise.all([
      this.themeService.getEffectiveTheme(tenantId),
      this.moduleAccess.listForTenant(tenantId),
    ]);

    const disabledKeys = new Set(
      records.filter((record) => !record.isEnabled).map((record) => record.moduleKey),
    );
    const enabledModuleKeys = Object.values(ModuleKey).filter((key) => !disabledKeys.has(key));

    return { theme, enabledModuleKeys };
  }
}
