export const Roles = Object.freeze({
  owner: 'Owner',
  branchManager: 'Branch Manager',
  staff: 'Staff',
  cashier: 'Cashier',
} as const);

export const Permissions = Object.freeze({
  ordersRead: 'orders:read',
  ordersWrite: 'orders:write',
  ordersAssign: 'orders:assign',
  customersRead: 'customers:read',
  customersWrite: 'customers:write',
  customersDelete: 'customers:delete',
  paymentsRead: 'payments:read',
  paymentsWrite: 'payments:write',
  expensesRead: 'expenses:read',
  expensesWrite: 'expenses:write',
  reportsRead: 'reports:read',
  staffRead: 'staff:read',
  staffWrite: 'staff:write',
  branchesRead: 'branches:read',
  branchesWrite: 'branches:write',
  cashRegisterAccess: 'cash-register:access',
  notificationsRead: 'notifications:read',
  businessSettingsWrite: 'business-settings:write',
  profileRead: 'profile:read',
  profileWrite: 'profile:write',
  securityWrite: 'security:write',
} as const);

const ROLE_ALIASES = Object.freeze({
  owner: new Set<string>([Roles.owner, 'tenant_owner', 'owner']),
  branchManager: new Set<string>([Roles.branchManager, 'branch_manager']),
  staff: new Set<string>([Roles.staff, 'staff']),
  cashier: new Set<string>([Roles.cashier, 'cashier']),
});

export function isOwnerRole(roleCode: string | undefined): boolean {
  return roleCode !== undefined && ROLE_ALIASES.owner.has(roleCode);
}

export function isBranchManagerRole(roleCode: string | undefined): boolean {
  return roleCode !== undefined && ROLE_ALIASES.branchManager.has(roleCode);
}

export function isStaffRole(roleCode: string | undefined): boolean {
  return roleCode !== undefined && ROLE_ALIASES.staff.has(roleCode);
}

export function isCashierRole(roleCode: string | undefined): boolean {
  return roleCode !== undefined && ROLE_ALIASES.cashier.has(roleCode);
}

export function hasPermission(
  roleCode: string | undefined,
  permissions: readonly string[],
  permission: string,
): boolean {
  return isOwnerRole(roleCode) || permissions.includes(permission);
}

export function defaultPermissionsForRole(roleCode: string): readonly string[] {
  if (isOwnerRole(roleCode)) return Object.freeze(Object.values(Permissions));
  if (isBranchManagerRole(roleCode)) {
    return Object.freeze([
      Permissions.ordersRead,
      Permissions.ordersWrite,
      Permissions.ordersAssign,
      Permissions.customersRead,
      Permissions.customersWrite,
      Permissions.customersDelete,
      Permissions.paymentsRead,
      Permissions.paymentsWrite,
      Permissions.expensesRead,
      Permissions.expensesWrite,
      Permissions.reportsRead,
      Permissions.staffRead,
      Permissions.staffWrite,
      Permissions.branchesRead,
      Permissions.branchesWrite,
      Permissions.cashRegisterAccess,
      Permissions.notificationsRead,
      Permissions.profileRead,
      Permissions.profileWrite,
      Permissions.securityWrite,
    ]);
  }
  if (isStaffRole(roleCode)) {
    return Object.freeze([
      Permissions.ordersRead,
      Permissions.ordersWrite,
      Permissions.customersRead,
      Permissions.customersWrite,
      Permissions.notificationsRead,
      Permissions.profileRead,
      Permissions.profileWrite,
      Permissions.securityWrite,
    ]);
  }
  return Object.freeze([]);
}

export function effectivePermissions(
  roleCode: string,
  storedPermissions: readonly string[],
): readonly string[] {
  return Object.freeze([
    ...new Set([...storedPermissions, ...defaultPermissionsForRole(roleCode)]),
  ]);
}
