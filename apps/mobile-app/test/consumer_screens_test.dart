import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/controllers/consumer_session_controller.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/screens/booking_screen.dart';
import 'package:nexoraa_mobile/features/consumer/screens/consumer_auth_screens.dart';
import 'package:nexoraa_mobile/features/consumer/screens/request_detail_screen.dart';
import 'package:nexoraa_mobile/features/consumer/screens/welcome_screen.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_session_storage.dart';

/// Points the customer dependencies at a fake backend.
void _useBackend(Future<http.Response> Function(http.Request) handler, {ConsumerSession? session}) {
  final MemoryConsumerSessionStorage storage = MemoryConsumerSessionStorage()..session = session;
  ConsumerDependencies.storage = storage;
  ConsumerDependencies.api = ConsumerApiService(
    authBaseUri: () => Uri.parse('http://auth.test/api'),
    marketplaceBaseUri: () => Uri.parse('http://market.test/api'),
    storage: storage,
    client: MockClient(handler),
  );
  ConsumerDependencies.controller = ConsumerSessionController(api: ConsumerDependencies.api, storage: storage);
}

Widget _app(Widget home, {List<RouteBase> extra = const <RouteBase>[]}) {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => home),
      ...extra,
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

GoRoute _stub(String path, String name) =>
    GoRoute(path: path, name: name, builder: (_, _) => Scaffold(body: Text('route:$name')));

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

ShopDetail _shop({List<ServiceMode> modes = const <ServiceMode>[ServiceMode.visitShop, ServiceMode.pickupDrop]}) =>
    ShopDetail(
      shopId: 'branch-1',
      shopName: 'Sparkle Laundry',
      branchName: 'Head Office',
      categories: const <ShopCategory>[ShopCategory.laundry, ShopCategory.dryCleaning],
      distanceKm: 2.6,
      city: 'Mumbai',
      addressLine: 'Shop 4, SV Road',
      phone: '9123456789',
      serviceModes: modes,
      servesYourLocation: true,
      isOpenNow: true,
      latitude: 19.11,
      longitude: 72.84,
      openingHours: List<OpeningHoursDay>.generate(
        7,
        (int day) => OpeningHoursDay(day: day, closed: false, open: '08:00', close: '21:00'),
      ),
      serviceRadiusKm: 3,
      directionsUrl: '',
      streetAddress: 'Shop 4, SV Road',
      state: 'Maharashtra',
      postalCode: '400058',
    );

