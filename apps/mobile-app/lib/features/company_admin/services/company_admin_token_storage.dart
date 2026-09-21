import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';

/// Storage for the Company Admin JWT (Phase 1), deliberately SEPARATE from
/// AuthTokenStorage's tenant/staff session (auth_token_storage.dart). A
/// device could be signed into both a tenant account and an admin account at
/// once — these must never collide or overwrite each other, so every key
/// here uses a distinct `company_admin.` prefix instead of `auth.`.
abstract interface class CompanyAdminTokenStorage {
  Future<void> clear();

  Future<AdminSession?> read();

  Future<void> write(AdminSession session);
}

final class SecureCompanyAdminTokenStorage implements CompanyAdminTokenStorage {
  SecureCompanyAdminTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _accessTokenKey = 'company_admin.access_token';
  static const String _refreshTokenKey = 'company_admin.refresh_token';
  static const String _accessExpiryKey = 'company_admin.access_token_expires_at';

  final FlutterSecureStorage _storage;
  static AdminSession? _cachedSession;

  static const Duration _operationTimeout = Duration(seconds: 3);

  @override
  Future<void> clear() async {
    _cachedSession = null;
    for (final String key in <String>[
      _accessTokenKey,
      _refreshTokenKey,
      _accessExpiryKey,
    ]) {
      try {
        await _storage.delete(key: key).timeout(_operationTimeout);
      } catch (_) {
        // Ignore platform storage errors
      }
    }
  }

  @override
  Future<AdminSession?> read() async {
    try {
      final String? accessToken = await _storage
          .read(key: _accessTokenKey)
          .timeout(_operationTimeout);
      final String? refreshToken = await _storage
          .read(key: _refreshTokenKey)
          .timeout(_operationTimeout);
      final DateTime? accessExpiry = DateTime.tryParse(
        await _storage.read(key: _accessExpiryKey).timeout(_operationTimeout) ??
            '',
      );

      if (accessToken == null ||
          accessToken.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty ||
          accessExpiry == null) {
        return _cachedSession;
      }

      final AdminSession session = AdminSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        accessTokenExpiresAt: accessExpiry,
      );
      _cachedSession = session;
      return session;
    } catch (_) {
      return _cachedSession;
    }
  }

  @override
  Future<void> write(AdminSession session) async {
    _cachedSession = session;
    try {
      await _storage
          .write(key: _accessTokenKey, value: session.accessToken)
          .timeout(_operationTimeout);
      await _storage
          .write(key: _refreshTokenKey, value: session.refreshToken)
          .timeout(_operationTimeout);
      await _storage
          .write(
            key: _accessExpiryKey,
            value: session.accessTokenExpiresAt.toUtc().toIso8601String(),
          )
          .timeout(_operationTimeout);
    } catch (_) {
      // Ignore storage write errors to allow app to continue
    }
  }
}
