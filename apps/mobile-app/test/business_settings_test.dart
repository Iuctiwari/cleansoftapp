import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard.dart';
import 'package:nexoraa_mobile/features/settings/settings.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

class _FakeTokenStorage implements AuthTokenStorage {
  _FakeTokenStorage(this.session);
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

  group('Business Settings Access Policy', () {
    test('Allows Owner and Branch Manager, disallows Staff', () {
      final ownerSession = AuthenticationSession(
        accessToken: 'owner-tok',
        accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
        refreshToken: 'owner-ref',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
        roleCode: 'Owner',
      );
      final managerSession = AuthenticationSession(
        accessToken: 'mgr-tok',
        accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
        refreshToken: 'mgr-ref',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
        roleCode: 'Branch Manager',
      );
      final staffSession = AuthenticationSession(
        accessToken: 'staff-tok',
        accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
        refreshToken: 'staff-ref',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
        roleCode: 'Staff',
      );

      final ownerPolicy = AccessPolicy.fromSession(ownerSession);
      final managerPolicy = AccessPolicy.fromSession(managerSession);
      final staffPolicy = AccessPolicy.fromSession(staffSession);

      expect(ownerPolicy.allows(AppCapability.businessSettings), isTrue);
      expect(managerPolicy.allows(AppCapability.businessSettings), isTrue);
      expect(staffPolicy.allows(AppCapability.businessSettings), isFalse);
    });
  });

