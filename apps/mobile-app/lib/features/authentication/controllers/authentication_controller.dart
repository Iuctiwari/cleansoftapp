import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/authentication_service.dart';

enum AuthenticationStatus {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
}

final class AuthenticationController extends ChangeNotifier {
  AuthenticationController({required AuthenticationService service})
    : _service = service;

  final AuthenticationService _service;
  String? _errorMessage;
  AuthenticationSession? _session;
  AuthenticationStatus _status = AuthenticationStatus.unknown;

  String? get errorMessage => _errorMessage;
  AuthenticationSession? get session => _session;
  bool get isAuthenticated => _status == AuthenticationStatus.authenticated;
  bool get isLoading => _status == AuthenticationStatus.authenticating;
  AuthenticationStatus get status => _status;

  Future<void> restoreSession() async {
    _session = await _service.restoreSession();
    _status = _session != null
        ? AuthenticationStatus.authenticated
        : AuthenticationStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    if (isLoading) return false;

    _errorMessage = null;
    _status = AuthenticationStatus.authenticating;
    notifyListeners();

    try {
      _session = await _service.signIn(
        identifier: identifier,
        password: password,
      );
      _status = AuthenticationStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
    } on Exception {
      _errorMessage = 'Something went wrong. Please try again.';
    }

    _status = AuthenticationStatus.unauthenticated;
    _session = null;
    notifyListeners();
    return false;
  }

  /// Runs while the session is still valid, just before signing out (stops
  /// push notifications for this account on this phone).
  Future<void> Function()? beforeSignOut;

  Future<void> signOut() async {
    try {
      await beforeSignOut?.call();
    } on Object {
      // Signing out must never be blocked by a notification problem.
    }
    await _service.signOut();
    _errorMessage = null;
    _session = null;
    _status = AuthenticationStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> requestPasswordReset({required String identifier}) async {
    _errorMessage = null;
    try {
      await _service.requestPasswordReset(identifier: identifier);
      return true;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
    } on Exception {
      _errorMessage = 'Something went wrong. Please try again.';
    }
    return false;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = null;
    try {
      await _service.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
    } on Exception {
      _errorMessage = 'Something went wrong. Please try again.';
    }
    return false;
  }

  Future<bool> confirmPasswordReset({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    _errorMessage = null;
    try {
      await _service.confirmPasswordReset(
        identifier: identifier,
        otp: otp,
        newPassword: newPassword,
      );
      return true;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
    } on Exception {
      _errorMessage = 'Something went wrong. Please try again.';
    }
    return false;
  }
}
