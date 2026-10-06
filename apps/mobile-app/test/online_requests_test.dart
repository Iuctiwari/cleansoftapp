import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/controllers/authentication_controller.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/authentication/services/authentication_service.dart';
import 'package:nexoraa_mobile/features/online_requests/screens/shop_listing_screen.dart';
import 'package:nexoraa_mobile/features/online_requests/screens/shop_request_detail_screen.dart';
import 'package:nexoraa_mobile/features/online_requests/services/shop_marketplace_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/online_requests_card.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';

AuthenticationSession _session(String role, List<String> permissions) => AuthenticationSession(
  accessToken: 'shop-token',
  refreshToken: 'r',
  accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
  refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
  tenantId: 'tenant-1',
  branchId: 'branch-1',
  branchName: 'Head Office',
  businessName: 'Sparkle Laundry',
  roleCode: role,
  permissions: permissions,
);

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

class _Service implements AuthenticationService {
  _Service(this.session);
  final AuthenticationSession session;
  @override
  Future<AuthenticationSession?> restoreSession() async => session;
  @override
  Future<AuthenticationSession> signIn({required String identifier, required String password}) async => session;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> requestPasswordReset({required String identifier}) async {}
  @override
  Future<void> confirmPasswordReset({required String identifier, required String otp, required String newPassword}) async {}
  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {}
}

/// Signs the app in as [role] for the access-policy checks.
Future<AuthTokenStorage> _signInAs(String role, List<String> permissions) async {
  final AuthenticationSession session = _session(role, permissions);
  final _Storage storage = _Storage(session);
  AuthenticationDependencies.tokenStorage = storage;
  AuthenticationDependencies.controller = AuthenticationController(service: _Service(session));
  await AuthenticationDependencies.controller.restoreSession();
  return storage;
}

class _Backend {
  final List<http.Request> requests = <http.Request>[];
  Map<String, dynamic> listing = _incompleteListing();
  Map<String, dynamic> request = _pendingRequest();

  ShopMarketplaceApiService service(AuthTokenStorage storage) => ShopMarketplaceApiService(
    tokenStorage: storage,
    branchId: 'branch-1',
    baseUri: () => Uri.parse('http://market.test/api'),
    client: MockClient((http.Request r) async {
      requests.add(r);
      final String path = r.url.path;
      if (path.endsWith('/shop/requests/summary')) {
        return http.Response(jsonEncode(<String, int>{'pending': 3, 'accepted': 1}), 200);
      }
      if (path.endsWith('/shop-listing/me')) {
        if (r.method == 'PUT') {
          listing = <String, dynamic>{...listing, ...jsonDecode(r.body) as Map<String, dynamic>, 'missingFields': <String>[], 'isVisibleToCustomers': true, 'saved': true};
        }
        return http.Response(jsonEncode(listing), 200);
      }
      if (path.endsWith('/accept')) {
        request = <String, dynamic>{...request, 'status': 'Accepted', 'shopNote': (jsonDecode(r.body) as Map<String, dynamic>)['note'], 'actions': <String, bool>{'accept': false, 'decline': true, 'linkOrder': true, 'complete': true}};
      }
      if (path.endsWith('/decline')) {
        request = <String, dynamic>{...request, 'status': 'Declined', 'declineReason': (jsonDecode(r.body) as Map<String, dynamic>)['reason'], 'actions': <String, bool>{}};
      }
      if (path.contains('/shop/requests/')) return http.Response(jsonEncode(request), 200);
      return http.Response('{}', 404);
    }),
  );
}

Map<String, dynamic> _incompleteListing() => <String, dynamic>{
  'branchId': 'branch-1',
  'shopName': 'Sparkle Laundry',
  'branchName': 'Head Office',
  'categories': <String>['laundry'],
  'address': <String, String>{'streetAddress': 'Shop 4', 'city': 'Mumbai', 'state': '', 'postalCode': '400058'},
  'ownerPhone': '9123456789',
  'phoneShownToCustomers': '9123456789',
  'serviceModes': <String>[],
  'serviceRadiusKm': 5,
  'openingHours': <Object>[],
  'isListed': true,
  'saved': false,
  'missingFields': <String>['state', 'location', 'serviceModes'],
  'isVisibleToCustomers': false,
  'hiddenReason': 'incomplete',
};

