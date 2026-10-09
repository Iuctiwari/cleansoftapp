import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/push/push_api.dart';
import 'package:nexoraa_mobile/core/push/push_destination.dart';
import 'package:nexoraa_mobile/core/push/push_platform.dart';
import 'package:nexoraa_mobile/core/push/push_registrar.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';

/// A phone with no Firebase: records what the app asks of it.
class FakePlatform implements PushPlatform {
  FakePlatform({this.failToStart = false, this.allow = true, this.firstToken = 'token-1'});

  final bool failToStart;
  final bool allow;
  String firstToken;
  int permissionAsks = 0;
  int forgotten = 0;
  final List<PushPayload> shown = <PushPayload>[];
  PushPayload? launched;
  final StreamController<String> refreshed = StreamController<String>.broadcast();
  final StreamController<PushPayload> foreground = StreamController<PushPayload>.broadcast();
  final StreamController<PushPayload> taps = StreamController<PushPayload>.broadcast();

  @override
  Future<void> initialize() async {
    if (failToStart) throw StateError('Firebase is not configured');
  }

  @override
  Future<bool> requestPermission() async {
    permissionAsks++;
    return allow;
  }

  @override
  Future<String?> token() async => firstToken;

  @override
  Stream<String> get tokenRefreshed => refreshed.stream;

  @override
  Stream<PushPayload> get arrivedInForeground => foreground.stream;

  @override
  Stream<PushPayload> get tapped => taps.stream;

  @override
  Future<PushPayload?> launchedFromNotification() async => launched;

  @override
  Future<void> showWhileOpen(PushPayload payload) async => shown.add(payload);

  @override
  Future<void> forgetToken() async => forgotten++;
}

class Session extends ChangeNotifier {
  bool signedIn = false;

  void set(bool value) {
    signedIn = value;
    notifyListeners();
  }
}

class Harness {
  Harness({FakePlatform? platform, String branchId = 'branch-1', this.past = true})
    : platform = platform ?? FakePlatform() {
    api = PushApi(
      baseUri: () => Uri.parse('http://notify.test/api'),
      authorization: (PushAccount account) async => 'Bearer ${account.name}-token',
      shopBranchId: () => branchId,
      client: MockClient((http.Request request) async {
        calls.add(request);
        return http.Response('', 204);
      }),
    );
    registrar = PushRegistrar(
      platform: this.platform,
      api: api,
      shopSession: shop,
      shopSignedIn: () => shop.signedIn,
      consumerSession: consumer,
      consumerSignedIn: () => consumer.signedIn,
      open: opened.add,
      pastSplash: () => past,
    );
  }

  final FakePlatform platform;
  final Session shop = Session();
  final Session consumer = Session();
  final List<http.Request> calls = <http.Request>[];
  final List<PushDestination> opened = <PushDestination>[];
  bool past;
  late final PushApi api;
  late final PushRegistrar registrar;

