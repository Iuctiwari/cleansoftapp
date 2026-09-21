import { ModuleKey } from '../src/module-access/module-key.enum';
import type {
  TenantModuleAccessRecord,
  TenantModuleAccessRepository,
} from '../src/module-access/module-access.types';
import { TenantConfigService } from '../src/tenant-config/tenant-config.service';
import { DEFAULT_PRIMARY_COLOR_HEX } from '../src/theme/theme-defaults';
import { ThemeService } from '../src/theme/theme.service';
import type { EffectiveTenantTheme } from '../src/theme/theme.types';

const TENANT_ID = '64f0c18f7c4d2f0012ab3400';

function buildModuleAccessRecord(
  overrides: Partial<TenantModuleAccessRecord> = {},
): TenantModuleAccessRecord {
  return {
    id: 'access-1',
    tenantId: TENANT_ID,
    moduleKey: ModuleKey.PAYMENTS,
    isEnabled: false,
    updatedAt: new Date(),
    ...overrides,
  };
}

describe('TenantConfigService — GET /tenant/config/active', () => {
  function buildService(
    theme: EffectiveTenantTheme,
    moduleRecords: readonly TenantModuleAccessRecord[],
  ): TenantConfigService {
    const themeServiceStub = {
      getEffectiveTheme: jest.fn().mockResolvedValue(theme),
    } as unknown as ThemeService;
    const moduleAccess: TenantModuleAccessRepository = {
      findAccess: jest.fn(),
      listForTenant: jest.fn().mockResolvedValue(moduleRecords),
      setAccess: jest.fn(),
    };
    return new TenantConfigService(themeServiceStub, moduleAccess);
  }

  it('(a)/(f) with no records at all: returns default theme AND every module key enabled', async () => {
    const defaultTheme: EffectiveTenantTheme = {
      tenantId: TENANT_ID,
      isCustomized: false,
      primaryColorHex: DEFAULT_PRIMARY_COLOR_HEX,
      secondaryColorHex: '#7C3AED',
      accentColorHex: '#0EA5E9',
      darkThemeEnabled: false,
      customAppTitle: 'Nexoraa CleanSoft',
      allowShopThemeOverride: false,
    };
    const service = buildService(defaultTheme, []);

    const result = await service.getActiveConfig(TENANT_ID);

    expect(result.theme).toEqual(defaultTheme);
    expect(result.enabledModuleKeys).toEqual(Object.values(ModuleKey));
  });

  it('(c)/(f) with a custom theme and one disabled module: returns custom theme AND excludes that module only', async () => {
    const customTheme: EffectiveTenantTheme = {
      tenantId: TENANT_ID,
      isCustomized: true,
      primaryColorHex: '#ABCDEF',
      secondaryColorHex: '#123456',
      accentColorHex: '#654321',
      darkThemeEnabled: true,
      customAppTitle: 'My Shop',
      allowShopThemeOverride: false,
    };
    const service = buildService(customTheme, [
      buildModuleAccessRecord({ moduleKey: ModuleKey.PAYMENTS, isEnabled: false }),
    ]);

    const result = await service.getActiveConfig(TENANT_ID);

    expect(result.theme).toEqual(customTheme);
    expect(result.theme.isCustomized).toBe(true);
    expect(result.enabledModuleKeys).not.toContain(ModuleKey.PAYMENTS);
    expect(result.enabledModuleKeys).toContain(ModuleKey.ORDER_MANAGEMENT);
    expect(result.enabledModuleKeys.length).toBe(Object.values(ModuleKey).length - 1);
  });
});
