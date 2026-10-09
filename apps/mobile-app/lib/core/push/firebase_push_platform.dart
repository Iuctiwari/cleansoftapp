import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nexoraa_mobile/core/push/push_platform.dart';

/// Android notification channel the server's pushes use (see the manifest).
const String kPushChannelId = 'nexoraa_default';

PushPayload _payloadOf(RemoteMessage message) => PushPayload(
  title: message.notification?.title ?? message.data['title']?.toString() ?? '',
  body: message.notification?.body ?? message.data['body']?.toString() ?? '',
  data: message.data.map((String key, Object? value) => MapEntry<String, String>(key, '$value')),
);

/// Firebase Cloud Messaging + a local notification for pushes that arrive
/// while the app is open.
final class FirebasePushPlatform implements PushPlatform {
  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final StreamController<PushPayload> _tapped = StreamController<PushPayload>.broadcast();
  PushPayload? _launched;

  @override
  Future<void> initialize() async {
    // Uses android/app/google-services.json; throws if it is missing.
    await Firebase.initializeApp();

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final PushPayload? payload = _decode(response.payload);
        if (payload != null) _tapped.add(payload);
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            kPushChannelId,
            'Nexoraa notifications',
            description: 'Online requests, order tasks and updates',
            importance: Importance.high,
          ),
        );

    // Tapping a push while the app is in the background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) => _tapped.add(_payloadOf(m)));
    final RemoteMessage? initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _launched = _payloadOf(initial);
  }

  @override
  Future<bool> requestPermission() async {
    final NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() => FirebaseMessaging.instance.getToken();

  @override
  Stream<String> get tokenRefreshed => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<PushPayload> get arrivedInForeground => FirebaseMessaging.onMessage.map(_payloadOf);

  @override
  Stream<PushPayload> get tapped => _tapped.stream;

  @override
  Future<PushPayload?> launchedFromNotification() async {
    final PushPayload? launched = _launched;
    _launched = null;
    return launched;
  }

  @override
  Future<void> showWhileOpen(PushPayload payload) async {
    await _local.show(
      id: payload.hashCode & 0x7fffffff,
      title: payload.title,
      body: payload.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          kPushChannelId,
          'Nexoraa notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(<String, Object>{
        'title': payload.title,
        'body': payload.body,
        'data': payload.data,
      }),
    );
  }

  @override
  Future<void> forgetToken() => FirebaseMessaging.instance.deleteToken();

  PushPayload? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
      return PushPayload(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        data: (json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{})
            .map((String k, dynamic v) => MapEntry<String, String>(k, '$v')),
      );
    } on Object {
      return null;
    }
  }
}