  Map<String, dynamic> body(int index) => jsonDecode(calls[index].body) as Map<String, dynamic>;
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  group('PushRegistrar', () {
    test('without Firebase the app carries on and nothing is registered', () async {
      final Harness h = Harness(platform: FakePlatform(failToStart: true));

      await h.registrar.start();
      h.shop.set(true);
      await settle();

      expect(h.registrar.isReady, isFalse);
      expect(h.calls, isEmpty);
      expect(h.platform.permissionAsks, 0);
    });

    test('signing in as a shop user asks permission once and registers the phone for that branch', () async {
      final Harness h = Harness();
      await h.registrar.start();
      expect(h.calls, isEmpty, reason: 'nobody is signed in yet, so no permission prompt either');
      expect(h.platform.permissionAsks, 0);

      h.shop.set(true);
      await settle();

      expect(h.calls, hasLength(1));
      expect(h.calls.single.url.toString(), 'http://notify.test/api/v1/push/devices');
      expect(h.calls.single.headers['authorization'], 'Bearer shop-token');
      expect(h.calls.single.headers['x-branch-id'], 'branch-1');
      expect(h.body(0), <String, Object>{'token': 'token-1', 'platform': 'android'});

      h.shop.set(true); // an unrelated session change does not register again
      await settle();
      expect(h.calls, hasLength(1));
      expect(h.platform.permissionAsks, 1);
    });

    test('a customer signing in registers through the customer endpoint, with no branch', () async {
      final Harness h = Harness();
      await h.registrar.start();

      h.consumer.set(true);
      await settle();

      expect(h.calls.single.url.toString(), 'http://notify.test/api/v1/push/consumer/devices');
      expect(h.calls.single.headers['authorization'], 'Bearer consumer-token');
      expect(h.calls.single.headers.containsKey('x-branch-id'), isFalse);
    });

    test('if notifications are refused, the phone is not registered', () async {
      final Harness h = Harness(platform: FakePlatform(allow: false));
      await h.registrar.start();

      h.shop.set(true);
      await settle();
      h.shop.set(true);
      await settle();

      expect(h.calls, isEmpty);
      expect(h.platform.permissionAsks, 1, reason: 'asked once, not on every change');
    });

    test('a new token from Firebase is registered again', () async {
      final Harness h = Harness();
      await h.registrar.start();
      h.shop.set(true);
      await settle();

      h.platform.refreshed.add('token-2');
      await settle();

      expect(h.calls, hasLength(2));
      expect(h.body(1)['token'], 'token-2');
    });

    test('a started app that is already signed in registers straight away', () async {
      final Harness h = Harness();
      h.consumer.signedIn = true;

      await h.registrar.start();

      expect(h.calls, hasLength(1));
    });

    test('signing out stops pushes for the account and forgets the token when nobody else is signed in', () async {
      final Harness h = Harness();
      await h.registrar.start();
      h.shop.set(true);
      await settle();

      await h.registrar.unregister(PushAccount.shop);

      expect(h.calls.last.url.toString(), 'http://notify.test/api/v1/push/devices/unregister');
      expect(jsonDecode(h.calls.last.body), <String, String>{'token': 'token-1'});
      expect(h.platform.forgotten, 1);
    });

    test('with both kinds of account on the phone, signing out of one keeps the token for the other', () async {
      final Harness h = Harness();
      await h.registrar.start();
      h.shop.set(true);
      h.consumer.set(true);
      await settle();

      await h.registrar.unregister(PushAccount.shop);

      expect(h.calls.last.url.path, '/api/v1/push/devices/unregister');
      expect(h.platform.forgotten, 0);
    });

    test('after signing out and in again the phone is registered again', () async {
      final Harness h = Harness();
      await h.registrar.start();
      h.shop.set(true);
      await settle();
      await h.registrar.unregister(PushAccount.shop);
      h.shop.set(false);
      await settle();
      h.platform.firstToken = 'token-new';

      h.shop.set(true);
      await settle();

      expect(h.calls.where((http.Request r) => r.url.path.endsWith('/devices')), hasLength(2));
      expect(h.body(h.calls.length - 1)['token'], 'token-new');
    });

    test('a push that arrives while the app is open is shown and announced to screens', () async {
      final Harness h = Harness();
      await h.registrar.start();
      final List<PushPayload> seen = <PushPayload>[];
      h.registrar.arrivals.listen(seen.add);
      const PushPayload push = PushPayload(title: 'New online request', body: 'Riya', data: <String, String>{'type': 'online_request'});

      h.platform.foreground.add(push);
      await settle();

      expect(h.platform.shown, <PushPayload>[push]);
      expect(seen, <PushPayload>[push]);
    });

    test('tapping a notification opens its screen', () async {
      final Harness h = Harness();
      await h.registrar.start();

      h.platform.taps.add(const PushPayload(title: 't', body: 'b', data: <String, String>{'type': 'online_request', 'branchId': 'branch-9'}));
      await settle();

      expect(h.opened.single.routeName, AppRouteNames.onlineRequests);
      expect((h.opened.single.extra! as ShopBranchArgs).branchId, 'branch-9');
    });

    test('a notification that launched the app opens only after the start-up screen is done', () async {
      final FakePlatform platform = FakePlatform()
        ..launched = const PushPayload(title: 't', body: 'b', data: <String, String>{'type': 'WorkerAssigned', 'orderId': 'o1'});
      final Harness h = Harness(platform: platform, past: false);

      await h.registrar.start();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(h.opened, isEmpty);

      h.past = true;
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(h.opened.single.routeName, AppRouteNames.notifications);
    });

    test('a failing server never throws into the app', () async {
      final Harness h = Harness();
      final PushApi broken = PushApi(
        baseUri: () => Uri.parse('http://notify.test/api'),
        authorization: (_) async => 'Bearer x',
        shopBranchId: () => null,
        client: MockClient((_) async => throw StateError('offline')),
      );

      expect(await broken.register(PushAccount.shop, 'token-1'), isFalse);
      expect(await broken.unregister(PushAccount.consumer, 'token-1'), isFalse);
      await h.registrar.start();
    });
  });

  group('destinationFor', () {
    PushPayload push(Map<String, String> data) => PushPayload(title: 't', body: 'b', data: data);

    test('a new online request opens the shop inbox for that branch', () {
      final PushDestination d = destinationFor(push(<String, String>{'type': 'online_request', 'requestId': 'r1', 'branchId': 'b2'}));

      expect(d.routeName, AppRouteNames.onlineRequests);
      expect((d.extra! as ShopBranchArgs).branchId, 'b2');
    });

    test('an update to a customer’s request opens that request', () {
      for (final String type in <String>['request_accepted', 'request_declined', 'request_completed']) {
        final PushDestination d = destinationFor(push(<String, String>{'type': type, 'requestId': 'r7'}));

        expect(d, const PushDestination(AppRouteNames.consumerRequest, pathParameters: <String, String>{'requestId': 'r7'}));
      }
    });

    test('a customer push with no request id opens the My requests tab', () {
      expect(destinationFor(push(<String, String>{'type': 'request_accepted'})), const PushDestination(AppRouteNames.consumerHome, extra: 1));
    });

    test('order and worker-task notifications, and anything unknown, open the notifications list', () {
      for (final Map<String, String> data in <Map<String, String>>[
        <String, String>{'type': 'WorkerAssigned', 'orderId': 'o1'},
        <String, String>{'type': 'WorkerDeclineApproved'},
        <String, String>{'type': 'something_new'},
        <String, String>{},
      ]) {
        expect(destinationFor(push(data)), const PushDestination(AppRouteNames.notifications));
      }
    });
  });
}