void main() {
  testWidgets('welcome screen offers customer and business paths', (WidgetTester tester) async {
    await tester.pumpWidget(
      _app(
        const WelcomeScreen(),
        extra: <RouteBase>[
          _stub('/c-login', AppRouteNames.consumerLogin),
          _stub('/login', AppRouteNames.login),
        ],
      ),
    );

    expect(find.text('I need a service'), findsOneWidget);
    expect(find.text('I run a business'), findsOneWidget);

    await tester.tap(find.byKey(const Key('welcome.customer')));
    await tester.pumpAndSettle();
    expect(find.text('route:${AppRouteNames.consumerLogin}'), findsOneWidget);
  });

  testWidgets('sign-up validates mobile, email, password and confirmation', (WidgetTester tester) async {
    _useBackend((_) async => http.Response('{}', 500));
    await tester.pumpWidget(_app(const ConsumerSignupScreen()));

    await tester.enterText(find.byType(TextFormField).at(0), 'Riya Sharma');
    await tester.enterText(find.byType(TextFormField).at(1), '12345');
    await tester.enterText(find.byType(TextFormField).at(2), 'not-an-email');
    await tester.enterText(find.byType(TextFormField).at(3), 'weak');
    await tester.enterText(find.byType(TextFormField).at(4), 'other');
    await tester.ensureVisible(find.text('Create an account').last);
    await tester.tap(find.text('Create an account').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('mobile', findRichText: true), findsWidgets);
    expect(find.textContaining('at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
  });

  testWidgets('unverified sign-in goes to the verify screen with the email', (WidgetTester tester) async {
    final List<String> calls = <String>[];
    _useBackend((http.Request request) async {
      calls.add(request.url.path);
      if (request.url.path.endsWith('/login')) {
        return http.Response(jsonEncode(<String, Object>{'error': <String, String>{'code': 'auth.email_not_verified'}}), 403);
      }
      return http.Response(jsonEncode(<String, Object>{'data': <String, int>{'resendAvailableInSeconds': 60}}), 200);
    });
    await tester.pumpWidget(
      _app(
        const ConsumerLoginScreen(),
        extra: <RouteBase>[
          GoRoute(
            path: '/verify',
            name: AppRouteNames.consumerVerify,
            builder: (_, GoRouterState state) =>
                Text('verify:${(state.extra! as ConsumerVerifyArgs).email}'),
          ),
        ],
      ),
    );

    await tester.enterText(find.byKey(const Key('consumerLogin.identifier')).last, 'riya@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'Fresh@2026Pass');
    await tester.tap(find.byKey(const Key('consumerLogin.submit')));
    await tester.pumpAndSettle();

    expect(find.text('verify:riya@example.com'), findsOneWidget);
    expect(calls, contains('/api/v1/auth/consumer/resend-verification'));
  });

  testWidgets('wrong password shows a pop-up and stays signed out', (WidgetTester tester) async {
    _useBackend(
      (_) async => http.Response(jsonEncode(<String, Object>{'error': <String, String>{'code': 'auth.login_denied'}}), 401),
    );
    await tester.pumpWidget(_app(const ConsumerLoginScreen()));

    await tester.enterText(find.byKey(const Key('consumerLogin.identifier')).last, '9876543210');
    await tester.enterText(find.byType(TextFormField).at(1), 'nope');
    await tester.tap(find.byKey(const Key('consumerLogin.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email/mobile or password.'), findsOneWidget);
    expect(ConsumerDependencies.controller.isAuthenticated, isFalse);
  });

  testWidgets('booking offers only the shop services and blocks a too-short description', (WidgetTester tester) async {
    int posts = 0;
    _useBackend((http.Request request) async {
      if (request.method == 'POST') posts++;
      return http.Response(jsonEncode(<Object>[]), 200); // no saved addresses
    }, session: _session);
    await tester.pumpWidget(_app(BookingScreen(shop: _shop(modes: const <ServiceMode>[ServiceMode.visitShop]))));
    await tester.pumpAndSettle();

    expect(find.text('Laundry'), findsOneWidget);
    expect(find.text('Dry Cleaning'), findsOneWidget);
    expect(find.text('Salon'), findsNothing);
    expect(find.text('Pickup & drop'), findsNothing);

    await tester.enterText(find.byKey(const Key('booking.description')), 'hi');
    await tester.tap(find.byKey(const Key('booking.send')));
    await tester.pump();

    expect(find.textContaining('at least 5 characters'), findsOneWidget);
    expect(posts, 0);
  });

  testWidgets('booking sends the request with the chosen options', (WidgetTester tester) async {
    Map<String, dynamic>? sent;
    _useBackend((http.Request request) async {
      if (request.method == 'POST') {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode(<String, Object>{
            'requestId': 'r1',
            'requestNumber': 'SR-2026-000001',
            'shop': <String, String>{'shopId': 'branch-1', 'shopName': 'Sparkle Laundry'},
            'category': 'laundry',
            'requestType': 'visit_shop',
            'status': 'Pending',
            'canCancel': true,
          }),
          201,
        );
      }
      return http.Response(jsonEncode(<Object>[]), 200);
    }, session: _session);
    await tester.pumpWidget(
      _app(
        BookingScreen(shop: _shop(modes: const <ServiceMode>[ServiceMode.visitShop])),
        extra: <RouteBase>[
          _stub('/home', AppRouteNames.consumerHome),
          _stub('/request/:requestId', AppRouteNames.consumerRequest),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('booking.description')), 'Wash and iron 5 shirts');
    await tester.tap(find.byKey(const Key('booking.send')));
    await tester.pumpAndSettle();

    expect(sent, isNotNull);
    expect(sent!['shopId'], 'branch-1');
    expect(sent!['category'], 'laundry');
    expect(sent!['requestType'], 'visit_shop');
    expect(sent!['description'], 'Wash and iron 5 shirts');
    expect(sent!.containsKey('addressId'), isFalse);
    expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(sent!['preferredDate'] as String), isTrue);
    expect(find.text('Request sent!'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('route:${AppRouteNames.consumerRequest}'), findsOneWidget);
  });

  testWidgets('customer cancels a waiting request with a reason', (WidgetTester tester) async {
    Map<String, dynamic> request = <String, dynamic>{
      'requestId': 'r1',
      'requestNumber': 'SR-2026-000009',
      'shop': <String, String>{'shopId': 'b1', 'shopName': 'Sparkle Laundry', 'phone': '9123456789'},
      'category': 'laundry',
      'requestType': 'visit_shop',
      'description': 'Dry clean 2 suits',
      'preferredDate': '2030-01-08',
      'preferredSlot': <String, String>{'start': '10:00', 'end': '12:00'},
      'status': 'Pending',
      'canCancel': true,
      'expiresAt': '2030-01-03T10:00:00.000Z',
      'createdAt': '2030-01-01T10:00:00.000Z',
      'history': <Object>[<String, String>{'status': 'Pending', 'at': '2030-01-01T10:00:00.000Z', 'by': 'customer'}],
    };
    String? sentReason;
    _useBackend((http.Request r) async {
      if (r.url.path.endsWith('/cancel')) {
        sentReason = (jsonDecode(r.body) as Map<String, dynamic>)['reason'] as String?;
        request = <String, dynamic>{...request, 'status': 'Cancelled', 'canCancel': false, 'cancelReason': sentReason};
      }
      return http.Response(jsonEncode(request), 200);
    }, session: _session);
    await tester.pumpWidget(_app(const RequestDetailScreen(requestId: 'r1')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('request.cancel')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Found another shop');
    await tester.tap(find.byKey(const Key('cancel.confirm')));
    await tester.pumpAndSettle();

    expect(sentReason, 'Found another shop');
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.byKey(const Key('request.cancel')), findsNothing);
  });
}
