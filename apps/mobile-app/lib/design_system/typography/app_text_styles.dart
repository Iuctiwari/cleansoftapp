import 'package:flutter/material.dart';

import '../colors/app_colors.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'Inter';
  static const String monoFontFamily = 'JetBrains Mono';

  static const TextStyle displayLarge = TextStyle(
    color: AppColors.surface,
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1,
  );
  static const TextStyle displayMedium = TextStyle(
    color: AppColors.surface,
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -1,
  );
  static const TextStyle displaySmall = TextStyle(
    color: AppColors.surface,
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: -0.8,
  );
  static const TextStyle headingExtraLarge = TextStyle(
    color: AppColors.surface,
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static const TextStyle headingLarge = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
  );
  static const TextStyle headingMedium = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
  );
  static const TextStyle headingSmall = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
  );
  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.3,
  );
  static const TextStyle subtitle = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const TextStyle bodyLarge = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
  static const TextStyle bodySmall = TextStyle(
    color: AppColors.textMuted,
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle caption = TextStyle(
    color: AppColors.textMuted,
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle captionBold = TextStyle(
    color: AppColors.textMuted,
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  static const TextStyle label = TextStyle(
    color: AppColors.textSubtle,
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
  );
  static const TextStyle labelBold = TextStyle(
    color: AppColors.textSubtle,
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
  );
  static const TextStyle labelUppercase = TextStyle(
    color: AppColors.textSubtle,
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
  );
  static const TextStyle labelUppercaseSmall = TextStyle(
    color: AppColors.textSubtle,
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.8,
  );
  static const TextStyle micro = TextStyle(
    color: AppColors.textSubtle,
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -0.1,
  );
  static const TextStyle buttonMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: -0.1,
  );
  static const TextStyle buttonSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1,
  );
  static const TextStyle navigation = TextStyle(
    color: AppColors.textSubtle,
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1,
  );
  static const TextStyle navigationActive = TextStyle(
    color: AppColors.primary,
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1,
  );
  static const TextStyle badge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1,
    letterSpacing: 0.2,
  );
  static const TextStyle splashSubtitle = TextStyle(
    color: AppColors.whiteOverlay65,
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1,
    letterSpacing: 2.5,
  );

  static const TextTheme textTheme = TextTheme(
    displayLarge: displayLarge,
    displayMedium: displayMedium,
    displaySmall: displaySmall,
    headlineLarge: headingLarge,
    headlineMedium: headingMedium,
    headlineSmall: headingSmall,
    titleLarge: title,
    titleMedium: subtitle,
    titleSmall: bodyLarge,
    bodyLarge: bodyLarge,
    bodyMedium: bodyMedium,
    bodySmall: bodySmall,
    labelLarge: buttonMedium,
    labelMedium: captionBold,
    labelSmall: label,
  );

  static TextTheme textThemeFor(Brightness brightness) {
    if (brightness == Brightness.light) {
      return textTheme;
    }

    return textTheme.apply(
      bodyColor: AppColors.surface,
      displayColor: AppColors.surface,
      decorationColor: AppColors.surface,
    );
  }
}