Map<String, dynamic> _pendingRequest() => <String, dynamic>{
  'requestId': 'req-1',
  'requestNumber': 'SR-2026-000007',
  'shop': <String, String>{'shopId': 'branch-1', 'shopName': 'Sparkle Laundry'},
  'category': 'laundry',
  'requestType': 'pickup_drop',
  'description': 'Pickup curtains',
  'items': <Object>[<String, Object>{'name': 'Curtain', 'quantity': 4}],
  'preferredDate': '2030-01-08',
  'preferredSlot': <String, String>{'start': '10:00', 'end': '12:00'},
  'status': 'Pending',
  'customer': <String, String>{'name': 'Riya Sharma', 'mobile': '9876543210', 'email': 'riya@example.com'},
  'shopCustomerId': 'crm-1',
  'address': <String, Object>{'label': 'Home', 'formatted': 'Flat 302, Lokhandwala', 'contactName': 'Riya', 'contactPhone': '9876543210', 'latitude': 19.13, 'longitude': 72.84},
  'distanceKm': 1.1,
  'expiresAt': '2030-01-03T10:00:00.000Z',
  'createdAt': '2030-01-01T10:00:00.000Z',
  'updatedAt': '2030-01-01T10:00:00.000Z',
  'actions': <String, bool>{'accept': true, 'decline': true, 'linkOrder': false, 'complete': false},
  'history': <Object>[<String, String>{'status': 'Pending', 'at': '2030-01-01T10:00:00.000Z', 'by': 'customer'}],
};

Widget _app(Widget child) {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => Scaffold(body: ListView(children: <Widget>[child]))),
      GoRoute(path: '/listing', name: AppRouteNames.shopListing, builder: (_, _) => const Text('route:listing')),
      GoRoute(path: '/requests', name: AppRouteNames.onlineRequests, builder: (_, _) => const Text('route:requests')),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

