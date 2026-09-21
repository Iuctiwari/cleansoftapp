import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';

/// Result of GET /tenant/config/active (platform-admin-service, Phase 4) —
/// the single boot-time call that feeds BOTH TenantThemeProvider and
/// ModuleAccessProvider, per Phase 4's design ("shouldn't need two separate
/// calls later"). This client owns that one call; the two providers only
/// apply the parts of the response they each care about.
class TenantConfigFetchResult {
  const TenantConfigFetchResult({required this.theme, required this.enabledModuleKeys});

  final Map<String, dynamic>? theme;
  final List<String> enabledModuleKeys;
}

/// Uses the EXISTING tenant/staff AuthTokenStorage (AuthenticationDependencies)
/// — this is the tenant-facing app boot path, never CompanyAdminTokenStorage.
class TenantConfigClient {
  TenantConfigClient({AuthTokenStorage? tokenStorage, http.Client? client, String? baseUrl})
    : _tokenStorage = tokenStorage ?? AuthenticationDependencies.tokenStorage,
      _client = client ?? http.Client(),
      _baseUri = _buildBaseUri(
        baseUrl ??
            BackendEnvironment.resolveBase(
              _environment('PLATFORM_ADMIN_API_BASE_URL', 'http://10.0.2.2:3015/api'),
              'RENDER_PLATFORM_ADMIN_API_BASE_URL',
            ),
      );

  static const Duration _timeout = Duration(seconds: 10);

  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final Uri _baseUri;

  /// Returns null on ANY failure (no session, network error, bad response,
  /// unparsable body) — callers must treat null as "keep current defaults,"
  /// never as an error to surface to the tenant. A theming/module-gating
  /// hiccup must never block or visibly break the tenant-facing app.
  Future<TenantConfigFetchResult?> fetchActiveConfig() async {
    try {
      final AuthenticationSession? session = await _tokenStorage.read();
      if (session == null || session.accessToken.isEmpty) return null;

      final Uri uri = _baseUri.replace(path: '${_baseUri.path}/tenant/config/active');
      final http.Response response = await _client
          .get(
            uri,
            headers: <String, String>{
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
              if (session.branchId != null && session.branchId!.isNotEmpty)
                'x-branch-id': session.branchId!,
            },
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      if (response.body.isEmpty) return null;

      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic>? data =
          decoded is Map<String, dynamic> && decoded.containsKey('data')
          ? decoded['data'] as Map<String, dynamic>?
          : decoded as Map<String, dynamic>?;
      if (data == null) return null;

      return TenantConfigFetchResult(
        theme: data['theme'] as Map<String, dynamic>?,
        enabledModuleKeys: (data['enabledModuleKeys'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
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
}
