import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';

abstract interface class AuthTokenStorage {
  Future<void> clear();

  Future<AuthenticationSession?> read();

  Future<void> write(AuthenticationSession session);
}

final class SecureAuthTokenStorage implements AuthTokenStorage {
  SecureAuthTokenStorage({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  // Every *ApiService calls read() right before building request headers, so
  // this is the one place that can transparently refresh an expired access
  // token for the whole app — without it, every screen independently starts
  // failing with 401 "session expired" the moment the 1-hour access token
  // passes, even though the (much longer-lived) refresh token is still good.
  static const Duration _refreshSafetyMargin = Duration(seconds: 30);
  static const Duration _refreshTimeout = Duration(seconds: 15);

  Uri get _refreshUri {
    final base = BackendEnvironment.resolveBase(
      _environment('API_BASE_URL', 'http://127.0.0.1:3001/api'),
      'RENDER_AUTH_API_BASE_URL',
    ).trimRight().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$base/auth/refresh');
  }

  static String _environment(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }

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
  static const String _permissionsKey = 'auth.permissions';
  static const String _branchIdKey = 'auth.branch_id';
  static const String _branchNameKey = 'auth.branch_name';

  final FlutterSecureStorage _storage;
  final http.Client _client;
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
        _permissionsKey,
        _branchIdKey,
        _branchNameKey,
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
      final Map<String, String> values = await _storage.readAll().timeout(
        _operationTimeout,
      );
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
        permissions:
            (jsonDecode(values[_permissionsKey] ?? '[]') as List<dynamic>)
                .whereType<String>()
                .toList(growable: false),
        branchId: values[_branchIdKey],
        branchName: values[_branchNameKey],
      );
      _cachedSession = session;

      final now = DateTime.now().toUtc();
      if (!now.isBefore(accessExpiry.subtract(_refreshSafetyMargin)) &&
          now.isBefore(refreshExpiry)) {
        final AuthenticationSession? refreshed = await _refresh(session);
        if (refreshed != null) return refreshed;
        // Refresh either failed transiently (stale session kept, caller's
        // request will fail naturally) or the refresh token was rejected
        // and _refresh already cleared storage (_cachedSession is null).
        return _cachedSession;
      }

      return session;
    } catch (_) {
      return _cachedSession;
    }
  }

  /// Exchanges the refresh token for a new access/refresh pair, preserving
  /// every other field (tenant/owner/permissions) from [current]. Returns
  /// null on any failure; a hard rejection (expired/revoked refresh token)
  /// also clears the stored session so the app doesn't keep silently
  /// retrying a refresh token that can never work again.
  Future<AuthenticationSession?> _refresh(AuthenticationSession current) async {
    http.Response response;
    try {
      response = await _client
          .post(
            _refreshUri,
            headers: {HttpHeaders.contentTypeHeader: 'application/json'},
            body: jsonEncode({'refreshToken': current.refreshToken}),
          )
          .timeout(_refreshTimeout);
    } catch (_) {
      return null;
    }

    if (response.statusCode != 200) {
      await clear();
      return null;
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;

      final String? newAccessToken = data['accessToken'] as String?;
      final String? newRefreshToken = data['refreshToken'] as String?;
      final DateTime? newAccessExpiry = DateTime.tryParse(
        data['accessTokenExpiresAtUtc'] as String? ?? '',
      );
      final DateTime? newRefreshExpiry = DateTime.tryParse(
        data['refreshTokenExpiresAtUtc'] as String? ?? '',
      );
      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty ||
          newAccessExpiry == null ||
          newRefreshExpiry == null) {
        return null;
      }

      final AuthenticationSession refreshed = AuthenticationSession(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        accessTokenExpiresAt: newAccessExpiry,
        refreshTokenExpiresAt: newRefreshExpiry,
        tenantId: current.tenantId,
        tenantSlug: current.tenantSlug,
        ownerUserId: current.ownerUserId,
        ownerName: current.ownerName,
        ownerEmail: current.ownerEmail,
        businessName: current.businessName,
        roleCode: current.roleCode,
        permissions: current.permissions,
        branchId: current.branchId,
        branchName: current.branchName,
      );
      await write(refreshed);
      return refreshed;
    } catch (_) {
      return null;
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
      await _writeOptional(_permissionsKey, jsonEncode(session.permissions));
      await _writeOptional(_branchIdKey, session.branchId);
      await _writeOptional(_branchNameKey, session.branchName);
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
