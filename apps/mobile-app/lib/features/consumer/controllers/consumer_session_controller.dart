import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_session_storage.dart';

/// The signed-in customer, if any. Listened to by the router.
final class ConsumerSessionController extends ChangeNotifier {
  ConsumerSessionController({
    required ConsumerApiService api,
    required ConsumerSessionStorage storage,
  }) : _api = api,
       _storage = storage;

  final ConsumerApiService _api;
  final ConsumerSessionStorage _storage;
  ConsumerSession? _session;

  ConsumerSession? get session => _session;
  bool get isAuthenticated => _session != null;

  Future<void> restoreSession() async {
    _session = await _storage.read();
    notifyListeners();
  }

  /// Throws [ConsumerApiException]; code `auth.email_not_verified` means the
  /// email still needs its 6-digit code.
  Future<void> signIn({required String identifier, required String password}) async {
    _session = await _api.signIn(identifier: identifier, password: password);
    notifyListeners();
  }

  /// Runs while the session is still valid, just before signing out.
  Future<void> Function()? beforeSignOut;

  Future<void> signOut() async {
    try {
      await beforeSignOut?.call();
    } on Object {
      // Signing out must never be blocked by a notification problem.
    }
    await _api.signOut();
    _session = null;
    notifyListeners();
  }

  /// Called when an API call reports the session is gone.
  Future<void> handleSessionExpired() async {
    await _storage.clear();
    if (_session == null) return;
    _session = null;
    notifyListeners();
  }
}
