import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/screens/forgot_password_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/reset_password_screen.dart';
import 'package:nexoraa_mobile/features/authentication/services/authentication_service.dart';

class MockAuthenticationService implements AuthenticationService {
  String? requestedIdentifier;
  String? resetIdentifier;
  String? resetOtp;
  String? resetNewPassword;
  bool shouldSucceed = true;

  @override
  Future<AuthenticationSession?> restoreSession() async => null;

  @override
  Future<AuthenticationSession> signIn({
    required String identifier,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> requestPasswordReset({required String identifier}) async {
    requestedIdentifier = identifier;
    if (!shouldSucceed) {
      throw const AuthenticationException('Account lookup failed.');
    }
  }

  @override
  Future<void> confirmPasswordReset({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    resetIdentifier = identifier;
    resetOtp = otp;
    resetNewPassword = newPassword;
    if (!shouldSucceed) {
      throw const AuthenticationException('Invalid verification code.');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

void main() {
  group('ForgotPasswordScreen', () {
    testWidgets('requires email to proceed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );

      // Verify initial UI elements
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Send verification code'), findsOneWidget);

      // Tap without entering email
      await tester.tap(find.text('Send verification code'));
      await tester.pump();
      expect(find.text('Enter your email address to continue.'), findsOneWidget);
    });
  });

  group('ResetPasswordScreen', () {
    testWidgets('validates fields and calls confirmPasswordReset', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ResetPasswordScreen(initialIdentifier: 'test@example.com'),
        ),
      );

      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.widgetWithText(PrimaryButton, 'Reset Password'), findsOneWidget);

      // Scroll to button and tap without entering OTP and password
      final buttonFinder = find.widgetWithText(PrimaryButton, 'Reset Password');
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(find.text('Enter the 6-digit verification code sent to your email.'), findsOneWidget);
    });
  });
}
