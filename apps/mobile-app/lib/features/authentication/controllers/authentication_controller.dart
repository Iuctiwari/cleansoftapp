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
  AuthenticationStatus _status = AuthenticationStatus.unknown;

  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthenticationStatus.authenticated;
  bool get isLoading => _status == AuthenticationStatus.authenticating;
  AuthenticationStatus get status => _status;

  /// Marks this local app session authenticated without calling the API.
  /// Only invoke after checking the development-only environment flag.
  void authenticateForDevelopmentBypass() {
    _errorMessage = null;
    _status = AuthenticationStatus.authenticated;
    notifyListeners();
  }

  Future<void> restoreSession() async {
    final bool authenticated = await _service.isAuthenticated();
    _status = authenticated
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
      await _service.signIn(identifier: identifier, password: password);
      _status = AuthenticationStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthenticationException catch (error) {
      _errorMessage = error.message;
    } on Exception {
      _errorMessage = 'Something went wrong. Please try again.';
    }

    _status = AuthenticationStatus.unauthenticated;
    notifyListeners();
    return false;
  }

  Future<void> signOut() async {
    await _service.signOut();
    _errorMessage = null;
    _status = AuthenticationStatus.unauthenticated;
    notifyListeners();
  }
}
