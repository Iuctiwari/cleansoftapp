import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';

abstract final class AppFonts {
  static const String primary = 'Inter';
  static const String mono = 'JetBrains Mono';
}

abstract final class AppFontSizes {
  static const double xs = 10;
  static const double xxs = 11;
  static const double sm = 12;
  static const double md = 13;
  static const double base = 14;
  static const double lg = 15;
  static const double xl = 16;
  static const double xxl = 17;
  static const double h4 = 18;
  static const double h3 = 20;
  static const double h2 = 22;
  static const double h1 = 24;
  static const double display3 = 28;
  static const double display2 = 30;
  static const double display1 = 32;
}

abstract final class AppFontWeights {
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
}

abstract final class AppLetterSpacing {
  static const double tight3 = -1;
  static const double tight2 = -0.8;
  static const double tight1 = -0.5;
  static const double tight = -0.4;
  static const double snug = -0.3;
  static const double normal = 0;
  static const double badge = 0.2;
  static const double button = -0.1;
  static const double label = 0.5;
  static const double label2 = 0.8;
  static const double label3 = 1;
  static const double label4 = 2.5;
}

abstract final class AppLineHeights {
  static const double compact = 1.1;
  static const double tight = 1.2;
  static const double normal = 1.5;
  static const double relaxed = 1.6;
  static const double loose = 1.7;
}

abstract final class AppTextStyles {
  static const String fontFamily = AppFonts.primary;
  static const String monoFontFamily = AppFonts.mono;

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
  static const TextStyle inputLabel = TextStyle(
    color: AppColors.textBody,
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
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
  static const TextStyle headerSubtitle = TextStyle(
    color: AppColors.whiteOverlay70,
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
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
