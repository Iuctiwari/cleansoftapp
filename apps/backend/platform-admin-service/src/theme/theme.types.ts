import type { EffectiveTenantThemeValues } from './theme-defaults';

export interface TenantThemeRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly primaryColorHex: string;
  readonly secondaryColorHex: string;
  readonly accentColorHex: string;
  readonly darkThemeEnabled: boolean;
  readonly customAppTitle: string;
  readonly logoUrl?: string;
  readonly bannerUrl?: string;
  readonly allowShopThemeOverride: boolean;
  readonly updatedByAdminUserId: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export type SetTenantThemeInput = Partial<
  Omit<TenantThemeRecord, 'id' | 'tenantId' | 'updatedByAdminUserId' | 'createdAt' | 'updatedAt'>
>;

export const TENANT_THEME_REPOSITORY = Symbol('TENANT_THEME_REPOSITORY');

export interface TenantThemeRepository {
  /** Returns null when the tenant has no explicit theme set yet. */
  findByTenantId(tenantId: string): Promise<TenantThemeRecord | null>;
  upsert(
    tenantId: string,
    input: SetTenantThemeInput,
    updatedByAdminUserId: string,
  ): Promise<TenantThemeRecord>;
}

/** What GET (admin or tenant-facing) actually returns: real values merged
 *  over the app's current defaults, plus whether a record exists at all. */
export interface EffectiveTenantTheme extends EffectiveTenantThemeValues {
  readonly tenantId: string;
  readonly isCustomized: boolean;
}

export enum ThemeHistoryAction {
  THEME_UPDATED = 'THEME_UPDATED',
}

export interface ThemeHistoryRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly action: ThemeHistoryAction;
  readonly previousValue?: Record<string, unknown>;
  readonly newValue: Record<string, unknown>;
  readonly actorAdminUserId: string;
  readonly timestamp: Date;
}

export const THEME_HISTORY_REPOSITORY = Symbol('THEME_HISTORY_REPOSITORY');

export interface ThemeHistoryRepository {
  append(entry: Omit<ThemeHistoryRecord, 'id' | 'timestamp'>): Promise<ThemeHistoryRecord>;
  listByTenantId(tenantId: string): Promise<readonly ThemeHistoryRecord[]>;
}
