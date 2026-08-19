import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/orders/controllers/new_order_controller.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order_catalog.dart';
import 'package:nexoraa_mobile/features/orders/screens/new_order_screen.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/order_catalog_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';
import 'package:nexoraa_mobile/features/orders/widgets/new_order_widgets.dart';

const String _categoryId = '64f0c18f7c4d2f0012ab340';
const String _serviceId = '64f0c18f7c4d2f0012ab341';
const String _secondServiceId = '64f0c18f7c4d2f0012ab347';
const String _customerId = '64f0c18f7c4d2f0012ab342';
const String _orderId = '64f0c18f7c4d2f0012ab343';

void main() {
  test(
    'groups unsorted catalog items deterministically without changing selections or IDs',
    () async {
      const String hairCategoryId = '64f0c18f7c4d2f0012ab350';
      const String trouserCategoryId = '64f0c18f7c4d2f0012ab351';
      const String hairServiceId = '64f0c18f7c4d2f0012ab352';
      final Map<String, Object> hair = <String, Object>{
        ..._categoryJson(),
        'id': hairCategoryId,
        'name': 'Hair',
        'code': 'SALON_HAIR',
        'catalogGroupCodes': <String>['SALON'],
        'serviceIds': <String>[hairServiceId],
      };
      final Map<String, Object> trouser = <String, Object>{
        ..._categoryJson(),
        'id': trouserCategoryId,
        'name': 'Trouser',
        'code': 'ITEM_TROUSER',
        'catalogGroupCodes': <String>['LAUNDRY'],
      };
      final Map<String, Object> hairService = <String, Object>{
        ..._serviceJson(serviceId: hairServiceId, name: 'Haircut'),
        'itemCategoryIds': <String>[hairCategoryId],
      };
      final _FlowDependencies dependencies = await _dependencies(
        (_) async => http.Response('{}', 500),
        catalogCategories: <Object>[hair, trouser, _categoryJson()],
        catalogServices: <Object>[
          hairService,
          _serviceJson(),
          _serviceJson(serviceId: _secondServiceId, name: 'Ironing'),
        ],
      );

      await dependencies.newOrder.loadCatalog();

      expect(
        dependencies.newOrder.itemGroups.map((group) => group.label),
        <String>['Laundry', 'Salon'],
      );
      expect(
        dependencies.newOrder.itemGroups.first.items.map((item) => item.name),
        <String>['Shirt', 'Trouser'],
      );
      expect(
        dependencies.newOrder.itemGroups.last.items.single.id,
        hairCategoryId,
      );

      final OrderItemCategory shirt = dependencies.newOrder.categories
          .firstWhere((item) => item.id == _categoryId);
      final OrderItemCategory selectedHair = dependencies.newOrder.categories
          .firstWhere((item) => item.id == hairCategoryId);
      dependencies.newOrder.changeAmount(shirt, 2);
      dependencies.newOrder.changeAmount(selectedHair, 1);

      expect(
        dependencies.newOrder.selections.map(
          (selection) => selection.category.id,
        ),
        <String>[hairCategoryId, _categoryId],
      );
      expect(dependencies.newOrder.selectionFor(_categoryId)?.amount, 2);
      expect(
        dependencies.newOrder.servicesFor(selectedHair).single.id,
        hairServiceId,
      );
    },
  );

  test(
    'catalog client uses tenant branch scoped v1 list and quote contracts',
    () async {
      final List<http.Request> requests = <http.Request>[];
      final OrderCatalogApiService service = OrderCatalogApiService(
        tokenStorage: _MemoryTokenStorage(),
        baseUrl: 'http://catalog.test/api',
        client: MockClient((http.Request request) async {
          requests.add(request);
          if (request.url.path.endsWith('/item-categories')) {
            return _catalogPage(<Object>[_categoryJson()]);
          }
          if (request.url.path.endsWith('/services')) {
            return _catalogPage(<Object>[_serviceJson()]);
          }
          final double quantity = double.parse(
            request.url.queryParameters['quantity'] ?? '1',
          );
          return http.Response(
            jsonEncode(<String, Object>{
              'data': _quoteJson(quantity: quantity),
            }),
            200,
          );
        }),
      )..selectBranch('branch-a');

      final List<OrderItemCategory> categories = await service
          .allItemCategories();
      final List<OrderCatalogService> services = await service.allServices();
      final OrderCatalogQuote quote = await service.quote(
        serviceId: _serviceId,
        itemCategoryId: _categoryId,
        quantity: 2,
      );

      expect(categories.single.serviceIds, <String>[
        _serviceId,
        _secondServiceId,
      ]);
      expect(services.single.itemCategoryIds, <String>[_categoryId]);
      expect(services.single.currentPricing.single.basePrice, 100);
      expect(quote.total, 210);
      expect(requests[0].url.path, '/api/v1/item-categories');
      expect(requests[0].url.queryParameters['status'], 'Active');
      expect(requests[0].url.queryParameters['branchId'], 'branch-a');
      expect(requests[1].url.path, '/api/v1/services');
      expect(requests[2].url.path, '/api/v1/services/$_serviceId/quote');
      expect(requests[2].url.queryParameters['itemCategoryId'], _categoryId);
      expect(requests[2].url.queryParameters['quantity'], '2.0');
      for (final http.Request request in requests) {
        expect(request.headers['authorization'], 'Bearer order-token');
        expect(request.headers['x-branch-id'], 'branch-a');
      }
    },
  );

  testWidgets(
    'completes customer, item, service, pricing, save and receipt flow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, dynamic>? createBody;
      Map<String, dynamic>? paymentBody;
      final _FlowDependencies dependencies = await _dependencies(
        (http.Request request) async {
          if (request.url.path.endsWith('/$_orderId/history')) {
            return http.Response(jsonEncode(<Object>[]), 200);
          }
          if (request.method == 'POST') {
            createBody = jsonDecode(request.body) as Map<String, dynamic>;
          }
          return http.Response(
            jsonEncode(_orderJson()),
            request.method == 'POST' ? 201 : 200,
          );
        },
        paymentHandler: (http.Request request) async {
          paymentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode(<String, Object?>{
              'payment': <String, Object>{'status': 'Successful'},
              'order': _orderJson(
                paidAmount: 25,
                outstandingAmount: 75,
                paymentStatus: 'PartiallyPaid',
              ),
            }),
            201,
          );
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: NewOrderScreen(
            controller: dependencies.newOrder,
            orderController: dependencies.orders,
            customerController: dependencies.customers,
            businessName: 'Database Laundry',
            branchName: 'Main Branch',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NewOrderProgressIndicator), findsOneWidget);
      expect(find.text('1/6'), findsOneWidget);
      expect(find.textContaining('+91 3001234567'), findsOneWidget);
      await tester.tap(find.text('Hassan Ali'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('2/6'), findsOneWidget);
      expect(find.text('Shirt'), findsOneWidget);
      expect(find.text('From Rs. 100 / item'), findsOneWidget);
      await tester.tap(find.byIcon(AppIcons.add));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('3/6'), findsOneWidget);
      await tester.tap(find.text('Wash & Fold'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ironing'));
      await tester.pumpAndSettle();
      expect(find.text('Rs. 110'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('4/6'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '5');
      await tester.pump();
      expect(find.text('Rs. 109.73'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('5/6'), findsOneWidget);
      expect(find.text('Advance Payment (₹)'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '25');
      await tester.tap(find.text('Card'));
      await tester.pump();
      await tester.tap(find.text('Save Order'));
      await tester.pumpAndSettle();

      expect(find.text('6/6'), findsOneWidget);
      expect(find.text('ORD-MAIN-000123'), findsOneWidget);
      expect(find.text('Database Laundry'), findsOneWidget);
      expect(find.text('Rs. 25'), findsWidgets);
      expect(find.widgetWithText(OutlinedButton, 'Print'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'WhatsApp'), findsOneWidget);
      expect(
        tester.getSize(find.widgetWithText(OutlinedButton, 'Print')),
        tester.getSize(find.widgetWithText(OutlinedButton, 'WhatsApp')),
      );
      final Text washReceipt = tester.widget<Text>(
        find.textContaining('Wash & Fold').last,
      );
      final Text ironingReceipt = tester.widget<Text>(
        find.textContaining('Ironing').last,
      );
      expect(washReceipt.maxLines, 1);
      expect(ironingReceipt.maxLines, 1);
      expect(createBody?['customerId'], _customerId);
      expect(createBody?['discountPercentage'], 5.0);
      expect(createBody?['items'], <Object>[
        <String, Object>{
          'itemCategoryId': _categoryId,
          'serviceId': _serviceId,
          'quantity': 1.0,
        },
        <String, Object>{
          'itemCategoryId': _categoryId,
          'serviceId': _secondServiceId,
          'quantity': 1.0,
        },
      ]);
      expect(createBody?.containsKey('grandTotal'), isFalse);
      expect(createBody?.containsKey('subtotal'), isFalse);
      expect(createBody?.containsKey('paidAmount'), isFalse);
      expect(createBody?.containsKey('paymentMethod'), isFalse);
      expect(paymentBody?['amountMinor'], 2500);
      expect(paymentBody?['method'], 'Card');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Order Detail'), findsOneWidget);
      expect(find.text('ORD-MAIN-000123'), findsOneWidget);
    },
  );
}

Future<_FlowDependencies> _dependencies(
  Future<http.Response> Function(http.Request request) orderHandler, {
  Future<http.Response> Function(http.Request request)? paymentHandler,
  List<Object>? catalogCategories,
  List<Object>? catalogServices,
}) async {
  final _MemoryTokenStorage storage = _MemoryTokenStorage();
  final OrderApiService orderApi = OrderApiService(
    tokenStorage: storage,
    baseUrl: 'http://order.test/api',
    client: MockClient(orderHandler),
  )..selectBranch('branch-a');
  final OrderController orders = OrderController(service: orderApi);
  final CustomerController customers = CustomerController(
    service: CustomerApiService(
      tokenStorage: storage,
      baseUrl: 'http://customer.test',
      client: MockClient((http.Request request) async {
        if (request.url.path.endsWith('/statistics')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'total': 1,
              'active': 1,
              'outstanding': 0,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode(<String, Object>{
            'items': <Object>[_customerJson()],
            'total': 1,
            'page': 1,
            'limit': 20,
          }),
          200,
        );
      }),
    ),
    orderService: OrderApiService(
      tokenStorage: storage,
      baseUrl: 'http://order.test/api',
      client: MockClient(orderHandler),
    )..selectBranch('branch-a'),
  );
  await customers.selectBranch('branch-a');
  final OrderCatalogApiService catalog = OrderCatalogApiService(
    tokenStorage: storage,
    baseUrl: 'http://catalog.test/api',
    client: MockClient((http.Request request) async {
      if (request.url.path.endsWith('/item-categories')) {
        return _catalogPage(catalogCategories ?? <Object>[_categoryJson()]);
      }
      if (request.url.path.endsWith('/services')) {
        return _catalogPage(
          catalogServices ??
              <Object>[
                _serviceJson(),
                _serviceJson(serviceId: _secondServiceId, name: 'Ironing'),
              ],
        );
      }
      final String serviceId = request.url.path.contains(_secondServiceId)
          ? _secondServiceId
          : _serviceId;
      return http.Response(jsonEncode(_quoteJson(serviceId: serviceId)), 200);
    }),
  );
  return _FlowDependencies(
    customers: customers,
    orders: orders,
    newOrder: NewOrderController(
      catalogService: catalog,
      orderController: orders,
      paymentService: PaymentApiService(
        tokenStorage: storage,
        baseUrl: 'http://payment.test',
        client: MockClient(
          paymentHandler ?? (_) async => http.Response('{}', 500),
        ),
      ),
      branchId: 'branch-a',
    ),
  );
}

class _FlowDependencies {
  const _FlowDependencies({
    required this.customers,
    required this.orders,
    required this.newOrder,
  });

  final CustomerController customers;
  final OrderController orders;
  final NewOrderController newOrder;
}

http.Response _catalogPage(List<Object> items) => http.Response(
  jsonEncode(<String, Object>{
    'items': items,
    'total': items.length,
    'page': 1,
    'limit': 100,
  }),
  200,
);

Map<String, Object> _categoryJson() => <String, Object>{
  'id': _categoryId,
  'tenantId': '64f0c18f7c4d2f0012ab344',
  'name': 'Shirt',
  'code': 'SHIRT',
  'catalogGroupCodes': <String>['LAUNDRY'],
  'status': 'Active',
  'unitType': 'Piece',
  'branchIds': <String>['branch-a'],
  'serviceIds': <String>[_serviceId, _secondServiceId],
  'createdAt': '2026-08-14T09:15:00.000Z',
  'updatedAt': '2026-08-14T09:15:00.000Z',
  'version': 1,
};

Map<String, Object> _serviceJson({
  String serviceId = _serviceId,
  String name = 'Wash & Fold',
}) => <String, Object>{
  'id': serviceId,
  'tenantId': '64f0c18f7c4d2f0012ab344',
  'serviceName': name,
  'name': name,
  'code': 'WASH_FOLD',
  'status': 'Active',
  'pricingType': 'PerItem',
  'branchIds': <String>['branch-a'],
  'itemCategoryIds': <String>[_categoryId],
  'currentPricing': <Object>[
    <String, Object?>{
      'id': '64f0c18f7c4d2f0012ab346',
      'tenantId': '64f0c18f7c4d2f0012ab344',
      'serviceId': serviceId,
      'itemCategoryId': _categoryId,
      'branchId': 'branch-a',
      'pricingType': 'PerItem',
      'basePrice': 100,
      'taxPct': 5,
      'status': 'Active',
      'effectiveFrom': '2026-08-01T00:00:00.000Z',
      'createdAt': '2026-08-01T00:00:00.000Z',
      'updatedAt': '2026-08-01T00:00:00.000Z',
      'version': 1,
    },
  ],
  'createdAt': '2026-08-14T09:15:00.000Z',
  'updatedAt': '2026-08-14T09:15:00.000Z',
  'version': 1,
};

Map<String, Object> _quoteJson({
  double quantity = 1,
  String serviceId = _serviceId,
}) => <String, Object>{
  'serviceId': serviceId,
  'itemCategoryId': _categoryId,
  'branchId': 'branch-a',
  'serviceMappingId': '64f0c18f7c4d2f0012ab345',
  'servicePricingId': '64f0c18f7c4d2f0012ab346',
  'version': 1,
  'pricingType': 'PerItem',
  'basePrice': 100,
  'unitPrice': 100,
  'taxPct': 5,
  'quantity': quantity,
  'subtotal': 100 * quantity,
  'lineAmount': 100 * quantity,
  'effectiveFrom': '2026-08-01T00:00:00.000Z',
};

Map<String, Object?> _customerJson() => <String, Object?>{
  'id': _customerId,
  'tenantId': '64f0c18f7c4d2f0012ab344',
  'branchId': 'branch-a',
  'name': 'Hassan Ali',
  'mobile': '+923001234567',
  'customerType': 'Regular',
  'joiningDate': '2026-08-12T00:00:00.000Z',
  'totalOrders': 12,
  'totalSpent': 9200,
  'outstandingBalance': 0,
  'lastOrderDate': null,
  'createdAt': '2026-08-12T00:00:00.000Z',
  'updatedAt': '2026-08-12T00:00:00.000Z',
};

Map<String, Object?> _orderJson({
  double paidAmount = 0,
  double outstandingAmount = 100,
  String paymentStatus = 'Unpaid',
}) => <String, Object?>{
  'id': _orderId,
  'tenantId': '64f0c18f7c4d2f0012ab344',
  'branchId': 'branch-a',
  'orderNumber': 'ORD-MAIN-000123',
  'customerId': _customerId,
  'customerSnapshot': <String, Object>{
    'customerId': _customerId,
    'name': 'Hassan Ali',
    'mobile': '+923001234567',
    'customerType': 'Regular',
  },
  'status': 'Received',
  'paymentStatus': paymentStatus,
  'items': <Object>[
    <String, Object>{
      'id': '64f0c18f7c4d2f0012ab347',
      'itemCategoryId': _categoryId,
      'itemCategorySnapshot': <String, Object>{'name': 'Shirt'},
      'serviceId': _serviceId,
      'serviceSnapshot': <String, Object>{'name': 'Wash & Fold'},
      'quantity': 1,
      'unitPrice': 100,
      'discount': 0,
      'tax': 5,
      'lineTotal': 105,
    },
    <String, Object>{
      'id': '64f0c18f7c4d2f0012ab348',
      'itemCategoryId': _categoryId,
      'itemCategorySnapshot': <String, Object>{'name': 'Shirt'},
      'serviceId': _secondServiceId,
      'serviceSnapshot': <String, Object>{'name': 'Ironing'},
      'quantity': 1,
      'unitPrice': 10,
      'discount': 0,
      'tax': 0.5,
      'lineTotal': 10.5,
    },
  ],
  'subtotal': 105,
  'discount': 5,
  'discountPercentage': 0,
  'tax': 0,
  'grandTotal': 100,
  'paidAmount': paidAmount,
  'outstandingAmount': outstandingAmount,
  'createdBy': '64f0c18f7c4d2f0012ab348',
  'createdAt': '2026-08-14T09:15:00.000Z',
  'updatedAt': '2026-08-14T09:15:00.000Z',
  'version': 1,
};

final class _MemoryTokenStorage implements AuthTokenStorage {
  AuthenticationSession? _session = AuthenticationSession(
    accessToken: 'order-token',
    refreshToken: 'refresh-token',
    accessTokenExpiresAt: DateTime.utc(2027),
    refreshTokenExpiresAt: DateTime.utc(2028),
    tenantId: '64f0c18f7c4d2f0012ab344',
  );

  @override
  Future<void> clear() async => _session = null;

  @override
  Future<AuthenticationSession?> read() async => _session;

  @override
  Future<void> write(AuthenticationSession session) async => _session = session;
}
