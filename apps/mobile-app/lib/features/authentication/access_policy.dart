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
  /// Set by the server when the owner chose exactly which modules this person gets.
  static const String customAccessMarker = 'access:custom';

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
      return true;
    }
    if (isStaff && permissions.contains(customAccessMarker)) {
      // Custom access: exactly what the owner ticked, nothing assumed from the role.
      return switch (capability) {
        AppCapability.notificationsView => true,
        AppCapability.ordersView => permissions.contains('orders:read'),
        AppCapability.ordersCreate || AppCapability.ordersEdit => permissions.contains('orders:write'),
        AppCapability.customersView => permissions.contains('customers:read'),
        AppCapability.customersCreate || AppCapability.customersEdit => permissions.contains('customers:write'),
        AppCapability.paymentsView => permissions.contains('payments:read'),
        AppCapability.paymentsRecord => permissions.contains('payments:write'),
        AppCapability.expensesView => permissions.contains('expenses:read'),
        AppCapability.expensesCreate => permissions.contains('expenses:write'),
        AppCapability.reportsView => permissions.contains('reports:read'),
        AppCapability.cashRegister => permissions.contains('cash-register:access'),
        _ => false,
      };
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
