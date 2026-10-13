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

describe('role access chosen by the shop owner', () => {
  it('keeps the platform default when the owner changed nothing', () => {
    const result = staffEffectivePermissions('Staff', [], false, undefined);
    expect(result).toContain('orders:write');
    expect(result).not.toContain(CUSTOM_ACCESS_MARKER);
  });

  it('gives Staff exactly the modules the owner ticked for the role', () => {
    const result = staffEffectivePermissions('Staff', [], false, ['orders:read', 'reports:read']);
    expect(result).toContain('reports:read');
    expect(result).toContain(CUSTOM_ACCESS_MARKER);
    expect(result).not.toContain('orders:write');
    expect(result).not.toContain('customers:read');
  });

  it('a Branch Manager keeps the management powers whatever modules are ticked', () => {
    const result = staffEffectivePermissions('Branch Manager', [], false, ['orders:read']);
    expect(result).toEqual(
      expect.arrayContaining(['staff:write', 'branches:write', 'orders:assign', 'orders:read']),
    );
    expect(result).not.toContain('payments:write');
  });

  it('a person with their own custom access ignores the role change', () => {
    const result = staffEffectivePermissions('Staff', ['orders:read'], true, ['reports:read']);
    expect(result).toContain('orders:read');
    expect(result).not.toContain('reports:read');
  });

  it('owners and other roles are never touched by overrides', () => {
    const owner = staffEffectivePermissions('Owner', [], false, ['orders:read']);
    expect(owner).toContain('payments:write');
    expect(owner).not.toContain(CUSTOM_ACCESS_MARKER);
  });
});
