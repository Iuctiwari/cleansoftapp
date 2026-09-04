import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';

abstract interface class AuthenticationService {
  Future<AuthenticationSession?> restoreSession();

  Future<AuthenticationSession> signIn({
    required String identifier,
    required String password,
  });

  Future<void> signOut();

  Future<void> requestPasswordReset({
    required String identifier,
  });

  Future<void> confirmPasswordReset({
    required String identifier,
    required String otp,
    required String newPassword,
  });
}
