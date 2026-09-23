import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
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
  SecureCompanyAdminTokenStorage({FlutterSecureStorage? storage, http.Client? client})
    : _storage = storage ?? const FlutterSecureStorage(),
      _client = client ?? http.Client();

  static const String _accessTokenKey = 'company_admin.access_token';
  static const String _refreshTokenKey = 'company_admin.refresh_token';
  static const String _accessExpiryKey = 'company_admin.access_token_expires_at';

  final FlutterSecureStorage _storage;
  final http.Client _client;
  static AdminSession? _cachedSession;

  static const Duration _operationTimeout = Duration(seconds: 3);
  // Every CompanyAdminApiService call reads the session right before
  // building headers, so this is the one place that can transparently
  // refresh an expired access token instead of every screen independently
  // showing "Admin session expired" the moment the access token passes.
  static const Duration _refreshSafetyMargin = Duration(seconds: 30);
  static const Duration _refreshTimeout = Duration(seconds: 15);

  Uri get _refreshUri {
    final Uri base = _buildBaseUri(
      BackendEnvironment.resolveBase(
        _environment('PLATFORM_ADMIN_API_BASE_URL', 'http://10.0.2.2:3015/api'),
        'RENDER_PLATFORM_ADMIN_API_BASE_URL',
      ),
    );
    return base.replace(path: '${base.path}/platform-admin/auth/refresh');
  }

  static Uri _buildBaseUri(String rawUrl) {
    final Uri parsed = Uri.parse(rawUrl.trim());
    final List<String> segments = parsed.pathSegments.where((s) => s.isNotEmpty).toList();
    if (!segments.contains('api')) segments.add('api');
    if (!segments.contains('v1')) segments.add('v1');
    return parsed.replace(pathSegments: segments);
  }

  static String _environment(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final String? value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }

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

      final DateTime now = DateTime.now().toUtc();
      if (!now.isBefore(accessExpiry.subtract(_refreshSafetyMargin))) {
        final AdminSession? refreshed = await _refresh(session);
        if (refreshed != null) return refreshed;
        // Transient network failure keeps the stale cached session (caller's
        // request will fail naturally); a hard rejection already cleared it.
        return _cachedSession;
      }

      return session;
    } catch (_) {
      return _cachedSession;
    }
  }

  /// Exchanges the refresh token for a new pair. Returns null on any
  /// failure; a hard rejection (expired/revoked refresh token) also clears
  /// the stored session so it doesn't keep silently retrying.
  Future<AdminSession?> _refresh(AdminSession current) async {
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
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic>? data = decoded is Map<String, dynamic>
          ? (decoded['data'] is Map<String, dynamic> ? decoded['data'] as Map<String, dynamic> : decoded)
          : null;
      if (data == null) return null;

      final AdminSession refreshed = AdminSession.fromLoginResponse(data);
      if (refreshed.accessToken.isEmpty || refreshed.refreshToken.isEmpty) return null;

      await write(refreshed);
      return refreshed;
    } catch (_) {
      return null;
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
