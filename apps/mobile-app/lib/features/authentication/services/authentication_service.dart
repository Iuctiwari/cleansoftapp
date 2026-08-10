import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';

abstract interface class AuthenticationService {
  Future<bool> isAuthenticated();

  Future<AuthenticationSession> signIn({
    required String identifier,
    required String password,
  });

  Future<void> signOut();
}
