import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/core/push/push_api.dart';
import 'package:nexoraa_mobile/core/push/push_destination.dart';
import 'package:nexoraa_mobile/core/push/push_platform.dart';

/// Keeps this phone registered for pushes while someone is signed in, shows
/// pushes that arrive while the app is open, and opens the right screen when
/// a notification is tapped.
///
/// Pushes are a bonus: if Firebase is not set up, or permission is refused,
/// the app works exactly as before.
class PushRegistrar {
  PushRegistrar({
    required PushPlatform platform,
    required PushApi api,
    required Listenable shopSession,
    required bool Function() shopSignedIn,
    required Listenable consumerSession,
    required bool Function() consumerSignedIn,
    required void Function(PushDestination destination) open,
    required bool Function() pastSplash,
  }) : _platform = platform,
       _api = api,
       _shopSession = shopSession,
       _shopSignedIn = shopSignedIn,
       _consumerSession = consumerSession,
       _consumerSignedIn = consumerSignedIn,
       _open = open,
       _pastSplash = pastSplash;

  final PushPlatform _platform;
  final PushApi _api;
  final Listenable _shopSession;
  final bool Function() _shopSignedIn;
  final Listenable _consumerSession;
  final bool Function() _consumerSignedIn;
  final void Function(PushDestination destination) _open;
  final bool Function() _pastSplash;

  final StreamController<PushPayload> _arrivals = StreamController<PushPayload>.broadcast();
  final Set<PushAccount> _registered = <PushAccount>{};
  bool _ready = false;
  bool? _allowed;
  String? _token;
  Future<void> _syncing = Future<void>.value();

  /// True once Firebase started; false when pushes are unavailable.
  bool get isReady => _ready;

  /// Every push that arrived while the app was open (screens refresh on these).
  Stream<PushPayload> get arrivals => _arrivals.stream;

  Future<void> start() async {
    try {
      await _platform.initialize();
    } on Object catch (error) {
      debugPrint('Push notifications unavailable: $error');
      return;
    }
    _ready = true;

    _platform.tokenRefreshed.listen((String token) {
      _token = token;
      _registered.clear(); // a new token has to be registered again
      unawaited(sync());
    });
    _platform.arrivedInForeground.listen((PushPayload payload) {
      _arrivals.add(payload);
      unawaited(_platform.showWhileOpen(payload));
    });
    _platform.tapped.listen((PushPayload payload) => _open(destinationFor(payload)));
    _shopSession.addListener(_onSessionChanged);
    _consumerSession.addListener(_onSessionChanged);

    final PushPayload? launched = await _platform.launchedFromNotification();
    if (launched != null) unawaited(_openAfterSplash(launched));
    await sync();
  }

  /// Registers this phone for whoever is signed in. Safe to call any time.
  Future<void> sync() {
    // One at a time, so a quick sign-in/sign-out cannot interleave.
    return _syncing = _syncing.then((_) => _sync()).catchError((Object _) {});
  }

  /// Call right before signing out (the session is still valid): stops pushes
  /// for this account on this phone.
  Future<void> unregister(PushAccount account) async {
    if (!_ready) return;
    final String? token = _token;
    _registered.remove(account);
    if (token == null) return;
    await _api.unregister(account, token);
    // Nothing more should arrive for the signed-out person, even if the
    // server missed the request.
    // (Unless the other kind of account is still signed in on this phone.)
    if (_otherAccountSignedOut(account)) {
      await _platform.forgetToken().catchError((Object _) {});
      _token = null;
    }
  }

  bool _otherAccountSignedOut(PushAccount account) =>
      account == PushAccount.shop ? !_consumerSignedIn() : !_shopSignedIn();

  void _onSessionChanged() => unawaited(sync());

  Future<void> _sync() async {
    if (!_ready) return;
    final bool shop = _shopSignedIn();
    final bool consumer = _consumerSignedIn();
    if (!shop) _registered.remove(PushAccount.shop);
    if (!consumer) _registered.remove(PushAccount.consumer);
    if (!shop && !consumer) return;

    _allowed ??= await _platform.requestPermission();
    if (_allowed != true) return;
    _token ??= await _platform.token();
    final String? token = _token;
    if (token == null) return;

    if (shop && !_registered.contains(PushAccount.shop)) {
      if (await _api.register(PushAccount.shop, token)) _registered.add(PushAccount.shop);
    }
    if (consumer && !_registered.contains(PushAccount.consumer)) {
      if (await _api.register(PushAccount.consumer, token)) _registered.add(PushAccount.consumer);
    }
  }

  /// A notification that launched the app: wait for the start-up screen to
  /// finish, otherwise it would send the person to the dashboard afterwards.
  Future<void> _openAfterSplash(PushPayload payload) async {
    for (int i = 0; i < 40 && !_pastSplash(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    _open(destinationFor(payload));
  }
}
