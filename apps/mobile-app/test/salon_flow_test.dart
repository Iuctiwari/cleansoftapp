import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/controllers/consumer_session_controller.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_session_storage.dart';
import 'package:nexoraa_mobile/features/online_requests/services/shop_marketplace_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';
import 'package:nexoraa_mobile/features/salon/models/salon_models.dart';
import 'package:nexoraa_mobile/features/salon/screens/salon_chat_booking_screen.dart';
import 'package:nexoraa_mobile/features/salon/screens/salon_setup_screen.dart';

final ConsumerSession _session = ConsumerSession(
  accessToken: 'a',
  refreshToken: 'r',
  accessTokenExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
  refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
  consumerId: 'consumer-1',
  displayName: 'Riya',
  email: 'riya@example.com',
  mobileNumber: '9876543210',
);

ConsumerApiService _backend(Future<http.Response> Function(http.Request) handler) {
  final MemoryConsumerSessionStorage storage = MemoryConsumerSessionStorage()..session = _session;
  ConsumerDependencies.storage = storage;
  final ConsumerApiService api = ConsumerApiService(
    authBaseUri: () => Uri.parse('http://auth.test/api'),
    marketplaceBaseUri: () => Uri.parse('http://market.test/api'),
    storage: storage,
    client: MockClient(handler),
  );
  ConsumerDependencies.api = api;
  ConsumerDependencies.controller = ConsumerSessionController(api: api, storage: storage);
  return api;
}

Widget _app(Widget home, {List<RouteBase> extra = const <RouteBase>[]}) => MaterialApp.router(
  routerConfig: GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => home),
      ...extra,
    ],
  ),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);

GoRoute _stub(String path, String name) => GoRoute(
  path: path,
  name: name,
  builder: (_, _) => Scaffold(body: Text('route:$name')),
);

ShopDetail _salon() => ShopDetail(
  shopId: 'branch-1',
  shopName: 'Glow Salon',
  branchName: 'Main',
  categories: const <ShopCategory>[ShopCategory.salon],
  distanceKm: 1.2,
  city: 'Pune',
  addressLine: 'FC Road',
  phone: '9123456789',
  serviceModes: const <ServiceMode>[ServiceMode.visitShop],
  servesYourLocation: true,
  isOpenNow: true,
  latitude: 18.5,
  longitude: 73.8,
  openingHours: List<OpeningHoursDay>.generate(
    7,
    (int day) => OpeningHoursDay(day: day, closed: false, open: '10:00', close: '19:00'),
  ),
  serviceRadiusKm: 3,
  directionsUrl: '',
  streetAddress: 'FC Road',
  state: 'Maharashtra',
  postalCode: '411004',
);

Map<String, Object?> _menuJson({bool configured = true}) => <String, Object?>{
  'configured': configured,
  'slotMinutes': 30,
  'payment': 'pay_at_shop',
  'menu': configured
      ? <Object>[
          <String, Object>{
            'serviceId': 'cut',
            'name': 'Haircut',
            'price': 300,
            'durationMinutes': 30,
            'role': 'Hair Stylist',
          },
          <String, Object>{
            'serviceId': 'makeup',
            'name': 'Makeup',
            'price': 2000,
            'durationMinutes': 60,
            'role': 'Makeup Artist',
          },
        ]
      : <Object>[],
};

