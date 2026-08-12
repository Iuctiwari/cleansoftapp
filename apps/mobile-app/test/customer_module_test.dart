import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_list_screen.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';

void main() {
  testWidgets(
    'customer list covers loading, statistics, search, pagination and navigation',
    (WidgetTester tester) async {
      final Completer<void> release = Completer<void>();
      final List<Uri> requests = <Uri>[];
      final CustomerController controller = _controller((
        http.Request request,
      ) async {
        requests.add(request.url);
        await release.future;
        if (request.url.path.endsWith('/statistics')) return _statistics();
        if (request.url.path.endsWith('/customer-1'))
          return _customerResponse();
        final int page = int.parse(request.url.queryParameters['page'] ?? '1');
        final String search = request.url.queryParameters['search'] ?? '';
        return _page(
          items: search == 'missing' ? <Object>[] : <Object>[_customerJson()],
          page: page,
          total: page == 1 ? 2 : 2,
        );
      });

      await tester.pumpWidget(_app(CustomerListScreen(controller: controller)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      release.complete();
      await tester.pumpAndSettle();

      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('Hassan Ali'), findsOneWidget);
      expect(find.text('Rs. 650'), findsWidgets);
    expect(find.text('7'), findsNWidgets(2));

      await tester.enterText(find.byType(TextField).first, 'missing');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('No customers found'), findsOneWidget);
      expect(
        requests.any((Uri uri) => uri.queryParameters['search'] == 'missing'),
        isTrue,
      );

      await controller.load(search: '');
      await controller.loadMore();
      expect(
        requests.any((Uri uri) => uri.queryParameters['page'] == '2'),
        isTrue,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hassan Ali').first);
      await tester.pumpAndSettle();
      expect(find.text('Customer Profile'), findsOneWidget);
    },
  );

  testWidgets('add form validates and creates a customer', (
    WidgetTester tester,
  ) async {
    var created = false;
    final CustomerController controller = _controller((
      http.Request request,
    ) async {
      if (request.url.path.endsWith('/statistics'))
        return _statistics(total: created ? 1 : 0);
      if (request.method == 'POST') {
        created = true;
        return _customerResponse(status: 201);
      }
      return _page(items: created ? <Object>[_customerJson()] : <Object>[]);
    });
    await tester.pumpWidget(_app(CustomerListScreen(controller: controller)));
    await tester.pumpAndSettle();
    expect(find.text('No customers yet'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Customer'));
    await tester.pump();
    expect(find.text('Customer name is required'), findsOneWidget);
    expect(find.text('Mobile number is required'), findsOneWidget);

    final List<Finder> fields = List<Finder>.generate(
      4,
      (int index) => find.byType(TextFormField).at(index),
    );
    await tester.enterText(fields[0], 'Hassan Ali');
    await tester.enterText(fields[1], '+923001234567');
    await tester.tap(find.text('Create Customer'));
    await tester.pumpAndSettle();
    expect(created, isTrue);
    expect(find.text('Hassan Ali'), findsOneWidget);
  });

  testWidgets('customer list exposes empty and error states', (
    WidgetTester tester,
  ) async {
    final CustomerController emptyController = _controller((
      http.Request request,
    ) async {
      if (request.url.path.endsWith('/statistics'))
        return _statistics(total: 0);
      return _page(items: <Object>[]);
    });
    await tester.pumpWidget(
      _app(CustomerListScreen(controller: emptyController)),
    );
    await tester.pumpAndSettle();
    expect(find.text('No customers yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final CustomerController errorController = _controller(
      (_) async => http.Response(
        jsonEncode(<String, String>{'message': 'Server unavailable'}),
        500,
      ),
    );
    await tester.pumpWidget(
      _app(CustomerListScreen(controller: errorController)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load customers'), findsOneWidget);
    expect(find.text('Server unavailable'), findsOneWidget);
  });

  testWidgets('edit clears optional fields and delete requires confirmation', (
    WidgetTester tester,
  ) async {
    Map<String, dynamic>? patchBody;
    var deleted = false;
    final CustomerController controller = _controller((
      http.Request request,
    ) async {
      if (request.url.path.endsWith('/statistics'))
        return _statistics(total: 1);
      if (request.url.path.endsWith('/customer-1')) {
        if (request.method == 'PATCH') {
          patchBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _customerResponse();
        }
        if (request.method == 'DELETE') {
          deleted = true;
          return http.Response('', 204);
        }
        return _customerResponse();
      }
      return _page(items: <Object>[_customerJson()], total: 1);
    });
    await tester.pumpWidget(_app(CustomerListScreen(controller: controller)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hassan Ali'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.edit));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '');
    await tester.enterText(find.byType(TextFormField).at(3), '');
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(patchBody?['email'], isNull);
    expect(patchBody?['address'], isNull);

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete customer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Are you sure you want to delete this customer?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(find.text('Customers'), findsOneWidget);
  });
}

CustomerController _controller(
  Future<http.Response> Function(http.Request request) handler,
) => CustomerController(
  service: CustomerApiService(
    tokenStorage: _MemoryTokenStorage(),
    baseUrl: 'http://customer.test',
    client: MockClient(handler),
  )..selectBranch('branch-a'),
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

http.Response _statistics({int total = 7}) => http.Response(
  jsonEncode(<String, Object>{
    'total': total,
    'active': total,
    'outstanding': 650,
  }),
  200,
);

http.Response _page({
  List<Object> items = const <Object>[],
  int page = 1,
  int total = 0,
}) => http.Response(
  jsonEncode(<String, Object>{
    'items': items,
    'total': total,
    'page': page,
    'limit': 20,
  }),
  200,
);

http.Response _customerResponse({int status = 200}) =>
    http.Response(jsonEncode(_customerJson()), status);

Map<String, Object?> _customerJson() => <String, Object?>{
  'id': 'customer-1',
  'tenantId': 'tenant-1',
  'branchId': 'branch-a',
  'name': 'Hassan Ali',
  'mobile': '+923001234567',
  'email': 'hassan@example.com',
  'address': 'Karachi',
  'customerType': 'Regular',
  'joiningDate': '2026-08-12T00:00:00.000Z',
  'totalOrders': 12,
  'totalSpent': 9200,
  'outstandingBalance': 650,
  'lastOrderDate': null,
  'createdAt': '2026-08-12T00:00:00.000Z',
  'updatedAt': '2026-08-12T00:00:00.000Z',
};

final class _MemoryTokenStorage implements AuthTokenStorage {
  AuthenticationSession? _session = AuthenticationSession(
    accessToken: 'token',
    refreshToken: 'refresh',
    accessTokenExpiresAt: DateTime.utc(2027),
    refreshTokenExpiresAt: DateTime.utc(2028),
  );

  @override
  Future<void> clear() async => _session = null;

  @override
  Future<AuthenticationSession?> read() async => _session;

  @override
  Future<void> write(AuthenticationSession session) async => _session = session;
}
