import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/branch/screens/branch_details_screen.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

class _FakeTokenStorage implements AuthTokenStorage {
  AuthenticationSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<AuthenticationSession?> read() async => session;

  @override
  Future<void> write(AuthenticationSession value) async => session = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String tenantId = '64f0c18f7c4d2f0012ab34bb';
  const String branchId = '64f0c18f7c4d2f0012ab34cc';

  final Branch branchWithManager = Branch(
    branchId: branchId,
    tenantId: tenantId,
    branchName: 'Main Branch',
    streetAddress: '123 Main St',
    city: 'Mumbai',
    state: 'MH',
    country: 'IN',
    postalCode: '400001',
    phone: '+91 9876543210',
    email: 'main@nexoraa.com',
    isHeadOffice: true,
    status: BranchStatus.active,
    createdAt: '2026-01-01T00:00:00.000Z',
    updatedAt: '2026-01-01T00:00:00.000Z',
    managerId: 'user-manager-1',
    managerName: 'Usman Ali',
    totalStaff: 3,
    totalOrders: 1240,
    ordersToday: 24,
  );

  final List<Map<String, dynamic>> fakeUsers = [
    {
      'id': 'user-manager-1',
      'userId': 'user-manager-1',
      'tenantId': tenantId,
      'email': 'usman@nexoraa.com',
      'name': 'Usman Ali',
      'role': 'Branch Manager',
      'status': 'Active',
      'branchIds': [branchId],
      'branches': [branchId],
    },
    {
      'id': 'user-staff-1',
      'userId': 'user-staff-1',
      'tenantId': tenantId,
      'email': 'asif@nexoraa.com',
      'name': 'Muhammad Asif',
      'role': 'Presser',
      'status': 'Active',
      'branchIds': [branchId],
      'branches': [branchId],
    },
  ];

  testWidgets('BranchDetailsScreen renders manager card and statistics', (
    WidgetTester tester,
  ) async {
    final client = MockClient((http.Request request) async {
      if (request.url.path.contains('/api/v1/users/tenant/')) {
        return http.Response(
          jsonEncode(fakeUsers),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 404);
    });

    final storage = _FakeTokenStorage();
    final staffApiService = StaffApiService(
      client: client,
      baseUrl: 'http://test-staff.local',
      tokenStorage: storage,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BranchDetailsScreen(
          branch: branchWithManager,
          staffApiService: staffApiService,
        ),
      ),
    );

    // Pump and wait for async tasks
    await tester.pump();
    await tester.pumpAndSettle();

    // Verify branch details header
    expect(find.text('Branch Details'), findsOneWidget);
    expect(find.text('Main Branch'), findsOneWidget);

    // Verify stats
    expect(find.text('Total Staff'), findsOneWidget);
    expect(find.text('Orders Today'), findsOneWidget);
    expect(find.text('Total Orders'), findsOneWidget);

    // Verify Branch Manager section
    expect(find.text('Branch Manager'), findsWidgets);
    expect(find.text('Usman Ali'), findsWidgets);

    // Verify Staff section
    expect(find.text('Muhammad Asif'), findsOneWidget);
  });
}
