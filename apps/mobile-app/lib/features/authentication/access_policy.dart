import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';

enum AppCapability {
  ordersView,
  ordersCreate,
  ordersEdit,
  ordersAssign,
  customersView,
  customersCreate,
  customersEdit,
  customersDelete,
  paymentsView,
  paymentsRecord,
  expensesView,
  expensesCreate,
  reportsView,
  staffView,
  staffManage,
  branchesView,
  branchesEdit,
  cashRegister,
  notificationsView,
  businessSettings,
  ownProfile,
  ownSecurity,
}

final class AccessPolicy {
  const AccessPolicy({
    required this.roleCode,
    this.permissions = const <String>[],
  });

  factory AccessPolicy.fromSession(AuthenticationSession? session) =>
      AccessPolicy(
        roleCode: session?.roleCode ?? '',
        permissions: session?.permissions ?? const <String>[],
      );

  final String roleCode;
  final List<String> permissions;
  bool get isOwner =>
      const <String>{'Owner', 'tenant_owner', 'owner'}.contains(roleCode);
  bool get isBranchManager =>
      const <String>{'Branch Manager', 'branch_manager'}.contains(roleCode);
  bool get isStaff => const <String>{'Staff', 'staff'}.contains(roleCode);
  bool hasPermission(String permission) =>
      isOwner || permissions.contains(permission);

  bool allows(AppCapability capability) {
    if (roleCode.isEmpty) return false;
    if (isOwner) return true;
    if (capability == AppCapability.ownProfile ||
        capability == AppCapability.ownSecurity) {
      return true;
    }
    if (isBranchManager) {
      return capability != AppCapability.businessSettings;
    }
    if (isStaff) {
      if (const <AppCapability>{
        AppCapability.ordersView,
        AppCapability.ordersEdit,
        AppCapability.customersView,
        AppCapability.customersCreate,
        AppCapability.notificationsView,
        AppCapability.paymentsView,
        AppCapability.paymentsRecord,
      }.contains(capability)) {
        return true;
      }
      return switch (capability) {
        AppCapability.expensesView => hasPermission('expenses:read'),
        AppCapability.expensesCreate => hasPermission('expenses:write'),
        AppCapability.reportsView => hasPermission('reports:read'),
        AppCapability.cashRegister => hasPermission('cash-register:access'),
        _ => false,
      };
    }
    return false;
  }
}
