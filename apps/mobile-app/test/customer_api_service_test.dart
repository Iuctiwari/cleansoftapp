import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';

void main() {
  late _MemoryTokenStorage tokenStorage;

  setUp(() {
    tokenStorage = _MemoryTokenStorage(
      AuthenticationSession(
        accessToken: 'customer-token',
        refreshToken: 'refresh-token',
        accessTokenExpiresAt: DateTime.utc(2027),
        refreshTokenExpiresAt: DateTime.utc(2028),
      ),
    );
  });

  test('lists a searched customer page using the authenticated API', () async {
    final service = CustomerApiService(
      tokenStorage: tokenStorage,
      baseUrl: 'http://customer.test',
      client: MockClient((http.Request request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/customers/');
        expect(request.url.queryParameters, <String, String>{
          'page': '2',
          'limit': '20',
          'search': 'Ali',
        });
        expect(request.headers['authorization'], 'Bearer customer-token');
        return http.Response(
          jsonEncode(<String, Object>{
            'items': <Object>[_customerJson()],
            'total': 21,
            'page': 2,
            'limit': 20,
          }),
          200,
        );
      }),
    );

    final CustomerPage result = await service.list(page: 2, search: ' Ali ');

    expect(result.total, 21);
    expect(result.items.single.name, 'Hassan Ali');
  });

  test(
    'creates, updates, fetches and deletes customers with expected methods',
    () async {
      final List<String> methods = <String>[];
      final service = CustomerApiService(
        tokenStorage: tokenStorage,
        baseUrl: 'http://customer.test',
        client: MockClient((http.Request request) async {
          methods.add(request.method);
          expect(request.headers['authorization'], 'Bearer customer-token');
          if (request.method == 'DELETE') return http.Response('', 204);
          if (request.method == 'POST' || request.method == 'PATCH') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body.containsKey('tenantId'), isFalse);
            expect(body.containsKey('totalOrders'), isFalse);
            if (request.method == 'PATCH') {
              expect(body['email'], isNull);
              expect(body['address'], isNull);
            }
          }
          return http.Response(jsonEncode(_customerJson()), 200);
        }),
      );
      const draft = CustomerDraft(
        name: 'Hassan Ali',
        mobile: '+923001234567',
        customerType: CustomerType.regular,
      );

      await service.create(draft);
      await service.getById('customer-1');
      await service.update('customer-1', draft);
      await service.delete('customer-1');

      expect(methods, <String>['POST', 'GET', 'PATCH', 'DELETE']);
    },
  );

  test(
    'loads branch-wide statistics and sends selected branch securely',
    () async {
      final service = CustomerApiService(
        tokenStorage: tokenStorage,
        baseUrl: 'http://customer.test',
        client: MockClient((http.Request request) async {
          expect(request.url.path, '/customers/statistics');
          expect(request.headers['x-branch-id'], 'branch-b');
          return http.Response(
            jsonEncode(<String, Object>{
              'total': 40,
              'active': 38,
              'outstanding': 12500,
            }),
            200,
          );
        }),
      )..selectBranch('branch-b');

      final CustomerStatistics result = await service.statistics();

      expect(result.total, 40);
      expect(result.active, 38);
      expect(result.outstanding, 12500);
    },
  );

  test('branch switching reloads the selected branch', () async {
    final List<String?> branches = <String?>[];
    final service = CustomerApiService(
      tokenStorage: tokenStorage,
      baseUrl: 'http://customer.test',
      client: MockClient((http.Request request) async {
        branches.add(request.headers['x-branch-id']);
        if (request.url.path.endsWith('/statistics')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'total': 0,
              'active': 0,
              'outstanding': 0,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode(<String, Object>{
            'items': <Object>[],
            'total': 0,
            'page': 1,
            'limit': 20,
          }),
          200,
        );
      }),
    );
    final orderService = OrderApiService(
      tokenStorage: tokenStorage,
      baseUrl: 'http://order.test/api',
      client: MockClient(
        (http.Request request) async => http.Response(
          jsonEncode(<String, Object>{
            'items': <Object>[],
            'total': 0,
            'page': 1,
            'limit': 1,
            'totalPages': 1,
          }),
          200,
        ),
      ),
    );
    final controller = CustomerController(
      service: service,
      orderService: orderService,
    );

    await controller.selectBranch('branch-a');
    await controller.selectBranch('branch-b');

    expect(branches, <String?>['branch-a', 'branch-a', 'branch-b', 'branch-b']);
  });
}

Map<String, Object?> _customerJson() => <String, Object?>{
  'id': 'customer-1',
  'tenantId': 'tenant-1',
  'branchId': 'branch-1',
  'name': 'Hassan Ali',
  'mobile': '+923001234567',
  'customerType': 'Regular',
  'joiningDate': '2026-08-12T00:00:00.000Z',
  'totalOrders': 0,
  'totalSpent': 0,
  'outstandingBalance': 0,
  'lastOrderDate': null,
  'createdAt': '2026-08-12T00:00:00.000Z',
  'updatedAt': '2026-08-12T00:00:00.000Z',
};

final class _MemoryTokenStorage implements AuthTokenStorage {
  _MemoryTokenStorage(this.session);

  AuthenticationSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<AuthenticationSession?> read() async => session;

  @override
  Future<void> write(AuthenticationSession value) async => session = value;
}
