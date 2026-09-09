import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Picks the deployed (Render) backend when it's reachable and falls back
/// to the local backend URLs otherwise.
///
/// Render's free tier spins the service down after ~15 minutes of
/// inactivity, so a cold instance can be unreachable for a while. Rather
/// than requiring every developer to edit `.env` back and forth, [resolve]
/// probes the Render URL once per app run and every `*ApiService` asks
/// [resolveBase] which host to use.
abstract final class BackendEnvironment {
  static bool _useRender = false;
  static bool _resolved = false;

  /// Whether the last probe found the Render backend reachable.
  static bool get useRender => _useRender;

  static String? get renderBaseUrl {
    if (!dotenv.isInitialized) return null;
    final String? value = dotenv.env['RENDER_API_BASE_URL']?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Probes the Render backend once and caches the result for the rest of
  /// the app session. Safe to call more than once; only the first call
  /// performs the network probe.
  static Future<void> resolve({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (_resolved) return;
    _resolved = true;

    final String? base = renderBaseUrl;
    if (base == null) {
      _useRender = false;
      return;
    }

    try {
      final Uri probeUri = Uri.parse(
        base.endsWith('/') ? base : '$base/',
      ).resolve('v1/health/live');
      final http.Response response = await http
          .get(probeUri)
          .timeout(timeout);
      _useRender = response.statusCode < 500;
    } on Object {
      _useRender = false;
    }
  }

  /// Returns the Render base URL when it's reachable, otherwise [local].
  ///
  /// Call [resolve] once at startup before relying on this; until then it
  /// behaves as if Render was unreachable and returns [local].
  static String resolveBase(String local) {
    if (!_useRender) return local;
    return renderBaseUrl ?? local;
  }
}