Widget _page(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

const ShopBranchArgs _branch = ShopBranchArgs(branchId: 'branch-1', branchName: 'Head Office', businessName: 'Sparkle Laundry');

void main() {
  setUp(() => OnlineRequestsCard.addressPromptShown = false);

  testWidgets('owner dashboard card: waiting count, address banner and a one-time pop-up', (WidgetTester tester) async {
    final AuthTokenStorage storage = await _signInAs('Owner', const <String>[]);
    final _Backend backend = _Backend();
    await tester.pumpWidget(_app(OnlineRequestsCard(branch: _branch, serviceFactory: (_) => backend.service(storage))));
    await tester.pumpAndSettle();

    expect(find.text('Add your shop address'), findsWidgets); // pop-up + banner
    expect(find.byKey(const Key('addressPrompt.add')), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard.addShopAddress')), findsOneWidget);
    expect(find.text('3 waiting'), findsOneWidget);
    expect(backend.requests.every((http.Request r) => r.headers['x-branch-id'] == 'branch-1'), isTrue);

    // Rebuilding the dashboard does not pop the dialog up again.
    await tester.pumpWidget(_app(OnlineRequestsCard(key: UniqueKey(), branch: _branch, serviceFactory: (_) => backend.service(storage))));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('addressPrompt.add')), findsNothing);

    await tester.tap(find.byKey(const Key('dashboard.onlineRequests')));
    await tester.pumpAndSettle();
    expect(find.text('route:requests'), findsOneWidget);
  });

  testWidgets('staff see the requests card but no address banner or pop-up', (WidgetTester tester) async {
    final AuthTokenStorage storage = await _signInAs('Staff', const <String>['orders:read', 'orders:write']);
    final _Backend backend = _Backend();
    await tester.pumpWidget(_app(OnlineRequestsCard(branch: _branch, serviceFactory: (_) => backend.service(storage))));
    await tester.pumpAndSettle();

    expect(find.text('3 waiting'), findsOneWidget);
    expect(find.text('Add your shop address'), findsNothing);
    expect(backend.requests.any((http.Request r) => r.url.path.endsWith('/shop-listing/me')), isFalse);
  });

  testWidgets('listing screen: shows what is missing, validates the booking phone, saves', (WidgetTester tester) async {
    final AuthTokenStorage storage = await _signInAs('Owner', const <String>[]);
    final _Backend backend = _Backend();
    backend.listing = <String, dynamic>{
      ..._incompleteListing(),
      'latitude': 19.1197,
      'longitude': 72.8468,
      'serviceModes': <String>['visit_shop'],
    };
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_page(ShopListingScreen(branch: _branch, service: backend.service(storage))));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hidden from customers'), findsOneWidget);
    expect(find.textContaining('Leave empty to use your phone: 9123456789'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Maharashtra').evaluate().isEmpty
        ? find.byType(TextFormField).at(5)
        : find.widgetWithText(TextFormField, 'Maharashtra'), 'Maharashtra');
    await tester.enterText(find.byType(TextFormField).at(6), '12345');
    await tester.tap(find.byKey(const Key('listing.save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter a 10-digit mobile or a landline with STD code'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(6), '022 2345 6789');
    await tester.tap(find.byKey(const Key('listing.save')));
    await tester.pumpAndSettle();

    final http.Request put = backend.requests.lastWhere((http.Request r) => r.method == 'PUT');
    final Map<String, dynamic> body = jsonDecode(put.body) as Map<String, dynamic>;
    expect(body['state'], 'Maharashtra');
    expect(body['bookingPhone'], '022 2345 6789');
    expect(body['serviceModes'], <String>['visit_shop']);
    expect((body['openingHours'] as List<dynamic>).length, 7);
    expect(find.text('Customers can find your shop'), findsOneWidget);
  });

  testWidgets('staff can open the listing but not edit it', (WidgetTester tester) async {
    final AuthTokenStorage storage = await _signInAs('Staff', const <String>['orders:read']);
    final _Backend backend = _Backend();
    await tester.pumpWidget(_page(ShopListingScreen(branch: _branch, service: backend.service(storage))));
    await tester.pumpAndSettle();

    expect(find.text('Only the owner or a branch manager can change the shop listing.'), findsOneWidget);
    expect(find.byKey(const Key('listing.save')), findsNothing);
  });

  testWidgets('request detail: accept with a note, then create-order becomes available', (WidgetTester tester) async {
    final AuthTokenStorage storage = await _signInAs('Owner', const <String>[]);
    final _Backend backend = _Backend();
    await tester.pumpWidget(_page(ShopRequestDetailScreen(requestId: 'req-1', branch: _branch, service: backend.service(storage))));
    await tester.pumpAndSettle();

    expect(find.text('Riya Sharma'), findsWidgets);
    expect(find.text('• Curtain × 4'), findsOneWidget);
    expect(find.textContaining('1.1 km from your shop'), findsOneWidget);

    await tester.tap(find.byKey(const Key('request.accept')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'We will come at 10:30');
    await tester.tap(find.byKey(const Key('accept.confirm')));
    await tester.pumpAndSettle();

    final http.Request accept = backend.requests.lastWhere((http.Request r) => r.url.path.endsWith('/accept'));
    final Map<String, dynamic> body = jsonDecode(accept.body) as Map<String, dynamic>;
    expect(body['note'], 'We will come at 10:30');
    expect(DateTime.parse(body['confirmedAt'] as String).toLocal().hour, 10);
    expect(find.byKey(const Key('request.createOrder')), findsOneWidget);
    expect(find.byKey(const Key('request.accept')), findsNothing);
  });

  testWidgets('request detail: decline needs a reason', (WidgetTester tester) async {
    final AuthTokenStorage storage = await _signInAs('Owner', const <String>[]);
    final _Backend backend = _Backend();
    await tester.pumpWidget(_page(ShopRequestDetailScreen(requestId: 'req-1', branch: _branch, service: backend.service(storage))));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('request.decline')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('decline.confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Please give a reason'), findsOneWidget);
    expect(backend.requests.any((http.Request r) => r.url.path.endsWith('/decline')), isFalse);

    await tester.enterText(find.byKey(const Key('decline.reason')), 'Fully booked this week');
    await tester.tap(find.byKey(const Key('decline.confirm')));
    await tester.pumpAndSettle();
    final http.Request decline = backend.requests.lastWhere((http.Request r) => r.url.path.endsWith('/decline'));
    expect(jsonDecode(decline.body), <String, String>{'reason': 'Fully booked this week'});
    expect(find.text('Reason: Fully booked this week'), findsOneWidget);
  });

  testWidgets('a cashier (no order access) sees no action buttons', (WidgetTester tester) async {
    final AuthTokenStorage storage = await _signInAs('Cashier', const <String>['process:payments']);
    final _Backend backend = _Backend();
    await tester.pumpWidget(_page(ShopRequestDetailScreen(requestId: 'req-1', branch: _branch, service: backend.service(storage))));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('request.accept')), findsNothing);
    expect(find.byKey(const Key('request.decline')), findsNothing);
  });
}
