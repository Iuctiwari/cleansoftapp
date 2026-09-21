/**
 * Sourced directly from the Flutter app's current design system (verified
 * 2026-09-10, not guessed):
 *  - apps/mobile-app/lib/design_system/colors/app_colors.dart:17  (primary)
 *  - apps/mobile-app/lib/design_system/colors/app_colors.dart:29  (secondary)
 *  - apps/mobile-app/lib/app/app.dart:16-17                       (themeMode, title)
 *
 * A tenant with no TenantTheme record must render 100% identically to these
 * — zero visual change until a Company Admin explicitly sets a theme.
 *
 * accentColorHex has no field literally named "accent" in app_colors.dart.
 * Mapped to AppColors.info (aka primaryCyan, #0EA5E9) — the closest existing
 * third brand color today — confirmed with the user rather than guessed.
 *
 * logoUrl/bannerUrl have no current URL-based equivalent (the app uses
 * bundled local assets) — left unset, which the tenant-facing endpoint
 * exposes as undefined so a future consumer falls back to its bundled asset.
 */
export const DEFAULT_PRIMARY_COLOR_HEX = '#2563EB';
export const DEFAULT_SECONDARY_COLOR_HEX = '#7C3AED';
export const DEFAULT_ACCENT_COLOR_HEX = '#0EA5E9';
export const DEFAULT_DARK_THEME_ENABLED = false;
export const DEFAULT_APP_TITLE = 'Nexoraa CleanSoft';

export interface EffectiveTenantThemeValues {
  readonly primaryColorHex: string;
  readonly secondaryColorHex: string;
  readonly accentColorHex: string;
  readonly darkThemeEnabled: boolean;
  readonly customAppTitle: string;
  readonly logoUrl?: string;
  readonly bannerUrl?: string;
  readonly allowShopThemeOverride: boolean;
}

export const DEFAULT_TENANT_THEME: EffectiveTenantThemeValues = Object.freeze({
  primaryColorHex: DEFAULT_PRIMARY_COLOR_HEX,
  secondaryColorHex: DEFAULT_SECONDARY_COLOR_HEX,
  accentColorHex: DEFAULT_ACCENT_COLOR_HEX,
  darkThemeEnabled: DEFAULT_DARK_THEME_ENABLED,
  customAppTitle: DEFAULT_APP_TITLE,
  allowShopThemeOverride: false,
});
