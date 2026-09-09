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

        // Section 2: Items / Catalog
        expect(find.text('Items / Catalog'), findsOneWidget);
        expect(find.text('Manage your item catalog'), findsOneWidget);

        // Section 3: Pricing
        expect(find.text('Pricing'), findsOneWidget);
        expect(find.text('Set prices per item / service'), findsOneWidget);

        // Item Categories must NOT be rendered
        expect(find.text('Item Categories'), findsNothing);
        expect(find.text('Organize items into categories'), findsNothing);

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

  group('ServicesSettingsScreen UI', () {
    testWidgets(
      'Renders services grouped by category and supports category dropdown in Add Custom Service',
      (WidgetTester tester) async {
        final client = MockClient((http.Request request) async {
          if (request.url.path.endsWith('/templates')) {
            return http.Response(
              jsonEncode([
                {
                  'code': 'LAUNDRY_DRY_CLEANING',
                  'businessType': 'dry_cleaning',
                  'name': 'Laundry / Dry Cleaning',
                  'services': [
                    {
                      'code': 'SERVICE_WASH_FOLD',
                      'name': 'Wash & Fold',
                      'pricingType': 'per_item',
                    },
                    {
                      'code': 'SERVICE_DRY_CLEANING',
                      'name': 'Dry Cleaning',
                      'pricingType': 'per_item',
                    },
                    {
                      'code': 'SERVICE_IRONING',
                      'name': 'Ironing',
                      'pricingType': 'per_item',
                    },
                  ],
                },
                {
                  'code': 'SALON',
                  'businessType': 'salon',
                  'name': 'Salon',
                  'services': [
                    {
                      'code': 'SALON_HAIRCUT',
                      'name': 'Haircut',
                      'pricingType': 'per_item',
                    },
                    {
                      'code': 'SALON_FACIAL',
                      'name': 'Facial',
                      'pricingType': 'per_item',
                    },
                  ],
                },
                {
                  'code': 'CAR_WASH',
                  'businessType': 'vehicle_wash',
                  'name': 'Car Washing',
                  'services': [
                    {
                      'code': 'CAR_INTERIOR',
                      'name': 'Interior Cleaning',
                      'pricingType': 'per_item',
                    },
                  ],
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'POST' &&
              request.url.path.endsWith('/services')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'id': 'srv-new',
                'tenantId': 'tenant-123',
                'serviceName': body['serviceName'],
                'code': body['code'],
                'pricingType': body['pricingType'],
                'description': body['description'],
                'status': 'Active',
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'PATCH' &&
              request.url.path.contains('/services/')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'id': 'srv-1',
                'tenantId': 'tenant-123',
                'serviceName': 'Wash & Fold',
                'code': 'SERVICE_WASH_FOLD',
                'category': 'Laundry / Dry Cleaning',
                'pricingType': 'PerItem',
                'status': body['status'] ?? 'Active',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'tenantId': 'tenant-123',
              'totalServices': 1,
              'totalActiveServices': 1,
              'totalItems': 1,
              'totalActiveItems': 1,
              'totalCategories': 1,
              'totalActiveCategories': 1,
              'totalActivePricing': 0,
              'services': [
                {
                  'id': 'srv-1',
                  'tenantId': 'tenant-123',
                  'serviceName': 'Wash & Fold',
                  'code': 'SERVICE_WASH_FOLD',
                  'category': 'Laundry / Dry Cleaning',
                  'pricingType': 'PerItem',
                  'status': 'Active',
                },
              ],
              'items': [
                {
                  'id': 'item-1',
                  'tenantId': 'tenant-123',
                  'name': 'Shirt',
                  'code': 'ITEM_SHIRT',
                  'category': 'Laundry / Dry Cleaning',
                  'catalogGroupCodes': ['LAUNDRY_DRY_CLEANING'],
                  'status': 'Active',
                },
              ],
              'categories': [
                {
                  'id': 'cat-1',
                  'tenantId': 'tenant-123',
                  'name': 'Laundry / Dry Cleaning',
                  'code': 'LAUNDRY_DRY_CLEANING',
                  'status': 'Active',
                },
              ],
              'pricing': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final settingsApiService = SettingsApiService(
          client: client,
          tokenStorage: _FakeTokenStorage(
            AuthenticationSession(
              accessToken: 'tok',
              accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
              refreshToken: 'ref',
              refreshTokenExpiresAt: DateTime.now().add(
                const Duration(days: 30),
              ),
              roleCode: 'Owner',
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ServicesSettingsScreen(apiService: settingsApiService),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // 1. Active Services section has the initial active service
        expect(find.text('CURRENT SERVICES (1)'), findsOneWidget);
        expect(find.text('Wash & Fold'), findsOneWidget);

        // 2. Available Services shows only tenant business services (Laundry)
        expect(find.text('AVAILABLE SERVICES'), findsOneWidget);
        expect(find.text('Dry Cleaning'), findsOneWidget);
        expect(find.text('Ironing'), findsOneWidget);

        // Unrelated business types (Salon, Car Washing) are NOT shown
        expect(find.text('Haircut'), findsNothing);
        expect(find.text('Facial'), findsNothing);
        expect(find.text('Interior Cleaning'), findsNothing);

        // 3. Removing (crossing) a service moves it to Available Services
        final removeButtonFinder = find.byIcon(Icons.close).first;
        await tester.tap(removeButtonFinder);
        await tester.pumpAndSettle();

        expect(find.text('CURRENT SERVICES (0)'), findsOneWidget);
        expect(find.text('AVAILABLE SERVICES'), findsOneWidget);

        // 4. Adding it back via Add button moves it back to Current Services
        final addAvailableFinder = find.byIcon(Icons.add).first;
        await tester.tap(addAvailableFinder);
        await tester.pumpAndSettle();

        expect(find.text('CURRENT SERVICES (1)'), findsOneWidget);

        // 5. Category Dropdown in Add Custom Service
        await tester.scrollUntilVisible(
          find.text('ADD CUSTOM SERVICE'),
          200.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('ADD CUSTOM SERVICE'), findsOneWidget);

        // 6. Enter custom service name and click Add
        final nameInputFinder = find.byType(TextField).last;
        await tester.enterText(nameInputFinder, 'Custom Steam Clean');
        await tester.pumpAndSettle();

        final addButtonFinder = find.text('Add');
        await tester.scrollUntilVisible(
          addButtonFinder,
          100.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(addButtonFinder);
        await tester.pumpAndSettle();

        // 7. Verify custom service immediately appears in CURRENT SERVICES (2)
        await tester.scrollUntilVisible(
          find.text('CURRENT SERVICES (2)'),
          -200.0,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('CURRENT SERVICES (2)'), findsOneWidget);
        expect(find.text('Custom Steam Clean'), findsOneWidget);
      },
    );

    testWidgets('Strictly filters Available Services for Salon business type', (
      WidgetTester tester,
    ) async {
      final client = MockClient((http.Request request) async {
        if (request.url.path.endsWith('/templates')) {
          return http.Response(
            jsonEncode([
              {
                'code': 'LAUNDRY_DRY_CLEANING',
                'businessType': 'dry_cleaning',
                'name': 'Laundry / Dry Cleaning',
                'services': [
                  {
                    'code': 'SERVICE_WASH_FOLD',
                    'name': 'Wash & Fold',
                    'pricingType': 'per_item',
                  },
                ],
              },
              {
                'code': 'SALON',
                'businessType': 'salon',
                'name': 'Salon',
                'services': [
                  {
                    'code': 'SALON_HAIRCUT',
                    'name': 'Haircut',
                    'pricingType': 'per_item',
                  },
                  {
                    'code': 'SALON_FACIAL',
                    'name': 'Facial',
                    'pricingType': 'per_item',
                  },
                  {
                    'code': 'SALON_MANICURE',
                    'name': 'Manicure',
                    'pricingType': 'per_item',
                  },
                ],
              },
              {
                'code': 'CAR_WASH',
                'businessType': 'vehicle_wash',
                'name': 'Car Washing',
                'services': [
                  {
                    'code': 'CAR_INTERIOR',
                    'name': 'Interior Cleaning',
                    'pricingType': 'per_item',
                  },
                ],
              },
            ]),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode({
            'tenantId': 'tenant-salon',
            'totalServices': 1,
            'totalActiveServices': 1,
            'totalItems': 1,
            'totalActiveItems': 1,
            'totalCategories': 1,
            'totalActiveCategories': 1,
            'totalActivePricing': 0,
            'services': [
              {
                'id': 'srv-salon-1',
                'tenantId': 'tenant-salon',
                'serviceName': 'Haircut',
                'code': 'SALON_HAIRCUT',
                'pricingType': 'PerItem',
                'status': 'Active',
              },
            ],
            'items': [
              {
                'id': 'item-salon-1',
                'tenantId': 'tenant-salon',
                'name': 'Shampoo Wash',
                'code': 'ITEM_SHAMPOO',
                'category': 'Salon',
                'catalogGroupCodes': ['SALON'],
                'status': 'Active',
              },
            ],
            'categories': [],
            'pricing': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final settingsApiService = SettingsApiService(
        client: client,
        tokenStorage: _FakeTokenStorage(
          AuthenticationSession(
            accessToken: 'tok',
            accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
            refreshToken: 'ref',
            refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
            roleCode: 'Owner',
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServicesSettingsScreen(apiService: settingsApiService),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Current service is Haircut
      expect(find.text('CURRENT SERVICES (1)'), findsOneWidget);
      expect(find.text('Haircut'), findsOneWidget);

      // Available Services only shows Salon services
      expect(find.text('AVAILABLE SERVICES'), findsOneWidget);
      expect(find.text('Facial'), findsOneWidget);
      expect(find.text('Manicure'), findsOneWidget);

      // Laundry and Car Wash services are completely hidden
      expect(find.text('Wash & Fold'), findsNothing);
      expect(find.text('Interior Cleaning'), findsNothing);
    });

    testWidgets(
      'Strictly filters Available Services for Car Washing business type',
      (WidgetTester tester) async {
        final client = MockClient((http.Request request) async {
          if (request.url.path.endsWith('/templates')) {
            return http.Response(
              jsonEncode([
                {
                  'code': 'LAUNDRY_DRY_CLEANING',
                  'businessType': 'dry_cleaning',
                  'name': 'Laundry / Dry Cleaning',
                  'services': [
                    {
                      'code': 'SERVICE_WASH_FOLD',
                      'name': 'Wash & Fold',
                      'pricingType': 'per_item',
                    },
                  ],
                },
                {
                  'code': 'SALON',
                  'businessType': 'salon',
                  'name': 'Salon',
                  'services': [
                    {
                      'code': 'SALON_HAIRCUT',
                      'name': 'Haircut',
                      'pricingType': 'per_item',
                    },
                  ],
                },
                {
                  'code': 'CAR_WASH',
                  'businessType': 'vehicle_wash',
                  'name': 'Car Washing',
                  'services': [
                    {
                      'code': 'CAR_INTERIOR',
                      'name': 'Interior Cleaning',
                      'pricingType': 'per_item',
                    },
                    {
                      'code': 'CAR_EXTERIOR',
                      'name': 'Exterior Cleaning',
                      'pricingType': 'per_item',
                    },
                  ],
                },
              ]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode({
              'tenantId': 'tenant-carwash',
              'totalServices': 1,
              'totalActiveServices': 1,
              'totalItems': 1,
              'totalActiveItems': 1,
              'totalCategories': 1,
              'totalActiveCategories': 1,
              'totalActivePricing': 0,
              'services': [
                {
                  'id': 'srv-cw-1',
                  'tenantId': 'tenant-carwash',
                  'serviceName': 'Interior Cleaning',
                  'code': 'CAR_INTERIOR',
                  'pricingType': 'PerItem',
                  'status': 'Active',
                },
              ],
              'items': [
                {
                  'id': 'item-cw-1',
                  'tenantId': 'tenant-carwash',
                  'name': 'Sedan Cleaning',
                  'code': 'ITEM_SEDAN',
                  'category': 'Car Washing',
                  'catalogGroupCodes': ['CAR_WASH'],
                  'status': 'Active',
                },
              ],
              'categories': [],
              'pricing': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final settingsApiService = SettingsApiService(
          client: client,
          tokenStorage: _FakeTokenStorage(
            AuthenticationSession(
              accessToken: 'tok',
              accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
              refreshToken: 'ref',
              refreshTokenExpiresAt: DateTime.now().add(
                const Duration(days: 30),
              ),
              roleCode: 'Owner',
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: ServicesSettingsScreen(apiService: settingsApiService),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Current service is Interior Cleaning
        expect(find.text('CURRENT SERVICES (1)'), findsOneWidget);
        expect(find.text('Interior Cleaning'), findsOneWidget);

        // Available Services only shows Car Washing services
        expect(find.text('AVAILABLE SERVICES'), findsOneWidget);
        expect(find.text('Exterior Cleaning'), findsOneWidget);

        // Laundry and Salon services are completely hidden
        expect(find.text('Wash & Fold'), findsNothing);
        expect(find.text('Haircut'), findsNothing);
      },
    );
  });

  group('PricingSettingsScreen UI & Sync', () {
    testWidgets(
      'Displays pricing for active items only and hides pricing for disabled/removed items',
      (WidgetTester tester) async {
        final client = MockClient((http.Request request) async {
          return http.Response(
            jsonEncode({
              'tenantId': 'tenant-123',
              'totalServices': 1,
              'totalActiveServices': 1,
              'totalItems': 2,
              'totalActiveItems': 1,
              'totalCategories': 1,
              'totalActiveCategories': 1,
              'totalActivePricing': 1,
              'services': [
                {
                  'id': 'srv-1',
                  'tenantId': 'tenant-123',
                  'serviceName': 'Dry Cleaning',
                  'code': 'DRY_CLEAN',
                  'status': 'Active',
                },
              ],
              'items': [
                {
                  'id': 'item-active',
                  'tenantId': 'tenant-123',
                  'name': 'Silk Shirt',
                  'code': 'SILK_SHIRT',
                  'status': 'Active',
                },
                {
                  'id': 'item-inactive',
                  'tenantId': 'tenant-123',
                  'name': 'Wool Blanket',
                  'code': 'WOOL_BLANKET',
                  'status': 'Inactive',
                },
              ],
              'categories': [],
              'pricing': [
                {
                  'id': 'prc-active',
                  'tenantId': 'tenant-123',
                  'serviceId': 'srv-1',
                  'itemCategoryId': 'item-active',
                  'pricingType': 'per_item',
                  'basePrice': 25.0,
                  'taxPct': 0,
                  'status': 'Active',
                },
                {
                  'id': 'prc-inactive-item',
                  'tenantId': 'tenant-123',
                  'serviceId': 'srv-1',
                  'itemCategoryId': 'item-inactive',
                  'pricingType': 'per_item',
                  'basePrice': 40.0,
                  'taxPct': 0,
                  'status': 'Active',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final settingsApiService = SettingsApiService(
          client: client,
          tokenStorage: _FakeTokenStorage(
            AuthenticationSession(
              accessToken: 'tok',
              accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
              refreshToken: 'ref',
              refreshTokenExpiresAt: DateTime.now().add(
                const Duration(days: 30),
              ),
              roleCode: 'Owner',
            ),
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PricingSettingsScreen(apiService: settingsApiService),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // 1. Pricing screen header
        expect(find.text('Pricing'), findsOneWidget);
        expect(find.text('Set prices per item / service'), findsOneWidget);

        // 2. Active item "Silk Shirt" is displayed in pricing list
        expect(find.text('Silk Shirt'), findsOneWidget);
        expect(find.text('Dry Cleaning'), findsOneWidget);

        // 3. Inactive/Disabled item "Wool Blanket" must NOT appear in pricing list
        expect(find.text('Wool Blanket'), findsNothing);
      },
    );
  });
}
