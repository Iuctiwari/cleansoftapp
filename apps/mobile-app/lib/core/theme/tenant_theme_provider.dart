import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

/// Exposes the current tenant's ThemeData, sourced from GET
/// /tenant/config/active (Phase 4) via TenantConfigClient/
/// TenantConfigBootstrapper — this class itself does no networking, it only
/// applies already-fetched JSON, so it can be unit-tested with zero HTTP.
///
/// CRITICAL — the whole point of this class: when the tenant has no custom
/// theme (isCustomized: false), when nothing has loaded yet, or when a load
/// fails, [lightTheme]/[darkTheme] return the EXACT SAME instances as
/// AppTheme.light/AppTheme.dark — not a copy, not a no-op copyWith, the
/// literal same object every existing screen already renders with. A tenant
/// with no theme set is therefore provably unchanged from today, by
/// construction, not just "close enough."
///
/// Known limitation, deliberately not addressed in this phase (would require
/// editing design_system/theme/app_theme.dart, which Phase 5's own guardrails
/// keep off-limits): AppTheme hardcodes AppColors.primary directly in some
/// component themes (e.g. ElevatedButtonTheme, BottomNavigationBarTheme)
/// rather than reading through colorScheme. This override recolors
/// colorScheme.primary/secondary (and primaryColor), which flows through to
/// any widget that reads Theme.of(context).colorScheme — but NOT to the
/// handful of widgets styled with the hardcoded AppColors.primary constant.
/// Full re-theming of those would be a deliberate follow-up, not this phase.
class TenantThemeProvider extends ChangeNotifier {
  bool _isCustomized = false;
  ThemeData? _lightOverride;
  ThemeData? _darkOverride;

  bool get isCustomized => _isCustomized;

  ThemeData get lightTheme =>
      _isCustomized && _lightOverride != null ? _lightOverride! : AppTheme.light;

  ThemeData get darkTheme =>
      _isCustomized && _darkOverride != null ? _darkOverride! : AppTheme.dark;

  /// Applies the `theme` object from a GET /tenant/config/active response
  /// (or null, e.g. on fetch failure — treated the same as "no theme set").
  void applyThemeJson(Map<String, dynamic>? theme) {
    if (theme == null || theme['isCustomized'] != true) {
      reset();
      return;
    }

    final Color? primary = _tryParseHex(theme['primaryColorHex'] as String?);
    final Color? secondary = _tryParseHex(theme['secondaryColorHex'] as String?);
    if (primary == null && secondary == null) {
      reset();
      return;
    }

    _lightOverride = _withOverride(AppTheme.light, primary, secondary);
    _darkOverride = _withOverride(AppTheme.dark, primary, secondary);
    _isCustomized = true;
    notifyListeners();
  }

  void reset() {
    if (!_isCustomized && _lightOverride == null && _darkOverride == null) {
      return; // already at the default state — avoid a redundant rebuild
    }
    _isCustomized = false;
    _lightOverride = null;
    _darkOverride = null;
    notifyListeners();
  }

  ThemeData _withOverride(ThemeData base, Color? primary, Color? secondary) {
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary ?? base.colorScheme.primary,
        secondary: secondary ?? base.colorScheme.secondary,
      ),
      primaryColor: primary ?? base.primaryColor,
    );
  }

  Color? _tryParseHex(String? hex) {
    if (hex == null) return null;
    final String cleaned = hex.trim();
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(cleaned)) return null;
    return Color(int.parse('FF${cleaned.substring(1)}', radix: 16));
  }
}
