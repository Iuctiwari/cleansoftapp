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

  /// Changes the signed-in user's password. The backend signs out the user's
  /// other devices.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
