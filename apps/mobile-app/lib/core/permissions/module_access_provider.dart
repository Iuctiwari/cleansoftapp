import 'package:flutter/foundation.dart';

/// Exposes whether a module is enabled for the current tenant, sourced from
/// GET /tenant/config/active's `enabledModuleKeys` (Phase 4) via
/// TenantConfigBootstrapper. No networking here — only applies already-fetched
/// data, so it's independently unit-testable.
///
/// NOT wired to gate or hide any nav item or screen in this phase — every
/// current screen stays exactly as visible as it is today. isModuleEnabled()
/// exists for later, deliberate gating work; nothing calls it yet.
///
/// Fails open before load / on load failure, matching ModuleGuard's own
/// Phase 2 rule exactly: a tenant with no data yet must not appear to have
/// every module disabled.
class ModuleAccessProvider extends ChangeNotifier {
  List<String> _enabledModuleKeys = const <String>[];
  bool _hasLoaded = false;

  bool get hasLoaded => _hasLoaded;
  List<String> get enabledModuleKeys => _enabledModuleKeys;

  bool isModuleEnabled(String moduleKey) {
    if (!_hasLoaded) return true;
    return _enabledModuleKeys.contains(moduleKey);
  }

  /// Applies the `enabledModuleKeys` list from a GET /tenant/config/active
  /// response (or null, e.g. on fetch failure — treated as "not loaded yet",
  /// which keeps isModuleEnabled() failing open).
  void applyModuleKeysJson(List<String>? enabledModuleKeys) {
    if (enabledModuleKeys == null) {
      reset();
      return;
    }
    _enabledModuleKeys = enabledModuleKeys;
    _hasLoaded = true;
    notifyListeners();
  }

  void reset() {
    if (!_hasLoaded && _enabledModuleKeys.isEmpty) return;
    _enabledModuleKeys = const <String>[];
    _hasLoaded = false;
    notifyListeners();
  }
}
