import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';

void main() {
  test('default staff keep the usual access', () {
    const AccessPolicy policy = AccessPolicy(roleCode: 'Staff', permissions: <String>['orders:read', 'orders:write']);
    expect(policy.allows(AppCapability.ordersView), isTrue);
    expect(policy.allows(AppCapability.ordersEdit), isTrue);
    expect(policy.allows(AppCapability.customersView), isTrue);
    expect(policy.allows(AppCapability.paymentsRecord), isTrue);
    expect(policy.allows(AppCapability.reportsView), isFalse);
  });

  test('custom staff get exactly what the owner ticked', () {
    const AccessPolicy policy = AccessPolicy(
      roleCode: 'Staff',
      permissions: <String>['access:custom', 'orders:read', 'reports:read', 'notifications:read'],
    );
    expect(policy.allows(AppCapability.ordersView), isTrue);
    expect(policy.allows(AppCapability.reportsView), isTrue);
    // not ticked: no longer assumed from the Staff role
    expect(policy.allows(AppCapability.ordersEdit), isFalse);
    expect(policy.allows(AppCapability.customersView), isFalse);
    expect(policy.allows(AppCapability.paymentsRecord), isFalse);
    // always on
    expect(policy.allows(AppCapability.notificationsView), isTrue);
    expect(policy.allows(AppCapability.ownProfile), isTrue);
    // never granted to staff
    expect(policy.allows(AppCapability.staffManage), isFalse);
  });

  test('owners and managers are never narrowed by the marker', () {
    const AccessPolicy owner = AccessPolicy(roleCode: 'Owner', permissions: <String>['access:custom']);
    expect(owner.allows(AppCapability.reportsView), isTrue);
  });
}
