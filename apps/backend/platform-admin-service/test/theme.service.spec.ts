/* eslint-disable @typescript-eslint/unbound-method, @typescript-eslint/no-unsafe-assignment */
import { ThemeService } from '../src/theme/theme.service';
import {
  DEFAULT_ACCENT_COLOR_HEX,
  DEFAULT_APP_TITLE,
  DEFAULT_DARK_THEME_ENABLED,
  DEFAULT_PRIMARY_COLOR_HEX,
  DEFAULT_SECONDARY_COLOR_HEX,
} from '../src/theme/theme-defaults';
import {
  ThemeHistoryAction,
  type TenantThemeRecord,
  type TenantThemeRepository,
  type ThemeHistoryRepository,
} from '../src/theme/theme.types';

const TENANT_ID = '64f0c18f7c4d2f0012ab3400';
const ADMIN_ID = '64f0c18f7c4d2f0012ab9000';

function buildRecord(overrides: Partial<TenantThemeRecord> = {}): TenantThemeRecord {
  return {
    id: 'theme-1',
    tenantId: TENANT_ID,
    primaryColorHex: '#111111',
    secondaryColorHex: '#222222',
    accentColorHex: '#333333',
    darkThemeEnabled: true,
    customAppTitle: 'Custom Shop',
    allowShopThemeOverride: false,
    updatedByAdminUserId: ADMIN_ID,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  };
}

describe('ThemeService', () => {
  function buildService(
    themeOverrides: Partial<TenantThemeRepository> = {},
    historyOverrides: Partial<ThemeHistoryRepository> = {},
  ): { service: ThemeService; themes: TenantThemeRepository; history: ThemeHistoryRepository } {
    const themes: TenantThemeRepository = {
      findByTenantId: jest.fn().mockResolvedValue(null),
      upsert: jest
        .fn()
        .mockImplementation(
          (tenantId: string, input: Partial<TenantThemeRecord>, adminId: string) =>
            Promise.resolve(buildRecord({ tenantId, ...input, updatedByAdminUserId: adminId })),
        ),
      ...themeOverrides,
    };
    const history: ThemeHistoryRepository = {
      append: jest
        .fn()
        .mockImplementation((entry) =>
          Promise.resolve({ id: 'hist-1', timestamp: new Date(), ...entry }),
        ),
      listByTenantId: jest.fn().mockResolvedValue([]),
      ...historyOverrides,
    };
    return { service: new ThemeService(themes, history), themes, history };
  }

  it("(a) returns the app's exact current defaults when the tenant has no TenantTheme record", async () => {
    const { service } = buildService({ findByTenantId: jest.fn().mockResolvedValue(null) });

    const result = await service.getEffectiveTheme(TENANT_ID);

    expect(result).toEqual({
      tenantId: TENANT_ID,
      isCustomized: false,
      primaryColorHex: DEFAULT_PRIMARY_COLOR_HEX,
      secondaryColorHex: DEFAULT_SECONDARY_COLOR_HEX,
      accentColorHex: DEFAULT_ACCENT_COLOR_HEX,
      darkThemeEnabled: DEFAULT_DARK_THEME_ENABLED,
      customAppTitle: DEFAULT_APP_TITLE,
      allowShopThemeOverride: false,
    });
  });

  it('(b) setTheme followed by getEffectiveTheme reflects the new values, not defaults', async () => {
    const { service, themes } = buildService();
    (themes.findByTenantId as jest.Mock).mockResolvedValueOnce(null); // no existing theme yet
    (themes.findByTenantId as jest.Mock).mockResolvedValue(
      buildRecord({ primaryColorHex: '#ABCDEF', customAppTitle: 'My Shop' }),
    );

    await service.setTheme(
      TENANT_ID,
      { primaryColorHex: '#ABCDEF', customAppTitle: 'My Shop' },
      ADMIN_ID,
    );
    const result = await service.getEffectiveTheme(TENANT_ID);

    expect(result.isCustomized).toBe(true);
    expect(result.primaryColorHex).toBe('#ABCDEF');
    expect(result.customAppTitle).toBe('My Shop');
  });

  it('writes a THEME_UPDATED ThemeHistory record with correct previous/new values on first assignment', async () => {
    const { service, history } = buildService({
      findByTenantId: jest.fn().mockResolvedValue(null),
    });

    await service.setTheme(TENANT_ID, { primaryColorHex: '#ABCDEF' }, ADMIN_ID);

    expect(history.append).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: TENANT_ID,
        action: ThemeHistoryAction.THEME_UPDATED,
        previousValue: undefined,
        actorAdminUserId: ADMIN_ID,
        newValue: expect.objectContaining({ primaryColorHex: '#ABCDEF' }),
      }),
    );
  });

  it('writes previousValue on a second theme update (real diff, not just existence)', async () => {
    const existing = buildRecord({ primaryColorHex: '#111111' });
    const { service, history } = buildService({
      findByTenantId: jest.fn().mockResolvedValue(existing),
    });

    await service.setTheme(TENANT_ID, { primaryColorHex: '#999999' }, ADMIN_ID);

    expect(history.append).toHaveBeenCalledWith(
      expect.objectContaining({
        previousValue: expect.objectContaining({ primaryColorHex: '#111111' }),
        newValue: expect.objectContaining({ primaryColorHex: '#999999' }),
      }),
    );
  });
});