void main() {
  testWidgets('chat booking: hi, services, day, time, confirm sends a salon request', (WidgetTester tester) async {
    Map<String, dynamic>? sent;
    String? slotsQuery;
    final ConsumerApiService api = _backend((http.Request r) async {
      final String path = r.url.path;
      if (path.endsWith('/menu')) return http.Response(jsonEncode(_menuJson()), 200);
      if (path.endsWith('/slots')) {
        slotsQuery = r.url.query;
        return http.Response(
          jsonEncode(<String, Object>{
            'date': r.url.queryParameters['date']!,
            'closed': false,
            'totalMinutes': 90,
            'totalPrice': 2300,
            'slots': <Object>[
              <String, String>{'start': '10:00', 'end': '11:30', 'state': 'pending'},
              <String, String>{'start': '10:30', 'end': '12:00', 'state': 'booked'},
              <String, String>{'start': '11:00', 'end': '12:30', 'state': 'available'},
            ],
          }),
          200,
        );
      }
      if (r.method == 'POST' && path.endsWith('/consumer/requests')) {
        sent = jsonDecode(r.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(<String, Object>{
            'requestId': 'r1',
            'requestNumber': 'SR-2026-000001',
            'shop': <String, String>{'shopId': 'branch-1', 'shopName': 'Glow Salon'},
            'category': 'salon',
            'requestType': 'visit_shop',
            'status': 'Pending',
            'canCancel': true,
          }),
          201,
        );
      }
      return http.Response('{}', 200);
    });
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        SalonChatBookingScreen(shop: _salon(), api: api),
        extra: <RouteBase>[
          _stub('/home', AppRouteNames.consumerHome),
          _stub('/request/:requestId', AppRouteNames.consumerRequest),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome to Glow Salon'), findsOneWidget);
    await tester.tap(find.byKey(const Key('salon.chat.send')));
    await tester.pumpAndSettle();

    expect(find.text('Haircut'), findsOneWidget);
    expect(find.textContaining('Hair Stylist'), findsOneWidget);
    await tester.tap(find.byKey(const Key('salon.service.cut')));
    await tester.tap(find.byKey(const Key('salon.service.makeup')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('salon.services.next')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Which day suits you'), findsOneWidget);
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final String key =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await tester.tap(find.byKey(Key('salon.day.$key')));
    await tester.pumpAndSettle();

    expect(slotsQuery, contains('serviceIds=cut%2Cmakeup'));
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Booked'), findsOneWidget);
    // Waiting and booked slots cannot be tapped; the free one can.
    await tester.tap(find.byKey(const Key('salon.slot.10:00')));
    await tester.pumpAndSettle();
    expect(find.text('Your appointment'), findsNothing);
    await tester.tap(find.byKey(const Key('salon.slot.11:00')));
    await tester.pumpAndSettle();

    expect(find.text('Your appointment'), findsOneWidget);
    expect(find.textContaining('No advance payment'), findsOneWidget);
    await tester.tap(find.byKey(const Key('salon.confirm')));
    await tester.pumpAndSettle();

    expect(sent, isNotNull);
    expect(sent!['category'], 'salon');
    expect(sent!['requestType'], 'visit_shop');
    expect(sent!['salonServiceIds'], <String>['cut', 'makeup']);
    expect(sent!['preferredSlot'], <String, String>{'start': '11:00', 'end': '12:30'});
    expect(sent!.containsKey('addressId'), isFalse);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('route:${AppRouteNames.consumerRequest}'), findsOneWidget);
  });

  testWidgets('chat booking: a salon that has not opened online booking says so', (WidgetTester tester) async {
    final ConsumerApiService api = _backend(
      (http.Request r) async => http.Response(jsonEncode(_menuJson(configured: false)), 200),
    );
    await tester.pumpWidget(_app(SalonChatBookingScreen(shop: _salon(), api: api)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('salon.chat.send')));
    await tester.pumpAndSettle();

    expect(find.textContaining('has not opened online booking yet'), findsOneWidget);
    expect(find.byKey(const Key('salon.services.next')), findsNothing);
  });

  testWidgets('owner setup: add a team member and a service by role, then save', (WidgetTester tester) async {
    Map<String, dynamic>? saved;
    final AuthenticationSession session = AuthenticationSession(
      accessToken: 'shop-token',
      refreshToken: 'r',
      accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
      refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      branchName: 'Main',
      businessName: 'Glow Salon',
      roleCode: 'Owner',
      permissions: const <String>[],
    );
    final ShopMarketplaceApiService service = ShopMarketplaceApiService(
      tokenStorage: _Storage(session),
      branchId: 'branch-1',
      baseUri: () => Uri.parse('http://market.test/api'),
      client: MockClient((http.Request r) async {
        if (r.method == 'PUT') {
          saved = jsonDecode(r.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode(<String, Object>{
              'configured': true,
              'slotMinutes': 30,
              'staff': <Object>[
                <String, String>{'staffId': 's1', 'name': 'Asha', 'role': 'Hair Stylist'},
              ],
              'menu': <Object>[
                <String, Object>{
                  'serviceId': 'm1',
                  'name': 'Haircut',
                  'price': 300,
                  'durationMinutes': 30,
                  'role': 'Hair Stylist',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode(<String, Object>{'configured': false, 'slotMinutes': 30, 'staff': <Object>[], 'menu': <Object>[]}),
          200,
        );
      }),
    );
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        SalonSetupScreen(
          branch: const ShopBranchArgs(branchId: 'branch-1'),
          service: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A service needs a team member with a role first.
    await tester.tap(find.byKey(const Key('salon.menu.add')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Add your team first'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));

    await tester.tap(find.byKey(const Key('salon.staff.add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('salon.staff.name')), 'Asha');
    await tester.tap(find.widgetWithText(ActionChip, 'Hair Stylist'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('salon.staff.save')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('salon.menu.add')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('salon.menu.name')), 'Haircut');
    await tester.enterText(find.byKey(const Key('salon.menu.price')), '300');
    await tester.tap(find.byKey(const Key('salon.menu.save')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('salon.setup.save')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!['slotMinutes'], 30);
    expect(saved!['staff'], <Object>[
      <String, String>{'name': 'Asha', 'role': 'Hair Stylist'},
    ]);
    expect(saved!['menu'], <Object>[
      <String, Object>{'name': 'Haircut', 'price': 300.0, 'durationMinutes': 30, 'role': 'Hair Stylist'},
    ]);
  });

  test('the salon booking on a request lists who does each service', () {
    final ServiceRequest request = ServiceRequest.fromJson(<String, dynamic>{
      'requestId': 'r1',
      'status': 'Pending',
      'salon': <String, Object>{
        'totalPrice': 2300,
        'totalMinutes': 90,
        'parts': <Object>[
          <String, Object>{
            'serviceId': 'cut',
            'name': 'Haircut',
            'price': 300,
            'role': 'Hair Stylist',
            'staffId': 's1',
            'staffName': 'Asha',
            'startMinute': 600,
            'endMinute': 630,
          },
          <String, Object>{
            'serviceId': 'makeup',
            'name': 'Makeup',
            'price': 2000,
            'role': 'Makeup Artist',
            'staffId': 'm1',
            'staffName': 'Priya',
            'startMinute': 630,
            'endMinute': 690,
          },
        ],
      },
    });
    expect(request.salon!.parts.map((SalonBookedPart p) => '${p.name}:${p.staffName}:${p.start}-${p.end}'), <String>[
      'Haircut:Asha:10:00-10:30',
      'Makeup:Priya:10:30-11:30',
    ]);
    expect(ServiceRequest.fromJson(<String, dynamic>{'requestId': 'r2', 'status': 'Pending'}).salon, isNull);
  });
}

class _Storage implements AuthTokenStorage {
  _Storage(this.session);
  final AuthenticationSession session;
  @override
  Future<void> clear() async {}
  @override
  Future<AuthenticationSession?> read() async => session;
  @override
  Future<void> write(AuthenticationSession session) async {}
}
