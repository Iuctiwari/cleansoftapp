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
  static const String _roleCodeKey = 'auth.role_code';

  final FlutterSecureStorage _storage;
  static AuthenticationSession? _cachedSession;

  // Web (IndexedDB) is async and needs more time than native secure storage
  static const Duration _operationTimeout = Duration(seconds: 3);

  @override
  Future<void> clear() async {
    _cachedSession = null;
    try {
      await _storage.deleteAll().timeout(_operationTimeout);
    } catch (_) {
      // Fallback to individual deletes if deleteAll is not supported
      for (final String key in <String>[
        _accessTokenKey,
        _refreshTokenKey,
        _accessExpiryKey,
        _refreshExpiryKey,
        _tenantIdKey,
        _tenantSlugKey,
        _ownerUserIdKey,
        _ownerNameKey,
        _ownerEmailKey,
        _businessNameKey,
        _roleCodeKey,
      ]) {
        try {
          await _storage.delete(key: key).timeout(_operationTimeout);
        } catch (_) {
          // Ignore platform storage errors
        }
      }
    }
  }

  @override
  Future<AuthenticationSession?> read() async {
    try {
      final Map<String, String> values = await _storage
          .readAll()
          .timeout(_operationTimeout);
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
        return _cachedSession;
      }

      final AuthenticationSession session = AuthenticationSession(
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
        roleCode: values[_roleCodeKey] ?? 'tenant_owner',
      );
      _cachedSession = session;
      return session;
    } catch (_) {
      return _cachedSession;
    }
  }

  @override
  Future<void> write(AuthenticationSession session) async {
    _cachedSession = session;
    try {
      await _storage
          .write(key: _refreshTokenKey, value: session.refreshToken)
          .timeout(_operationTimeout);
      await _storage
          .write(
            key: _accessExpiryKey,
            value: session.accessTokenExpiresAt.toUtc().toIso8601String(),
          )
          .timeout(_operationTimeout);
      await _storage
          .write(
            key: _refreshExpiryKey,
            value: session.refreshTokenExpiresAt.toUtc().toIso8601String(),
          )
          .timeout(_operationTimeout);
      await _storage
          .write(key: _accessTokenKey, value: session.accessToken)
          .timeout(_operationTimeout);
      await _writeOptional(_tenantIdKey, session.tenantId);
      await _writeOptional(_tenantSlugKey, session.tenantSlug);
      await _writeOptional(_ownerUserIdKey, session.ownerUserId);
      await _writeOptional(_ownerNameKey, session.ownerName);
      await _writeOptional(_ownerEmailKey, session.ownerEmail);
      await _writeOptional(_businessNameKey, session.businessName);
      await _writeOptional(_roleCodeKey, session.roleCode);
    } catch (_) {
      // Ignore storage write errors to allow app to continue
    }
  }

  Future<void> _writeOptional(String key, String? value) async {
    try {
      if (value == null || value.isEmpty) {
        await _storage.delete(key: key).timeout(_operationTimeout);
      } else {
        await _storage.write(key: key, value: value).timeout(_operationTimeout);
      }
    } catch (_) {
      // Ignore storage write errors
    }
  }
}
