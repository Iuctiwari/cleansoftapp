import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/settings/settings.dart';

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

  late AuthenticationSession session;
  late _FakeTokenStorage tokenStorage;

  setUp(() {
    session = AuthenticationSession(
      accessToken: 'test-token',
      accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
      refreshToken: 'test-refresh',
      refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
      roleCode: 'Owner',
      tenantId: 'tenant-123',
      branchId: 'branch-123',
    );
    tokenStorage = _FakeTokenStorage(session);
  });

  group('ItemsSettingsScreen', () {
    testWidgets(
      'Renders Catalog Items, search, available items, and custom item creator',
      (WidgetTester tester) async {
        final summaryResponse = {
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
              'pricingType': 'per_item',
              'status': 'Active',
            },
          ],
          'items': [
            {
              'id': 'item-1',
              'tenantId': 'tenant-123',
              'name': 'Shirt',
              'code': 'SHIRT',
              'unitType': 'piece',
              'category': 'Laundry',
              'status': 'Active',
            },
            {
              'id': 'item-2',
              'tenantId': 'tenant-123',
              'name': 'Curtain (pair)',
              'code': 'CURTAIN',
              'unitType': 'pair',
              'category': 'Curtain',
              'status': 'Inactive',
            },
          ],
          'categories': [
            {
              'id': 'cat-1',
              'tenantId': 'tenant-123',
              'name': 'Laundry',
              'code': 'LAUNDRY',
              'status': 'Active',
            },
          ],
          'pricing': [
            {
              'id': 'prc-1',
              'tenantId': 'tenant-123',
              'serviceId': 'srv-1',
              'itemCategoryId': 'item-1',
              'pricingType': 'per_item',
              'basePrice': 25.0,
              'taxPct': 0.0,
              'status': 'Active',
            },
          ],
        };

        final client = MockClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/settings-services')) {
            return http.Response(
              jsonEncode(summaryResponse),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'PATCH' &&
              request.url.path.contains('/items/')) {
            return http.Response(
              jsonEncode({
                'id': 'item-1',
                'tenantId': 'tenant-123',
                'name': 'Shirt',
                'code': 'SHIRT',
                'unitType': 'piece',
                'status': 'Inactive',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'POST' && request.url.path.endsWith('/items')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'id': 'item-custom',
                'tenantId': 'tenant-123',
                'name': body['name'],
                'code': body['code'],
                'unitType': body['unitType'] ?? 'piece',
                'category': body['category'] ?? 'Laundry',
                'status': 'Active',
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        });

        final apiService = SettingsApiService(
          client: client,
          tokenStorage: tokenStorage,
        );

        await tester.pumpWidget(
          MaterialApp(home: ItemsSettingsScreen(apiService: apiService)),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Verify Header
        expect(find.text('Items / Catalog'), findsOneWidget);
        expect(find.text('Manage your item catalog'), findsOneWidget);

        // Verify Search
        expect(find.text('Search items...'), findsOneWidget);

        // Verify Section: CATALOG ITEMS (1)
        expect(find.text('CATALOG ITEMS (1)'), findsOneWidget);
        expect(find.text('Shirt'), findsOneWidget);
        expect(find.text('Dry Cleaning'), findsWidgets);

        // Verify Section: AVAILABLE TO ADD
        expect(find.text('AVAILABLE TO ADD'), findsOneWidget);
        expect(find.text('Curtain (pair)'), findsOneWidget);

        // Verify Section: ADD CUSTOM ITEM
        expect(find.text('ADD CUSTOM ITEM'), findsOneWidget);
        expect(find.text('Save Catalog'), findsOneWidget);

        // Remove item
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();

        // Add custom item
        await tester.enterText(
          find.widgetWithText(TextField, 'Item name...'),
          'Silk Tie',
        );
        await tester.tap(find.text('Add'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Silk Tie'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders multi-service item with all services comma-separated on a single card without duplicate cards',
      (WidgetTester tester) async {
        final summaryResponse = {
          'tenantId': 'tenant-123',
          'totalServices': 3,
          'totalActiveServices': 3,
          'totalItems': 1,
          'totalActiveItems': 1,
          'totalCategories': 0,
          'totalActiveCategories': 0,
          'totalActivePricing': 3,
          'services': [
            {
              'id': 'srv-1',
              'tenantId': 'tenant-123',
              'serviceName': 'Dry Cleaning',
              'code': 'SERVICE_DRY_CLEANING',
              'pricingType': 'per_item',
              'status': 'Active',
            },
            {
              'id': 'srv-2',
              'tenantId': 'tenant-123',
              'serviceName': 'Wash & Fold',
              'code': 'SERVICE_WASH_FOLD',
              'pricingType': 'per_item',
              'status': 'Active',
            },
            {
              'id': 'srv-3',
              'tenantId': 'tenant-123',
              'serviceName': 'Ironing',
              'code': 'SERVICE_IRONING',
              'pricingType': 'per_item',
              'status': 'Active',
            },
          ],
          'items': [
            {
              'id': 'item-1',
              'tenantId': 'tenant-123',
              'name': 'Shirt',
              'code': 'ITEM_SHIRT',
              'unitType': 'piece',
              'status': 'Active',
              'serviceIds': ['srv-1', 'srv-2', 'srv-3'],
            },
          ],
          'categories': [],
          'pricing': [
            {
              'id': 'prc-1',
              'tenantId': 'tenant-123',
              'serviceId': 'srv-1',
              'itemCategoryId': 'item-1',
              'serviceName': 'Dry Cleaning',
              'itemName': 'Shirt',
              'basePrice': 100,
              'status': 'Active',
            },
            {
              'id': 'prc-2',
              'tenantId': 'tenant-123',
              'serviceId': 'srv-2',
              'itemCategoryId': 'item-1',
              'serviceName': 'Wash & Fold',
              'itemName': 'Shirt',
              'basePrice': 50,
              'status': 'Active',
            },
            {
              'id': 'prc-3',
              'tenantId': 'tenant-123',
              'serviceId': 'srv-3',
              'itemCategoryId': 'item-1',
              'serviceName': 'Ironing',
              'itemName': 'Shirt',
              'basePrice': 20,
              'status': 'Active',
            },
          ],
        };

        final client = MockClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/settings-services')) {
            return http.Response(
              jsonEncode(summaryResponse),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        });

        final apiService = SettingsApiService(
          client: client,
          tokenStorage: tokenStorage,
        );

        await tester.pumpWidget(
          MaterialApp(home: ItemsSettingsScreen(apiService: apiService)),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Exactly one item card for "Shirt"
        expect(find.text('CATALOG ITEMS (1)'), findsOneWidget);
        expect(find.text('Shirt'), findsOneWidget);

        // Associated services rendered together separated by commas
        expect(find.text('Dry Cleaning, Wash & Fold, Ironing'), findsOneWidget);
      },
    );
  });

  group('ServicesSettingsScreen', () {
    testWidgets(
      'Renders Current Services, Available Services, and Custom Service creator',
      (WidgetTester tester) async {
        final summaryResponse = {
          'tenantId': 'tenant-123',
          'totalServices': 2,
          'totalActiveServices': 1,
          'totalItems': 0,
          'totalActiveItems': 0,
          'totalCategories': 0,
          'totalActiveCategories': 0,
          'totalActivePricing': 0,
          'services': [
            {
              'id': 'srv-1',
              'tenantId': 'tenant-123',
              'serviceName': 'Dry Cleaning',
              'code': 'DRY_CLEAN',
              'pricingType': 'per_item',
              'status': 'Active',
            },
            {
              'id': 'srv-2',
              'tenantId': 'tenant-123',
              'serviceName': 'Wash & Fold',
              'code': 'WASH_FOLD',
              'pricingType': 'per_kg',
              'status': 'Inactive',
            },
          ],
          'items': [],
          'categories': [],
          'pricing': [],
        };

        final client = MockClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/settings-services')) {
            return http.Response(
              jsonEncode(summaryResponse),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        });

        final apiService = SettingsApiService(
          client: client,
          tokenStorage: tokenStorage,
        );

        await tester.pumpWidget(
          MaterialApp(home: ServicesSettingsScreen(apiService: apiService)),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        // Header
        expect(find.text('Services'), findsOneWidget);
        expect(find.text('CURRENT SERVICES (1)'), findsOneWidget);
        expect(find.text('Dry Cleaning'), findsOneWidget);
        expect(find.text('AVAILABLE SERVICES'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('ADD CUSTOM SERVICE'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('ADD CUSTOM SERVICE'), findsOneWidget);
        expect(find.text('Save Services'), findsOneWidget);
      },
    );
  });

  group('PricingSettingsScreen', () {
    testWidgets(
      'Renders Pricing entries with price fields and allows editing',
      (WidgetTester tester) async {
        final summaryResponse = {
          'tenantId': 'tenant-123',
          'totalServices': 1,
          'totalActiveServices': 1,
          'totalItems': 1,
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
              'pricingType': 'per_item',
              'status': 'Active',
            },
          ],
          'items': [
            {
              'id': 'item-1',
              'tenantId': 'tenant-123',
              'name': 'Shirt',
              'code': 'SHIRT',
              'unitType': 'piece',
              'category': 'Laundry',
              'status': 'Active',
            },
          ],
          'categories': [],
          'pricing': [
            {
              'id': 'prc-1',
              'tenantId': 'tenant-123',
              'serviceId': 'srv-1',
              'itemCategoryId': 'item-1',
              'pricingType': 'per_item',
              'basePrice': 25.0,
              'taxPct': 0.0,
              'status': 'Active',
            },
          ],
        };

        final client = MockClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.endsWith('/settings-services')) {
            return http.Response(
              jsonEncode(summaryResponse),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'PATCH' &&
              request.url.path.contains('/pricing/')) {
            return http.Response(
              jsonEncode({
                'id': 'prc-1',
                'tenantId': 'tenant-123',
                'serviceId': 'srv-1',
                'itemCategoryId': 'item-1',
                'pricingType': 'per_item',
                'basePrice': 30.0,
                'taxPct': 0.0,
                'status': 'Active',
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        });

        final apiService = SettingsApiService(
          client: client,
          tokenStorage: tokenStorage,
        );

        await tester.pumpWidget(
          MaterialApp(home: PricingSettingsScreen(apiService: apiService)),
        );

        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text('Pricing'), findsOneWidget);
        expect(find.text('PRICING ENTRIES (1)'), findsOneWidget);
        expect(find.text('Shirt'), findsOneWidget);
        expect(find.text('Dry Cleaning'), findsOneWidget);
        expect(find.text('Save Pricing'), findsOneWidget);

        // Edit price
        await tester.enterText(find.byType(TextField).last, '30');
        await tester.tap(find.text('Save Pricing'));
        await tester.pump();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('Groups pricing entries by active services correctly', (
      WidgetTester tester,
    ) async {
      final summaryResponse = {
        'tenantId': 'tenant-123',
        'totalServices': 2,
        'totalActiveServices': 2,
        'totalItems': 2,
        'totalActiveItems': 2,
        'totalCategories': 0,
        'totalActiveCategories': 0,
        'totalActivePricing': 3,
        'services': [
          {
            'id': 'srv-1',
            'tenantId': 'tenant-123',
            'serviceName': 'Dry Cleaning',
            'code': 'DRY_CLEAN',
            'pricingType': 'per_item',
            'status': 'Active',
          },
          {
            'id': 'srv-2',
            'tenantId': 'tenant-123',
            'serviceName': 'Wash & Fold',
            'code': 'WASH_FOLD',
            'pricingType': 'per_item',
            'status': 'Active',
          },
        ],
        'items': [
          {
            'id': 'item-1',
            'tenantId': 'tenant-123',
            'name': 'Shirt',
            'code': 'SHIRT',
            'unitType': 'Piece',
            'status': 'Active',
          },
          {
            'id': 'item-2',
            'tenantId': 'tenant-123',
            'name': 'Trouser',
            'code': 'TROUSER',
            'unitType': 'Piece',
            'status': 'Active',
          },
        ],
        'categories': [],
        'pricing': [
          {
            'id': 'prc-1',
            'tenantId': 'tenant-123',
            'serviceId': 'srv-1',
            'itemCategoryId': 'item-1',
            'pricingType': 'per_item',
            'basePrice': 25.0,
            'status': 'Active',
          },
          {
            'id': 'prc-2',
            'tenantId': 'tenant-123',
            'serviceId': 'srv-1',
            'itemCategoryId': 'item-2',
            'pricingType': 'per_item',
            'basePrice': 35.0,
            'status': 'Active',
          },
          {
            'id': 'prc-3',
            'tenantId': 'tenant-123',
            'serviceId': 'srv-2',
            'itemCategoryId': 'item-1',
            'pricingType': 'per_item',
            'basePrice': 15.0,
            'status': 'Active',
          },
        ],
      };

      final client = MockClient((http.Request request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/settings-services')) {
          return http.Response(
            jsonEncode(summaryResponse),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final apiService = SettingsApiService(
        client: client,
        tokenStorage: tokenStorage,
      );

      await tester.pumpWidget(
        MaterialApp(home: PricingSettingsScreen(apiService: apiService)),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('PRICING ENTRIES (3)'), findsOneWidget);
      expect(find.text('Dry Cleaning'), findsOneWidget);
      expect(find.text('Wash & Fold'), findsOneWidget);
      expect(find.text('Shirt'), findsNWidgets(2));
      expect(find.text('Trouser'), findsOneWidget);
    });
  });
}
