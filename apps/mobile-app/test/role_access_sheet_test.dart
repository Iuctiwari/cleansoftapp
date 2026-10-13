import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/features/staff/models/system_role.dart';
import 'package:nexoraa_mobile/features/staff/widgets/role_access_sheet.dart';

void main() {
  test('a role from the server keeps its default so it can be reset', () {
    final SystemRole role = SystemRole.fromJson(<String, dynamic>{
      'role': 'Staff',
      'description': 'd',
      'permissions': <String>['orders:read'],
      'defaultPermissions': <String>['orders:read', 'orders:write'],
      'editable': true,
      'isCustomized': true,
    });
    expect(role.editable, isTrue);
    expect(role.isCustomized, isTrue);
    expect(role.defaultPermissions, contains('orders:write'));
    // an older server without the new fields still parses, as a locked default role
    final SystemRole old = SystemRole.fromJson(<String, dynamic>{'role': 'Owner', 'description': 'd', 'permissions': <String>['x']});
    expect(old.editable, isFalse);
    expect(old.isCustomized, isFalse);
  });

  testWidgets('the owner switches modules on and off for a role, and edit implies see', (WidgetTester tester) async {
    List<String>? saved;
    const SystemRole role = SystemRole(
      role: 'Staff',
      description: 'd',
      permissions: <String>['orders:read', 'orders:write', 'customers:read', 'profile:read'],
      editable: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                saved = await showModalBottomSheet<List<String>>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const RoleAccessSheet(role: role),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // switch on Reports; switch off Customers; turn on Payments "record" which also turns on "see"
    await tester.scrollUntilVisible(find.byKey(const Key('role.access.reports:read')), 120, scrollable: find.descendant(of: find.byType(RoleAccessSheet), matching: find.byType(Scrollable)));
    await tester.tap(find.byKey(const Key('role.access.reports:read')));
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('role.access.customers:read')), 120, scrollable: find.descendant(of: find.byType(RoleAccessSheet), matching: find.byType(Scrollable)));
    await tester.tap(find.byKey(const Key('role.access.customers:read')));
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('role.access.payments:write')), 120, scrollable: find.descendant(of: find.byType(RoleAccessSheet), matching: find.byType(Scrollable)));
    await tester.tap(find.byKey(const Key('role.access.payments:write')));
    await tester.pump();
    await tester.scrollUntilVisible(find.byKey(const Key('role.access.save')), 120, scrollable: find.descendant(of: find.byType(RoleAccessSheet), matching: find.byType(Scrollable)));
    await tester.tap(find.byKey(const Key('role.access.save')));
    await tester.pumpAndSettle();

    expect(saved, containsAll(<String>['orders:read', 'orders:write', 'reports:read', 'payments:read', 'payments:write']));
    expect(saved, isNot(contains('customers:read')));
    // basics like profile are never part of what the owner picks
    expect(saved, isNot(contains('profile:read')));
  });
}
