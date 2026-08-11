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
  static const String _tenantIdKey = 'auth.tenant_id';
  static const String _tenantSlugKey = 'auth.tenant_slug';
  static const String _ownerUserIdKey = 'auth.owner_user_id';
  static const String _ownerNameKey = 'auth.owner_name';
  static const String _ownerEmailKey = 'auth.owner_email';
  static const String _businessNameKey = 'auth.business_name';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _accessExpiryKey),
      _storage.delete(key: _refreshExpiryKey),
      _storage.delete(key: _tenantIdKey),
      _storage.delete(key: _tenantSlugKey),
      _storage.delete(key: _ownerUserIdKey),
      _storage.delete(key: _ownerNameKey),
      _storage.delete(key: _ownerEmailKey),
      _storage.delete(key: _businessNameKey),
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
      tenantId: values[_tenantIdKey],
      tenantSlug: values[_tenantSlugKey],
      ownerUserId: values[_ownerUserIdKey],
      ownerName: values[_ownerNameKey],
      ownerEmail: values[_ownerEmailKey],
      businessName: values[_businessNameKey],
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
    await _writeOptional(_tenantIdKey, session.tenantId);
    await _writeOptional(_tenantSlugKey, session.tenantSlug);
    await _writeOptional(_ownerUserIdKey, session.ownerUserId);
    await _writeOptional(_ownerNameKey, session.ownerName);
    await _writeOptional(_ownerEmailKey, session.ownerEmail);
    await _writeOptional(_businessNameKey, session.businessName);
  }

  Future<void> _writeOptional(String key, String? value) {
    if (value == null || value.isEmpty) return _storage.delete(key: key);
    return _storage.write(key: key, value: value);
  }
}
