import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/screens/orders_screen.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';

void main() {
  test(
    'formats receipt totals with the existing Indian currency convention',
    () {
      expect(formatOrderMoney(850), 'Rs. 850');
      expect(formatOrderMoney(2200), 'Rs. 2,200');
      expect(formatOrderMoney(1234567.5), 'Rs. 12,34,567.50');
    },
  );

  testWidgets('uses readable design-system styling for the selected filter', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: OrderFilterBar(
            selected: OrderListFilter.all,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final ChoiceChip selectedChip = tester.widget<ChoiceChip>(
      find.byType(ChoiceChip).first,
    );
    expect(selectedChip.labelStyle?.color, AppColors.textPrimary);
    expect(selectedChip.selectedColor, AppColors.primaryMuted);
    expect(selectedChip.side, AppBorders.chipActiveSide);
  });

  test(
    'uses the authenticated v1 Order API contract and backend queries',
    () async {
      final List<http.Request> requests = <http.Request>[];
      final OrderApiService service = OrderApiService(
        tokenStorage: _MemoryTokenStorage(),
        baseUrl: 'http://orders.test/api',
        client: MockClient((http.Request request) async {
          requests.add(request);
          if (request.url.path.endsWith('/order-1/history')) {
            return http.Response(
              jsonEncode(<String, Object>{
                'data': <Object>[_historyJson()],
              }),
              200,
            );
          }
          if (request.method == 'PATCH' &&
              request.url.path.endsWith('/order-1/status')) {
            return http.Response(
              jsonEncode(<String, Object>{
                'data': _orderJson(status: 'Delivered'),
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/order-1')) {
            return http.Response(
              jsonEncode(<String, Object>{'data': _orderJson()}),
              200,
            );
          }
          return http.Response(
            jsonEncode(<String, Object>{
              'data': <String, Object>{
                'items': <Object>[_orderJson()],
                'total': 1,
                'page': 1,
                'limit': 20,
                'totalPages': 1,
              },
            }),
            200,
          );
        }),
      )..selectBranch('branch-a');

      final OrderPage page = await service.list(
        search: 'Hassan',
        status: OrderStatus.inProgress,
      );
      final Order details = await service.getById('order-1');
      final List<OrderStatusHistory> history = await service.getHistory(
        'order-1',
      );
      final Order delivered = await service.changeStatus(
        'order-1',
        OrderStatus.delivered,
      );

      expect(page.items.single.orderNumber, 'ORD-MAIN-000123');
      expect(details.id, 'order-1');
      expect(history.single.newStatus, OrderStatus.ready);
      expect(delivered.status, OrderStatus.delivered);
      expect(requests.first.url.path, '/api/v1/orders/');
      expect(requests.first.url.queryParameters['search'], 'Hassan');
      expect(requests.first.url.queryParameters['status'], 'InProgress');
      expect(requests.first.url.queryParameters['sortBy'], 'createdAt');
      expect(requests.first.headers['authorization'], 'Bearer order-token');
      expect(requests.first.headers['x-branch-id'], 'branch-a');
      expect(requests[2].url.path, '/api/v1/orders/order-1/history');
      expect(requests.last.url.path, '/api/v1/orders/order-1/status');
      expect(requests.last.method, 'PATCH');
      expect(jsonDecode(requests.last.body), <String, Object>{
        'status': 'Delivered',
      });
    },
  );

  testWidgets('renders, searches, filters, paginates and opens real details', (
    WidgetTester tester,
  ) async {
    final List<Uri> requests = <Uri>[];
    final OrderController controller = _controller((
      http.Request request,
    ) async {
      requests.add(request.url);
      if (request.url.path.endsWith('/order-1/history')) {
        return http.Response(jsonEncode(<Object>[_historyJson()]), 200);
      }
      if (request.url.path.endsWith('/order-1')) {
        return http.Response(jsonEncode(_orderJson()), 200);
      }
      final int page = int.parse(request.url.queryParameters['page'] ?? '1');
      return http.Response(
        jsonEncode(<String, Object>{
          'items': <Object>[_orderJson(id: 'order-$page')],
          'total': 2,
          'page': page,
          'limit': 20,
          'totalPages': 2,
        }),
        200,
      );
    });

    await tester.pumpWidget(_app(OrdersScreen(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Hassan Ali'), findsOneWidget);
    expect(
      find.text('ORD-123 · Shirt · Dry cleaning 3'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), '03001234567');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(
      requests.any((Uri uri) => uri.queryParameters['search'] == '03001234567'),
      isTrue,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Ready'));
    await tester.pumpAndSettle();
    expect(
      requests.any((Uri uri) => uri.queryParameters['status'] == 'Ready'),
      isTrue,
    );

    await controller.loadMore();
    expect(
      requests.any((Uri uri) => uri.queryParameters['page'] == '2'),
      isTrue,
    );

    await tester.tap(find.text('Hassan Ali').first);
    await tester.pumpAndSettle();
    expect(find.text('Order Detail'), findsOneWidget);
    expect(find.text('ORD-MAIN-000123'), findsOneWidget);
    expect(
      requests.any((Uri uri) => uri.path == '/api/v1/orders/order-1/history'),
      isTrue,
    );
  });

  testWidgets('shows backend empty and error states with retry', (
    WidgetTester tester,
  ) async {
    final OrderController empty = _controller(
      (_) async => http.Response(
        jsonEncode(<String, Object>{
          'items': <Object>[],
          'total': 0,
          'page': 1,
          'limit': 20,
          'totalPages': 0,
        }),
        200,
      ),
    );
    await tester.pumpWidget(_app(OrdersScreen(controller: empty)));
    await tester.pumpAndSettle();
    expect(find.text('No orders yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    final OrderController error = _controller(
      (_) async => http.Response(
        jsonEncode(<String, String>{'message': 'Order database unavailable'}),
        500,
      ),
    );
    await tester.pumpWidget(_app(OrdersScreen(controller: error)));
    await tester.pumpAndSettle();
    expect(find.text('Order database unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

OrderController _controller(
  Future<http.Response> Function(http.Request request) handler,
) => OrderController(
  service: OrderApiService(
    tokenStorage: _MemoryTokenStorage(),
    baseUrl: 'http://orders.test/api/v1',
    client: MockClient(handler),
  )..selectBranch('branch-a'),
);

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

Map<String, Object?> _orderJson({
  String id = 'order-1',
  String status = 'Ready',
}) => <String, Object?>{
  'id': id,
  'tenantId': 'tenant-1',
  'branchId': 'branch-a',
  'orderNumber': 'ORD-MAIN-000123',
  'customerId': 'customer-1',
  'customerSnapshot': <String, Object>{
    'customerId': 'customer-1',
    'name': 'Hassan Ali',
  'mobile': '9876543210',
    'customerType': 'Regular',
  },
  'status': status,
  'paymentStatus': 'PartiallyPaid',
  'items': <Object>[
    <String, Object>{
      'id': 'item-1',
      'itemCategoryId': 'category-1',
      'itemCategorySnapshot': <String, Object>{'name': 'Shirt'},
      'serviceId': 'service-1',
      'serviceSnapshot': <String, Object>{'name': 'Dry cleaning'},
      'quantity': 3,
      'unitPrice': 100,
      'discount': 0,
      'tax': 0,
      'lineTotal': 300,
    },
  ],
  'subtotal': 300,
  'discount': 0,
  'tax': 0,
  'grandTotal': 300,
  'paidAmount': 100,
  'outstandingAmount': 200,
  'createdAt': '2026-08-14T09:15:00.000Z',
  'updatedAt': '2026-08-14T09:15:00.000Z',
  'version': 1,
};

Map<String, Object> _historyJson() => <String, Object>{
  'id': 'history-1',
  'orderId': 'order-1',
  'previousStatus': 'InProgress',
  'newStatus': 'Ready',
  'changedBy': 'worker-1',
  'note': 'Completed and packaged',
  'timestamp': '2026-08-14T11:20:00.000Z',
};

final class _MemoryTokenStorage implements AuthTokenStorage {
  AuthenticationSession? _session = AuthenticationSession(
    accessToken: 'order-token',
    refreshToken: 'refresh-token',
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