  group('MoreScreen Business Settings Visibility', () {
    testWidgets(
      'Shows Business Settings for Owner and Manager, hides for Staff',
      (WidgetTester tester) async {
        final ownerPolicy = const AccessPolicy(roleCode: 'Owner');
        final staffPolicy = const AccessPolicy(roleCode: 'Staff');

        // Test Owner view
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MoreScreen(
                businessName: 'Nexoraa CleanSoft',
                role: 'Owner',
                accessPolicy: ownerPolicy,
                userProfile: const MoreUserProfileData(
                  name: 'Test Owner',
                  email: 'owner@example.com',
                ),
                onExpensesTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Business Settings'), findsOneWidget);

        // Test Staff view
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MoreScreen(
                businessName: 'Nexoraa CleanSoft',
                role: 'Staff',
                accessPolicy: staffPolicy,
                userProfile: const MoreUserProfileData(
                  name: 'Test Staff',
                  email: 'staff@example.com',
                ),
                onExpensesTap: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Business Settings'), findsNothing);
      },
    );
  });

  group('BusinessSettingsScreen UI', () {
    testWidgets(
      'Renders all required sections in exact order and excludes Business Profile',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: BusinessSettingsScreen()),
        );
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Business Settings'), findsOneWidget);

        // Section 1: Services
        expect(find.text('Services'), findsOneWidget);
        expect(find.text('Manage your service offerings'), findsOneWidget);

        // Section 2: Item Categories
        expect(find.text('Item Categories'), findsOneWidget);
        expect(find.text('Organize items into categories'), findsOneWidget);

        // Section 3: Pricing
        expect(find.text('Pricing'), findsOneWidget);
        expect(find.text('Set prices per item / service'), findsOneWidget);

        // Section 4: Preferences Section
        expect(find.text('PREFERENCES'), findsOneWidget);
        expect(find.text('Notifications'), findsOneWidget);
        expect(find.text('Push, SMS & in-app alerts'), findsOneWidget);
        expect(find.text('Roles & Permissions'), findsOneWidget);
        expect(find.text('Access control for staff'), findsOneWidget);

        // Explicitly excluded sections
        expect(find.text('Business Profile'), findsNothing);
        expect(find.text('Working Hours'), findsNothing);
        expect(find.text('Taxes / GST'), findsNothing);

        // Tap Services to test interaction
        await tester.tap(find.text('Services'));
        await tester.pumpAndSettle();
        expect(
          find.text('Services settings will be available soon.'),
          findsOneWidget,
        );
      },
    );
  });

  group('RolesAndStaffScreen UI', () {
    testWidgets(
      'Renders Owner at top, Branch Manager below Owner, branch staff as Worker/Cashier, and exactly 3 staff roles in dropdown',
      (WidgetTester tester) async {
        const String tenantId = 'tenant-123';
        const String branchId = 'branch-main';

        final session = AuthenticationSession(
          accessToken: 'tok',
          accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
          refreshToken: 'ref',
          refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
          roleCode: 'Branch Manager',
          tenantId: tenantId,
          branchId: branchId,
          ownerName: 'Muhammad Asif', // Logged in user's name
          ownerEmail: 'asif@example.com',
        );

        final fakeUsers = [
          {
            'id': 'owner-1',
            'userId': 'owner-1',
            'tenantId': tenantId,
            'email': 'owner@example.com',
            'name': 'Ahmed Khan',
            'role': 'Owner',
            'status': 'Active',
            'branchIds': [],
          },
          {
            'id': 'user-1',
            'userId': 'user-1',
            'tenantId': tenantId,
            'email': 'asif@example.com',
            'name': 'Muhammad Asif',
            'role': 'Branch Manager',
            'status': 'Active',
            'branchIds': [branchId],
          },
          {
            'id': 'user-2',
            'userId': 'user-2',
            'tenantId': tenantId,
            'email': 'aisha@example.com',
            'name': 'Aisha Noor',
            'role': 'Staff',
            'status': 'Active',
            'branchIds': [branchId],
          },
          {
            'id': 'user-3',
            'userId': 'user-3',
            'tenantId': tenantId,
            'email': 'other@example.com',
            'name': 'Other Branch Staff',
            'role': 'Staff',
            'status': 'Active',
            'branchIds': ['other-branch-id'], // Should be filtered out
          },
        ];

        final client = MockClient((http.Request request) async {
          if (request.url.path.contains('/api/v1/users/tenant/')) {
            return http.Response(
              jsonEncode(fakeUsers),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.contains('/api/v1/tenants/')) {
            return http.Response(
              jsonEncode({
                'tenantId': tenantId,
                'businessName': 'Nexoraa CleanSoft',
                'ownerName': 'Ahmed Khan',
                'ownerEmail': 'owner@example.com',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        });

        final staffApiService = StaffApiService(
          client: client,
          tokenStorage: _FakeTokenStorage(session),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RolesAndStaffScreen(
              staffApiService: staffApiService,
              session: session,
            ),
          ),
        );

        // Let initial async load settle
        await tester.pump();
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Roles & Staff'), findsOneWidget);
        expect(find.text('Manage access control'), findsOneWidget);

        // 1. Owner card at top displays real tenant owner (Ahmed Khan), not Branch Manager
        expect(find.text('Ahmed Khan'), findsOneWidget);
        expect(find.text('Owner'), findsOneWidget);

        // 2. Branch Manager (Muhammad Asif) is displayed with Branch Manager role
        expect(find.text('Muhammad Asif'), findsOneWidget);
        expect(find.text('Branch Manager'), findsWidgets);

        // 3. Worker (Aisha Noor) is displayed with Worker role
        expect(find.text('Aisha Noor'), findsOneWidget);
        expect(find.text('Worker'), findsWidgets);

        // Other branch staff should NOT appear (strict branch isolation)
        expect(find.text('Other Branch Staff'), findsNothing);

        // View permissions buttons
        expect(find.text('View Permissions'), findsNWidgets(2));

        // Tap View Permissions for Branch Manager
        await tester.tap(find.text('View Permissions').first);
        await tester.pumpAndSettle();
        expect(find.text('Branch Manager Permissions'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Tap Role dropdown for Worker to verify exact 3 options
        await tester.tap(find.text('Worker').last);
        await tester.pumpAndSettle();

        // Dropdown menu items
        expect(find.text('Branch Manager'), findsWidgets);
        expect(find.text('Worker'), findsWidgets);
        expect(find.text('Cashier'), findsWidgets);

        // Close menu
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Switch to Roles tab
        await tester.tap(find.text('Roles'));
        await tester.pumpAndSettle();

        expect(find.text('14 permissions enabled'), findsOneWidget);
        expect(find.text('4 permissions enabled'), findsOneWidget);
        expect(find.text('6 permissions enabled'), findsOneWidget);
      },
    );
  });
}
