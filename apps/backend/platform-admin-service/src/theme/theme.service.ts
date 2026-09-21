import { Inject, Injectable } from '@nestjs/common';

import { DEFAULT_TENANT_THEME } from './theme-defaults';
import {
  TENANT_THEME_REPOSITORY,
  THEME_HISTORY_REPOSITORY,
  ThemeHistoryAction,
  type EffectiveTenantTheme,
  type SetTenantThemeInput,
  type TenantThemeRecord,
  type TenantThemeRepository,
  type ThemeHistoryRepository,
} from './theme.types';

const THEME_VALUE_KEYS = [
  'primaryColorHex',
  'secondaryColorHex',
  'accentColorHex',
  'darkThemeEnabled',
  'customAppTitle',
  'logoUrl',
  'bannerUrl',
  'allowShopThemeOverride',
] as const;

function toDiffableValue(record: TenantThemeRecord): Record<string, unknown> {
  const value: Record<string, unknown> = {};
  for (const key of THEME_VALUE_KEYS) value[key] = record[key];
  return value;
}

@Injectable()
export class ThemeService {
  constructor(
    @Inject(TENANT_THEME_REPOSITORY) private readonly themes: TenantThemeRepository,
    @Inject(THEME_HISTORY_REPOSITORY) private readonly history: ThemeHistoryRepository,
  ) {}

  /**
   * The single source of truth both GET endpoints (admin and tenant-facing)
   * read from — guarantees a tenant with no record gets IDENTICAL default
   * values regardless of which endpoint asks.
   */
  async getEffectiveTheme(tenantId: string): Promise<EffectiveTenantTheme> {
    const record = await this.themes.findByTenantId(tenantId);
    if (!record) {
      return { tenantId, isCustomized: false, ...DEFAULT_TENANT_THEME };
    }

    return {
      tenantId,
      isCustomized: true,
      primaryColorHex: record.primaryColorHex,
      secondaryColorHex: record.secondaryColorHex,
      accentColorHex: record.accentColorHex,
      darkThemeEnabled: record.darkThemeEnabled,
      customAppTitle: record.customAppTitle,
      logoUrl: record.logoUrl,
      bannerUrl: record.bannerUrl,
      allowShopThemeOverride: record.allowShopThemeOverride,
    };
  }

  async setTheme(
    tenantId: string,
    input: SetTenantThemeInput,
    actorAdminUserId: string,
  ): Promise<TenantThemeRecord> {
    const existing = await this.themes.findByTenantId(tenantId);
    const updated = await this.themes.upsert(tenantId, input, actorAdminUserId);

    await this.history.append({
      tenantId,
      action: ThemeHistoryAction.THEME_UPDATED,
      previousValue: existing ? toDiffableValue(existing) : undefined,
      newValue: toDiffableValue(updated),
      actorAdminUserId,
    });

    return updated;
  }
}
