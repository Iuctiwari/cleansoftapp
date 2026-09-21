import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Picks each deployed (Render) backend service when it's reachable and
/// falls back to that service's local URL otherwise.
///
/// Each backend service is deployed to Render separately and gets its own
/// `RENDER_<SERVICE>_API_BASE_URL` — there is no single shared gateway host,
/// so every `*ApiService` probes and resolves its OWN key independently
/// (one service being asleep/cold must never affect any other).
///
/// Render's free tier spins a service down after ~15 minutes of inactivity,
/// so a cold instance can be unreachable for a while. Rather than requiring
/// every developer to edit `.env` back and forth, [resolve] probes every
/// configured `RENDER_*_API_BASE_URL` once per app run (in parallel) and
/// every `*ApiService` asks [resolveBase] with its own key to know which
/// host to use.
abstract final class BackendEnvironment {
  static final Map<String, bool> _reachable = <String, bool>{};

  static String? _renderUrlFor(String renderEnvKey) {
    if (!dotenv.isInitialized) return null;
    final String? value = dotenv.env[renderEnvKey]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Whether the last probe found [renderEnvKey]'s Render backend reachable.
  static bool isReachable(String renderEnvKey) => _reachable[renderEnvKey] ?? false;

  /// Probes every `RENDER_*_API_BASE_URL` configured in `.env`, in parallel,
  /// and caches each result for the rest of the app session. Safe to call
  /// more than once; keys that were already probed are skipped.
  static Future<void> resolve({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (!dotenv.isInitialized) return;

    final Iterable<String> keys = dotenv.env.keys.where(
      (String key) =>
          key.startsWith('RENDER_') &&
          key.endsWith('_API_BASE_URL') &&
          !_reachable.containsKey(key),
    );
    await Future.wait(keys.map((String key) => _probe(key, timeout)));
  }

  static Future<void> _probe(String renderEnvKey, Duration timeout) async {
    final String? base = _renderUrlFor(renderEnvKey);
    if (base == null) {
      _reachable[renderEnvKey] = false;
      return;
    }

    try {
      final Uri probeUri = Uri.parse(
        base.endsWith('/') ? base : '$base/',
      ).resolve('v1/health/live');
      final http.Response response = await http
          .get(probeUri)
          .timeout(timeout);
      _reachable[renderEnvKey] = response.statusCode < 500;
    } on Object {
      _reachable[renderEnvKey] = false;
    }
  }

  /// Returns the Render base URL for [renderEnvKey] when it's reachable,
  /// otherwise [local].
  ///
  /// Call [resolve] once at startup before relying on this; until then it
  /// behaves as if every Render backend was unreachable and returns [local].
  static String resolveBase(String local, String renderEnvKey) {
    if (!isReachable(renderEnvKey)) return local;
    return _renderUrlFor(renderEnvKey) ?? local;
  }
}
