/// What a push carries, whichever way it reached the app.
class PushPayload {
  const PushPayload({required this.title, required this.body, this.data = const <String, String>{}});

  final String title;
  final String body;

  /// Ids the app uses to open the right screen, e.g. {type: online_request, requestId: …}.
  final Map<String, String> data;
}

/// The phone side of push notifications. The real implementation is Firebase
/// (see firebase_push_platform.dart); tests use a fake, so nothing else in the
/// app depends on Firebase.
abstract interface class PushPlatform {
  /// Starts Firebase and the notification channel. Throws if Firebase is not
  /// configured, so the app can carry on without pushes.
  Future<void> initialize();

  /// Asks the person to allow notifications; false when they say no.
  Future<bool> requestPermission();

  /// This phone's push token, or null if the phone cannot receive pushes.
  Future<String?> token();

  /// A new token (Firebase rotates them now and then).
  Stream<String> get tokenRefreshed;

  /// A push that arrived while the app is open.
  Stream<PushPayload> get arrivedInForeground;

  /// A notification the person tapped (app in the background or closed).
  Stream<PushPayload> get tapped;

  /// The notification that started the app, if it was opened by tapping one.
  Future<PushPayload?> launchedFromNotification();

  /// Shows a heads-up notification (the system shows nothing while the app is open).
  Future<void> showWhileOpen(PushPayload payload);

  /// Invalidates this phone's token, so nothing more arrives after sign out.
  Future<void> forgetToken();
}
