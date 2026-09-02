import 'package:flutter/material.dart';

@immutable
final class AppSemanticColor {
  const AppSemanticColor({required this.text, required this.background});

  final Color background;
  final Color text;
}

/// Canonical color palette extracted from the Nexoraa CleanSoft Figma export.
///
/// Semantic aliases reference a single canonical value so duplicate colors are
/// not redefined throughout the application.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primarySurface = Color(0xFFEFF6FF);
  static const Color primarySurfaceAlt = Color(0xFFF0F7FF);
  static const Color primaryBorder = Color(0xFFBFDBFE);
  static const Color primaryMuted = Color(0xFFDBEAFE);
  static const Color info = Color(0xFF0EA5E9);
  static const Color primaryCyan = info;
  static const Color infoSurface = Color(0xFFF0F9FF);

  // Secondary
  static const Color secondary = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFF8B5CF6);
  static const Color indigo = Color(0xFF6366F1);
  static const Color secondaryIndigo = indigo;
  static const Color secondarySurface = Color(0xFFFAF5FF);
  static const Color indigoSurface = Color(0xFFEEF2FF);
  static const Color secondaryBorder = indigoSurface;

  // Success
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color successDarker = Color(0xFF15803D);
  static const Color successSurface = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successSubtle = Color(0xFFDCFCE7);

  // Warning
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningDeep = Color(0xFFCA8A04);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color warningSurface = Color(0xFFFEFCE8);
  static const Color warningBorder = Color(0xFFFDE68A);
  static const Color warningText = Color(0xFF92400E);
  static const Color warningTextDeep = warningDark;

  // Error
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFEF4444);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFCA5A5);
  static const Color errorText = error;

  // Neutral
  static const Color ink = Color(0xFF0F172A);
  static const Color inkSoft = Color(0xFF111827);
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF334155);
  static const Color textBody = Color(0xFF374151);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSubtle = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Surfaces and borders
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color surfaceGray = surfaceMuted;
  static const Color surfaceDark = ink;
  static const Color surfaceDarker = Color(0xFF1E293B);
  static const Color surfaceBlack = Color(0xFF111111);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = surfaceMuted;
  static const Color divider = surfaceMuted;
  static const Color transparent = Color(0x00000000);

  // Semantic aliases
  static const Color card = surface;
  static const Color disabled = textDisabled;
  static const Color iconPrimary = textPrimary;
  static const Color iconSecondary = textMuted;
  static const Color iconBackgroundBlue = primarySurface;
  static const Color iconBackgroundGreen = successSurface;
  static const Color iconBackgroundPurple = secondarySurface;
  static const Color iconBackgroundYellow = warningSurface;
  static const Color iconBackgroundRed = errorSurface;
  static const Color iconBackgroundCyan = infoSurface;
  static const Color iconBackgroundIndigo = indigoSurface;
  static const Color iconBackgroundGray = surfaceMuted;
  static const Color iconBgBlue = iconBackgroundBlue;
  static const Color iconBgGreen = iconBackgroundGreen;
  static const Color iconBgPurple = iconBackgroundPurple;
  static const Color iconBgYellow = iconBackgroundYellow;
  static const Color iconBgRed = iconBackgroundRed;
  static const Color iconBgCyan = iconBackgroundCyan;
  static const Color iconBgIndigo = iconBackgroundIndigo;
  static const Color iconBgGray = iconBackgroundGray;
  static const Color statusReady = success;
  static const Color statusProcessing = primary;
  static const Color statusPending = warningDeep;
  static const Color statusCompleted = success;
  static const Color statusError = error;
  static const Color statusPurple = secondary;
  static const Color availabilityAvailable = successLight;
  static const Color availabilityBusy = warning;
  static const Color availabilityBreak = warningOrange;
  static const Color availabilityOffline = textSubtle;

  // Black overlays and shadows
  static const Color blackOverlay04 = Color(0x0A000000);
  static const Color blackOverlay05 = Color(0x0D000000);
  static const Color blackOverlay06 = Color(0x0F000000);
  static const Color blackOverlay10 = Color(0x1A000000);
  static const Color blackOverlay20 = Color(0x33000000);
  static const Color blackOverlay35 = Color(0x59000000);
  static const Color scrimLight = blackOverlay05;
  static const Color scrimMedium = blackOverlay10;
  static const Color scrimDark = blackOverlay35;
  static const Color overlay = blackOverlay35;
  static const Color scrim = blackOverlay35;

  // White overlays
  static const Color whiteOverlay05 = Color(0x0DFFFFFF);
  static const Color whiteOverlay06 = Color(0x0FFFFFFF);
  static const Color whiteOverlay07 = Color(0x12FFFFFF);
  static const Color whiteOverlay08 = Color(0x14FFFFFF);
  static const Color whiteOverlay15 = Color(0x26FFFFFF);
  static const Color whiteOverlay18 = Color(0x2EFFFFFF);
  static const Color whiteOverlay20 = Color(0x33FFFFFF);
  static const Color whiteOverlay25 = Color(0x40FFFFFF);
  static const Color whiteOverlay30 = Color(0x4DFFFFFF);
  static const Color whiteOverlay35 = Color(0x59FFFFFF);
  static const Color whiteOverlay40 = Color(0x66FFFFFF);
  static const Color whiteOverlay50 = Color(0x80FFFFFF);
  static const Color whiteOverlay55 = Color(0x8CFFFFFF);
  static const Color whiteOverlay60 = Color(0x99FFFFFF);
  static const Color whiteOverlay65 = Color(0xA6FFFFFF);
  static const Color whiteOverlay70 = Color(0xB3FFFFFF);
  static const Color whiteOverlay80 = Color(0xCCFFFFFF);
  static const Color overlayLight = whiteOverlay18;
  static const Color overlayMedium = whiteOverlay25;
  static const Color overlayWhite = whiteOverlay08;

  // Brand overlays
  static const Color primaryOverlay00 = Color(0x002563EB);
  static const Color primaryOverlay15 = Color(0x262563EB);
  static const Color primaryOverlay25 = Color(0x402563EB);
  static const Color primaryOverlay45 = Color(0x732563EB);
  static const Color primaryLightOverlay30 = Color(0x4D3B82F6);
  static const Color successOverlay15 = Color(0x2610B981);
}

abstract final class SemanticColors {
  static const AppSemanticColor statusReady = AppSemanticColor(
    text: AppColors.statusReady,
    background: AppColors.successSurface,
  );
  static const AppSemanticColor statusProcessing = AppSemanticColor(
    text: Color(0xFFEA580C),
    background: Color(0xFFFFF7ED),
  );
  static const AppSemanticColor statusPending = AppSemanticColor(
    text: AppColors.primary,
    background: AppColors.primarySurface,
  );
  static const AppSemanticColor statusCompleted = AppSemanticColor(
    text: AppColors.statusCompleted,
    background: AppColors.successSurface,
  );
  static const AppSemanticColor statusError = AppSemanticColor(
    text: AppColors.statusError,
    background: AppColors.errorSurface,
  );
  static const AppSemanticColor statusPurple = AppSemanticColor(
    text: Color(0xFF7C3AED),
    background: Color(0xFFF5F3FF),
  );
  static const AppSemanticColor statusBlack = AppSemanticColor(
    text: Color(0xFF0F172A),
    background: Color(0xFFF1F5F9),
  );
}
