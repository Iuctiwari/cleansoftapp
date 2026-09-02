import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/role_dashboard_screen.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  testWidgets('Staff dashboard renders its role-specific UI', (
    WidgetTester tester,
  ) async {
    await _pumpRoleDashboard(tester, RoleDashboardKind.staff);

    expect(find.text('MY TASKS TODAY'), findsOneWidget);
    expect(find.text('My Assigned Orders'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Branch Manager dashboard renders its role-specific UI', (
    WidgetTester tester,
  ) async {
    await _pumpRoleDashboard(tester, RoleDashboardKind.branchManager);

    expect(find.text('Branch Orders'), findsOneWidget);
    expect(find.text('Cash Register'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Branch Manager uses the authenticated assigned branch', (
    WidgetTester tester,
  ) async {
    final DateTime expiresAt = DateTime.now().add(const Duration(hours: 1));
    await _pumpRoleDashboard(
      tester,
      RoleDashboardKind.branchManager,
      session: AuthenticationSession(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        accessTokenExpiresAt: expiresAt,
        refreshTokenExpiresAt: expiresAt,
        tenantId: 'tenant-1',
        ownerUserId: 'manager-1',
        ownerName: 'Branch Manager User',
        roleCode: 'Branch Manager',
        branchId: 'assigned-branch-1',
        branchName: 'Assigned Branch',
      ),
    );

    expect(find.text('Branch Manager - Assigned Branch'), findsOneWidget);
    expect(find.text('Hassan Ali'), findsNothing);
    expect(find.text('18'), findsNothing);
    expect(find.textContaining('Select an active branch'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRoleDashboard(
  WidgetTester tester,
  RoleDashboardKind kind, {
  AuthenticationSession? session,
}) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: RoleDashboardScreen(kind: kind, session: session),
    ),
  );
  await tester.pump();
}
