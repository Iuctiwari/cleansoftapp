import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Why a phone code could not be sent or checked, in words the person can read.
class PhoneVerificationException implements Exception {
  const PhoneVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One text message that was sent: the person types the code, and this turns it into
/// a Firebase ID token the server can check.
abstract class PhoneCodeSession {
  Future<String> confirm(String code);
}

/// Sends a one-time code to a phone number through Firebase (real SMS, or the fixed
/// code of a Firebase test number). Behind an interface so tests never touch Firebase.
abstract class PhoneVerifier {
  Future<PhoneCodeSession> sendCode(String phoneE164);
}

abstract final class PhoneVerification {
  static PhoneVerifier verifier = FirebasePhoneVerifier();
}

class FirebasePhoneVerifier implements PhoneVerifier {
  @override
  Future<PhoneCodeSession> sendCode(String phoneE164) async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final Completer<PhoneCodeSession> sent = Completer<PhoneCodeSession>();
      PhoneAuthCredential? automatic;
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneE164,
        timeout: const Duration(seconds: 60),
        // Some phones read the SMS themselves; the typed code is then optional.
        verificationCompleted: (PhoneAuthCredential credential) => automatic = credential,
        verificationFailed: (FirebaseAuthException error) {
          if (!sent.isCompleted) sent.completeError(PhoneVerificationException(_explain(error)));
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!sent.isCompleted) sent.complete(_FirebaseSession(verificationId, () => automatic));
        },
        codeAutoRetrievalTimeout: (String _) {},
      );
      return await sent.future.timeout(const Duration(seconds: 75));
    } on TimeoutException {
      throw const PhoneVerificationException('The code took too long to send. Please try again.');
    } on FirebaseAuthException catch (error) {
      throw PhoneVerificationException(_explain(error));
    }
  }
}

class _FirebaseSession implements PhoneCodeSession {
  _FirebaseSession(this._verificationId, this._automatic);

  final String _verificationId;
  final PhoneAuthCredential? Function() _automatic;

  @override
  Future<String> confirm(String code) async {
    try {
      final PhoneAuthCredential credential = code.trim().isEmpty && _automatic() != null
          ? _automatic()!
          : PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: code.trim());
      final UserCredential signedIn = await FirebaseAuth.instance.signInWithCredential(credential);
      final String? token = await signedIn.user?.getIdToken();
      // Only the proof of the number is needed; the app keeps its own sign-in.
      await FirebaseAuth.instance.signOut();
      if (token == null) throw const PhoneVerificationException('Could not verify this number. Please try again.');
      return token;
    } on FirebaseAuthException catch (error) {
      throw PhoneVerificationException(_explain(error));
    }
  }
}

String _explain(FirebaseAuthException error) => switch (error.code) {
  'invalid-phone-number' => 'That mobile number is not valid.',
  'invalid-verification-code' => 'That code is not correct. Check it and try again.',
  'session-expired' || 'code-expired' => 'That code has expired. Send a new one.',
  'too-many-requests' => 'Too many tries. Please wait a few minutes and try again.',
  'quota-exceeded' => 'SMS limit reached for now. Try the email code instead.',
  'network-request-failed' => 'No internet connection. Please try again.',
  'operation-not-allowed' => 'Phone verification is not switched on yet. Use the email code.',
  _ => error.message ?? 'Could not verify this number. Please try again.',
};
