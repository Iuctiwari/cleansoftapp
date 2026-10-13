import {
  ALWAYS_ON_PERMISSIONS,
  CUSTOM_ACCESS_MARKER,
  sanitizeCustomPermissions,
  staffEffectivePermissions,
} from '@nexoraa/shared';

describe('staff custom access', () => {
  it('keeps the role defaults when access is not custom', () => {
    const result = staffEffectivePermissions('Staff', [], false);
    expect(result).toContain('orders:write');
    expect(result).toContain('customers:read');
    expect(result).not.toContain(CUSTOM_ACCESS_MARKER);
  });

  it('gives exactly the chosen modules plus the basics when custom', () => {
    const result = staffEffectivePermissions('Staff', ['orders:read', 'payments:write'], true);
    expect(result).toEqual(
      expect.arrayContaining([...ALWAYS_ON_PERMISSIONS, 'orders:read', 'payments:write', CUSTOM_ACCESS_MARKER]),
    );
    expect(result).not.toContain('orders:write');
    expect(result).not.toContain('customers:read');
  });

  it('custom with nothing ticked still keeps the basics', () => {
    const result = staffEffectivePermissions('Staff', [], true);
    expect([...result].sort()).toEqual([...ALWAYS_ON_PERMISSIONS, CUSTOM_ACCESS_MARKER].sort());
  });

  it('never lets an owner hand out management permissions', () => {
    expect(
      sanitizeCustomPermissions(['orders:read', 'staff:write', 'branches:write', 'orders:assign', 'orders:read', 42]),
    ).toEqual(['orders:read']);
  });
});
