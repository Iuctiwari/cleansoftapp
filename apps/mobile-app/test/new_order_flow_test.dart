import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/services/shop_marketplace_api_service.dart';
import 'package:nexoraa_mobile/features/salon/models/salon_models.dart';
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
  test('a pickup order gets a Photos & delivery step before Payment; a normal order does not', () async {
    final List<int> asked = <int>[];
    final _FlowDependencies pickup = await _dependencies(
      (_) async => http.Response('{}', 500),
      pickup: PickupOrderContext(
        requestId: 'req-1',
        estimate: (int quantity) async {
          asked.add(quantity);
          return '2030-01-10';
        },
      ),
    );
    final NewOrderController c = pickup.newOrder;
    expect(c.stepCount, 7);
    expect(c.stages.sublist(3, 6), <NewOrderStage>[NewOrderStage.pricing, NewOrderStage.photos, NewOrderStage.payment]);

    // at most six photos, and they can be removed
    for (int i = 0; i < 8; i++) {
      c.addPhoto(Uint8List.fromList(<int>[i]));
    }
    expect(c.photos.length, 6);
    c.removePhotoAt(0);
    expect(c.photos.length, 5);

    // the delivery date follows the typed total; a custom date wins until it is cleared
    c.setTotalItems('12');
    await Future<void>.delayed(Duration.zero);
    expect(asked.last, 12);
    expect(c.totalItems, 12);
    expect(c.deliveryDate, '2030-01-10');
    expect(c.deliveryIsCustom, isFalse);
    c.setCustomDeliveryDate('2030-01-15');
    expect(c.deliveryDate, '2030-01-15');
    expect(c.deliveryIsCustom, isTrue);
    c.setCustomDeliveryDate(null);
    expect(c.deliveryDate, '2030-01-10');

    // an empty or invalid total means "not given"
    c.setTotalItems('');
    expect(c.totalItems, isNull);

    final _FlowDependencies plain = await _dependencies((_) async => http.Response('{}', 500));
    expect(plain.newOrder.stepCount, 6);
    expect(plain.newOrder.stages, isNot(contains(NewOrderStage.photos)));
  });

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
        dependencies.newOrder.uniqueItems.map((item) => item.name),
        <String>['Hair', 'Shirt', 'Trouser'],
      );
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
          if (request.url.path.endsWith('/statistics')) {
            return http.Response(
              jsonEncode(<String, Object>{
                'totalOrders': 12,
                'todayOrders': 0,
                'yesterdayOrders': 0,
                'outstandingTotal': 0,
                'outstandingCustomerCount': 0,
                'statusBreakdown': <String, int>{},
              }),
              200,
            );
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
      expect(find.textContaining('12 orders'), findsOneWidget);
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

  testWidgets(
    'displays unique items only once without category or service grouping headers',
    (WidgetTester tester) async {
      const String trouserCategoryId = '64f0c18f7c4d2f0012ab351';
      final Map<String, Object> trouser = <String, Object>{
        ..._categoryJson(),
        'id': trouserCategoryId,
        'name': 'Trouser',
        'code': 'ITEM_TROUSER',
        'catalogGroupCodes': <String>['LAUNDRY'],
      };
      final _FlowDependencies dependencies = await _dependencies(
        (_) async => http.Response('{}', 500),
        catalogCategories: <Object>[_categoryJson(), trouser],
        catalogServices: <Object>[
          _serviceJson(),
          _serviceJson(serviceId: _secondServiceId, name: 'Ironing'),
        ],
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

      await tester.tap(find.text('Hassan Ali'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('2/6'), findsOneWidget);
      // Group headers should NOT be shown
      expect(find.text('LAUNDRY'), findsNothing);
      expect(find.text('OTHER'), findsNothing);

      // Unique items appear only once
      expect(find.byType(NewOrderItemCard), findsNWidgets(2));
      expect(find.text('Shirt'), findsOneWidget);
      expect(find.text('Trouser'), findsOneWidget);

      // Select shirt amount
      await tester.tap(find.byIcon(AppIcons.add).first);
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3 shows both associated services for the selected Shirt
      expect(find.text('3/6'), findsOneWidget);
      expect(find.text('Wash & Fold'), findsOneWidget);
      expect(find.text('Ironing'), findsOneWidget);
    },
  );

  group('salon orders', () {
    ShopMarketplaceApiService salonService(List<http.Request> calls, {bool salon = true}) => ShopMarketplaceApiService(
      tokenStorage: _MemoryTokenStorage(),
      branchId: 'branch-a',
      baseUri: () => Uri.parse('http://market.test/api'),
      client: MockClient((http.Request request) async {
        calls.add(request);
        final String path = request.url.path;
        if (path.endsWith('/shop/salon/config')) {
          if (!salon) return http.Response('{"message":"salons only"}', 403);
          return http.Response(
            jsonEncode(<String, Object>{
              'configured': true,
              'slotMinutes': 30,
              'staff': <Object>[],
              'menu': <Object>[
                <String, Object>{
                  'serviceId': 'm1',
                  'name': 'Haircut',
                  'price': 100,
                  'durationMinutes': 30,
                  'role': 'Hair Stylist',
                  'catalogServiceId': _serviceId,
                  'catalogItemCategoryId': _categoryId,
                },
                <String, Object>{
                  'serviceId': 'm2',
                  'name': 'Facial',
                  'price': 100,
                  'durationMinutes': 60,
                  'role': 'Beautician',
                  'catalogServiceId': _secondServiceId,
                  'catalogItemCategoryId': _categoryId,
                },
                <String, Object>{
                  'serviceId': 'm3',
                  'name': 'Unlinked service',
                  'price': 50,
                  'durationMinutes': 15,
                  'role': 'Barber',
                },
              ],
            }),
            200,
          );
        }
        if (path.endsWith('/shop/salon/walk-in')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'requestId': 'req-walk',
              'requestNumber': 'SR-2026-000009',
              'totalPrice': 200,
              'parts': <Object>[
                <String, Object>{
                  'serviceId': 'm1',
                  'name': 'Haircut',
                  'price': 100,
                  'role': 'Hair Stylist',
                  'staffId': 's1',
                  'staffName': 'Priya',
                  'startMinute': 660,
                  'endMinute': 690,
                },
                <String, Object>{
                  'serviceId': 'm2',
                  'name': 'Facial',
                  'price': 100,
                  'role': 'Beautician',
                  'staffId': 's2',
                  'staffName': 'Riya',
                  'startMinute': 690,
                  'endMinute': 750,
                },
              ],
            }),
            201,
          );
        }
        return http.Response(jsonEncode(<String, Object>{'requestId': 'req-walk', 'status': 'Accepted'}), 200);
      }),
    );

    Future<http.Response> orderHandler(http.Request request, List<Map<String, dynamic>> created) async {
      if (request.url.path.endsWith('/statistics')) {
        return http.Response(
          jsonEncode(<String, Object>{
            'totalOrders': 0,
            'todayOrders': 0,
            'yesterdayOrders': 0,
            'outstandingTotal': 0,
            'outstandingCustomerCount': 0,
            'statusBreakdown': <String, int>{},
          }),
          200,
        );
      }
      if (request.method == 'POST') created.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response(jsonEncode(_orderJson()), request.method == 'POST' ? 201 : 200);
    }

    testWidgets('a walk-in picks salon services, staff are assigned, and every service is full price', (
      WidgetTester tester,
    ) async {
      final List<http.Request> calls = <http.Request>[];
      final List<Map<String, dynamic>> created = <Map<String, dynamic>>[];
      final _FlowDependencies dependencies = await _dependencies(
        (http.Request request) => orderHandler(request, created),
        salonApi: salonService(calls),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: NewOrderScreen(
            controller: dependencies.newOrder,
            orderController: dependencies.orders,
            customerController: dependencies.customers,
            businessName: 'Glow Salon',
            branchName: 'Main',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No item or service steps: customer, services, review, payment, receipt.
      expect(find.text('1/5'), findsOneWidget);
      await tester.tap(find.text('Hassan Ali'));
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('2/5'), findsOneWidget);
      expect(find.text('Haircut'), findsOneWidget);
      expect(find.text('Facial'), findsOneWidget);
      expect(find.text('Unlinked service'), findsNothing); // not in the price list, so it cannot be billed
      await tester.tap(find.byKey(const Key('order.salon.m1')));
      await tester.tap(find.byKey(const Key('order.salon.m2')));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('3/5'), findsOneWidget);
      // Both services are on the same item, yet both are charged in full: 100 + 100, plus 5% tax.
      expect(dependencies.newOrder.previewGrandTotal, 210);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('4/5'), findsOneWidget);
      await tester.tap(find.text('Save Order'));
      await tester.pumpAndSettle();

      expect(find.text('5/5'), findsOneWidget);
      final http.Request walkIn = calls.firstWhere((http.Request r) => r.url.path.endsWith('/shop/salon/walk-in'));
      expect(jsonDecode(walkIn.body), <String, Object>{
        'customerId': _customerId,
        'serviceIds': <String>['m1', 'm2'],
      });
      expect(created, hasLength(1));
      final List<dynamic> items = created.single['items'] as List<dynamic>;
      expect(items, hasLength(2));
      expect(items.every((dynamic i) => (i as Map<String, dynamic>)['standalonePrice'] == true), isTrue);
      expect(calls.any((http.Request r) => r.url.path.endsWith('/shop/requests/req-walk/link-order')), isTrue);
      expect(dependencies.newOrder.walkIn!.parts.map((SalonBookedPart p) => p.staffName), <String>['Priya', 'Riya']);
    });

    testWidgets('a shop that is not a salon keeps the normal six steps', (WidgetTester tester) async {
      final List<http.Request> calls = <http.Request>[];
      final _FlowDependencies dependencies = await _dependencies(
        (_) async => http.Response('{}', 500),
        salonApi: salonService(calls, salon: false),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: NewOrderScreen(
            controller: dependencies.newOrder,
            orderController: dependencies.orders,
            customerController: dependencies.customers,
            businessName: 'Wash Co',
            branchName: 'Main',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1/6'), findsOneWidget);
      expect(dependencies.newOrder.isSalonWalkIn, isFalse);
      expect(dependencies.newOrder.stages, contains(NewOrderStage.items));
    });

    test('an online salon booking becomes an order with no selection steps', () async {
      final List<Map<String, dynamic>> created = <Map<String, dynamic>>[];
      final _FlowDependencies dependencies = await _dependencies(
        (http.Request request) => orderHandler(request, created),
        salonPreset: <SalonBookedPart>[
          const SalonBookedPart(
            serviceId: 'm1',
            name: 'Haircut',
            price: 100,
            role: 'Hair Stylist',
            staffId: 's1',
            staffName: 'Priya',
            start: '11:00',
            end: '11:30',
            catalogServiceId: _serviceId,
            catalogItemCategoryId: _categoryId,
          ),
          const SalonBookedPart(
            serviceId: 'm2',
            name: 'Facial',
            price: 100,
            role: 'Beautician',
            staffId: 's2',
            staffName: 'Riya',
            start: '11:30',
            end: '12:30',
            catalogServiceId: _secondServiceId,
            catalogItemCategoryId: _categoryId,
          ),
        ],
      );
      await dependencies.customers.load();
      dependencies.newOrder.selectCustomer(dependencies.customers.customers.first);

      expect(await dependencies.newOrder.applySalonPreset(), isTrue);
      expect(dependencies.newOrder.stages, <NewOrderStage>[
        NewOrderStage.pricing,
        NewOrderStage.payment,
        NewOrderStage.receipt,
      ]);
      expect(dependencies.newOrder.stage, NewOrderStage.pricing);
      expect(dependencies.newOrder.previewGrandTotal, 210);

      expect(dependencies.newOrder.next(), isTrue); // review -> payment
      expect(await dependencies.newOrder.save(), isNotNull);
      final List<dynamic> items = created.single['items'] as List<dynamic>;
      expect(items.map((dynamic i) => (i as Map<String, dynamic>)['serviceId']), <String>[
        _serviceId,
        _secondServiceId,
      ]);
      expect(items.every((dynamic i) => (i as Map<String, dynamic>)['standalonePrice'] == true), isTrue);
    });
  });
}

Future<_FlowDependencies> _dependencies(
  Future<http.Response> Function(http.Request request) orderHandler, {
  Future<http.Response> Function(http.Request request)? paymentHandler,
  List<Object>? catalogCategories,
  List<Object>? catalogServices,
  PickupOrderContext? pickup,
  ShopMarketplaceApiService? salonApi,
  List<SalonBookedPart>? salonPreset,
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
      pickup: pickup,
      salonApi: salonApi,
      salonPreset: salonPreset,
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
