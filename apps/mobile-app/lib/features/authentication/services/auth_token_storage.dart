import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';

abstract interface class AuthTokenStorage {
  Future<void> clear();

  Future<AuthenticationSession?> read();

  Future<void> write(AuthenticationSession session);
}

final class SecureAuthTokenStorage implements AuthTokenStorage {
  SecureAuthTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'auth.access_token';
  static const String _refreshTokenKey = 'auth.refresh_token';
  static const String _accessExpiryKey = 'auth.access_token_expires_at';
  static const String _refreshExpiryKey = 'auth.refresh_token_expires_at';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _accessExpiryKey),
      _storage.delete(key: _refreshExpiryKey),
    ]);
  }

  @override
  Future<AuthenticationSession?> read() async {
    final Map<String, String> values = await _storage.readAll();
    final String? accessToken = values[_accessTokenKey];
    final String? refreshToken = values[_refreshTokenKey];
    final DateTime? accessExpiry = DateTime.tryParse(
      values[_accessExpiryKey] ?? '',
    );
    final DateTime? refreshExpiry = DateTime.tryParse(
      values[_refreshExpiryKey] ?? '',
    );

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        accessExpiry == null ||
        refreshExpiry == null) {
      return null;
    }

    return AuthenticationSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessExpiry,
      refreshTokenExpiresAt: refreshExpiry,
    );
  }

  @override
  Future<void> write(AuthenticationSession session) async {
    await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    await _storage.write(
      key: _accessExpiryKey,
      value: session.accessTokenExpiresAt.toUtc().toIso8601String(),
    );
    await _storage.write(
      key: _refreshExpiryKey,
      value: session.refreshTokenExpiresAt.toUtc().toIso8601String(),
    );
    await _storage.write(key: _accessTokenKey, value: session.accessToken);
  }
}
