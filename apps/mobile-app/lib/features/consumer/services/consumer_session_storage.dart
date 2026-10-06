import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';

/// Where the customer session is kept. Separate keys from the shop login.
abstract interface class ConsumerSessionStorage {
  Future<ConsumerSession?> read();

  Future<void> write(ConsumerSession session);

  Future<void> clear();
}

/// Secure storage for the customer session that also refreshes an expiring
/// access token, so every customer API call gets a valid token from [read].
final class SecureConsumerSessionStorage implements ConsumerSessionStorage {
  SecureConsumerSessionStorage({
    required Uri Function() authBaseUri,
    FlutterSecureStorage? storage,
    http.Client? client,
  }) : _authBaseUri = authBaseUri,
       _storage = storage ?? const FlutterSecureStorage(),
       _client = client ?? http.Client();

  static const String _key = 'consumer.session';
  static const Duration _refreshSafetyMargin = Duration(seconds: 30);
  static const Duration _timeout = Duration(seconds: 15);

  final Uri Function() _authBaseUri;
  final FlutterSecureStorage _storage;
  final http.Client _client;
  ConsumerSession? _cached;
  Future<ConsumerSession?>? _refreshing;

  @override
  Future<ConsumerSession?> read() async {
    final ConsumerSession? session = _cached ?? await _load();
    if (session == null) return null;

    final DateTime now = DateTime.now().toUtc();
    if (!now.isBefore(session.refreshTokenExpiresAt)) {
      await clear();
      return null;
    }
    if (now.isBefore(session.accessTokenExpiresAt.subtract(_refreshSafetyMargin))) {
      return session;
    }
    // Several calls at once share one refresh (refresh tokens are single-use).
    return _refreshing ??= _refresh(session).whenComplete(() => _refreshing = null);
  }

  @override
  Future<void> write(ConsumerSession session) async {
    _cached = session;
    await _storage.write(key: _key, value: jsonEncode(session.toStorage()));
  }

  @override
  Future<void> clear() async {
    _cached = null;
    try {
      await _storage.delete(key: _key);
    } on Object {
      // Nothing stored is the same as signed out.
    }
  }

  Future<ConsumerSession?> _load() async {
    try {
      final String? raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _cached = ConsumerSession.fromStorage(decoded);
    } on Object {
      return null;
    }
  }

  Future<ConsumerSession?> _refresh(ConsumerSession current) async {
    try {
      final Uri base = _authBaseUri();
      final Uri uri = base.replace(path: '${base.path.replaceFirst(RegExp(r'/+$'), '')}/v1/auth/refresh');
      final http.Response response = await _client
          .post(
            uri,
            headers: const <String, String>{
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode(<String, String>{'refreshToken': current.refreshToken}),
          )
          .timeout(_timeout);

      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        // Revoked or reused refresh token: the customer must sign in again.
        await clear();
        return null;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) return current;

      final Map<String, dynamic> data =
          (jsonDecode(response.body) as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final ConsumerSession refreshed = current.withTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        accessTokenExpiresAt: DateTime.parse(data['accessTokenExpiresAtUtc'] as String).toUtc(),
        refreshTokenExpiresAt: DateTime.parse(data['refreshTokenExpiresAtUtc'] as String).toUtc(),
      );
      await write(refreshed);
      return refreshed;
    } on Object {
      // Offline: keep the current token; the request itself will report the problem.
      return current;
    }
  }
}

/// In-memory storage for tests.
final class MemoryConsumerSessionStorage implements ConsumerSessionStorage {
  ConsumerSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<ConsumerSession?> read() async => session;

  @override
  Future<void> write(ConsumerSession value) async => session = value;
}
