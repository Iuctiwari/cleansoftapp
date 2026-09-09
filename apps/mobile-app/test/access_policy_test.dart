import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';

void main() {
  test('Owner retains full access', () {
    const policy = AccessPolicy(roleCode: 'Owner');
    for (final capability in AppCapability.values) {
      expect(policy.allows(capability), isTrue, reason: capability.name);
    }
  });

  test('Branch Manager receives operational access and Business Settings', () {
    const policy = AccessPolicy(roleCode: 'Branch Manager');
    expect(policy.allows(AppCapability.ordersAssign), isTrue);
    expect(policy.allows(AppCapability.paymentsRecord), isTrue);
    expect(policy.allows(AppCapability.staffManage), isTrue);
    expect(policy.allows(AppCapability.branchesEdit), isTrue);
    expect(policy.allows(AppCapability.cashRegister), isTrue);
    expect(policy.allows(AppCapability.businessSettings), isTrue);
  });

  test(
    'Staff receives only assigned-work customer and account capabilities',
    () {
      const policy = AccessPolicy(roleCode: 'Staff');
      expect(policy.allows(AppCapability.ordersView), isTrue);
      expect(policy.allows(AppCapability.ordersEdit), isTrue);
      expect(policy.allows(AppCapability.ordersCreate), isFalse);
      expect(policy.allows(AppCapability.ordersAssign), isFalse);
      expect(policy.allows(AppCapability.customersView), isTrue);
      expect(policy.allows(AppCapability.customersCreate), isTrue);
      expect(policy.allows(AppCapability.paymentsView), isTrue);
      expect(policy.allows(AppCapability.paymentsRecord), isTrue);
      expect(policy.allows(AppCapability.expensesView), isFalse);
      expect(policy.allows(AppCapability.reportsView), isFalse);
      expect(policy.allows(AppCapability.staffView), isFalse);
      expect(policy.allows(AppCapability.branchesView), isFalse);
      expect(policy.allows(AppCapability.businessSettings), isFalse);
      expect(policy.allows(AppCapability.ownProfile), isTrue);
      expect(policy.allows(AppCapability.ownSecurity), isTrue);
    },
  );

  test(
    'explicit optional Staff permissions enable only supported optional areas',
    () {
      const policy = AccessPolicy(
        roleCode: 'Staff',
        permissions: <String>['reports:read', 'cash-register:access'],
      );
      expect(policy.allows(AppCapability.reportsView), isTrue);
      expect(policy.allows(AppCapability.cashRegister), isTrue);
      expect(policy.allows(AppCapability.staffView), isFalse);
    },
  );
}
