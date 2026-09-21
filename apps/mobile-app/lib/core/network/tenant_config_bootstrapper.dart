import 'package:nexoraa_mobile/core/network/tenant_config_client.dart';
import 'package:nexoraa_mobile/core/permissions/module_access_provider.dart';
import 'package:nexoraa_mobile/core/theme/tenant_theme_provider.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';

/// Wires the EXISTING tenant/staff AuthenticationController to the two new
/// boot-time providers, without modifying AuthenticationController,
/// splash_controller.dart, or login_screen.dart — this listens to the
/// controller from the outside (it's a plain ChangeNotifier, already used
/// that way as GoRouter's own refreshListenable), rather than those files
/// being taught anything new about theme/module fetching.
///
/// Fetches GET /tenant/config/active ONCE per distinct tenantId becoming
/// authenticated (covers both a fresh sign-in and an already-valid session
/// restored at cold start), then pushes the single response into BOTH
/// providers — the "single boot-time call feeds both" design Phase 4 asked for.
abstract final class TenantConfigBootstrapper {
  static final TenantThemeProvider themeProvider = TenantThemeProvider();
  static final ModuleAccessProvider moduleAccessProvider = ModuleAccessProvider();
  static final TenantConfigClient _client = TenantConfigClient();

  static String? _lastLoadedTenantId;
  static bool _listening = false;

  /// Call once (see NexoraaApp.initState in app.dart). Idempotent.
  static void start() {
    if (_listening) return;
    _listening = true;
    AuthenticationDependencies.controller.addListener(_onAuthStateChanged);
    _onAuthStateChanged(); // handles an already-authenticated cold start
  }

  static void _onAuthStateChanged() {
    final controller = AuthenticationDependencies.controller;
    if (!controller.isAuthenticated) {
      if (_lastLoadedTenantId != null) {
        _lastLoadedTenantId = null;
        themeProvider.reset();
        moduleAccessProvider.reset();
      }
      return;
    }

    final String? tenantId = controller.session?.tenantId;
    if (tenantId == null || tenantId.isEmpty || tenantId == _lastLoadedTenantId) {
      return;
    }
    _lastLoadedTenantId = tenantId;
    _load();
  }

  static Future<void> _load() async {
    final TenantConfigFetchResult? result = await _client.fetchActiveConfig();
    if (result == null) return; // fail silently — keep current defaults
    themeProvider.applyThemeJson(result.theme);
    moduleAccessProvider.applyModuleKeysJson(result.enabledModuleKeys);
  }
}
