import 'package:flutter/material.dart';

import '../borders/app_borders.dart';
import '../colors/app_colors.dart';
import '../radius/app_radius.dart';
import '../spacing/app_spacing.dart';
import '../typography/app_text_styles.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color surface = isDark ? AppColors.surfaceDarker : AppColors.surface;
    final Color background = isDark
        ? AppColors.surfaceDark
        : AppColors.background;
    final Color onSurface = isDark ? AppColors.surface : AppColors.textPrimary;
    final Color outline = isDark ? AppColors.textSecondary : AppColors.border;
    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: isDark
          ? AppColors.primaryDark
          : AppColors.primarySurface,
      onPrimaryContainer: isDark ? AppColors.surface : AppColors.primaryDark,
      secondary: AppColors.secondary,
      onSecondary: AppColors.surface,
      secondaryContainer: isDark
          ? AppColors.secondary
          : AppColors.secondarySurface,
      onSecondaryContainer: isDark ? AppColors.surface : AppColors.secondary,
      error: AppColors.error,
      onError: AppColors.surface,
      errorContainer: AppColors.errorSurface,
      onErrorContainer: AppColors.error,
      surface: surface,
      onSurface: onSurface,
      outline: outline,
      outlineVariant: isDark ? AppColors.textSecondary : AppColors.borderSubtle,
      shadow: AppColors.blackOverlay20,
      scrim: AppColors.blackOverlay35,
      inverseSurface: isDark ? AppColors.surface : AppColors.surfaceDark,
      onInverseSurface: isDark ? AppColors.textPrimary : AppColors.surface,
      inversePrimary: AppColors.primaryLight,
    );

    final TextTheme textTheme = AppTextStyles.textThemeFor(brightness);
    final BorderSide inputBorderSide = isDark
        ? const BorderSide(
            color: AppColors.textSecondary,
            width: AppBorderWidths.thin,
          )
        : AppBorders.inputDefaultSide;

    return ThemeData(
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        centerTitle: false,
        elevation: 0,
        foregroundColor: onSurface,
        iconTheme: IconThemeData(color: onSurface, size: 24),
        scrolledUnderElevation: 0,
        surfaceTintColor: AppColors.transparent,
        titleTextStyle: AppTextStyles.title.copyWith(color: onSurface),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 0,
        selectedIconTheme: const IconThemeData(size: 24),
        selectedItemColor: AppColors.primary,
        selectedLabelStyle: AppTextStyles.navigationActive,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        unselectedIconTheme: const IconThemeData(size: 24),
        unselectedItemColor: AppColors.textSubtle,
        unselectedLabelStyle: AppTextStyles.navigation,
      ),
      brightness: brightness,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.blackOverlay06,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: isDark
              ? const BorderSide(color: AppColors.textSecondary)
              : AppBorders.cardDefaultSide,
        ),
        surfaceTintColor: AppColors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: const WidgetStatePropertyAll<Color>(AppColors.surface),
        fillColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textDisabled;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.transparent;
        }),
        side: inputBorderSide,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        checkmarkColor: AppColors.primary,
        color: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? AppColors.primaryDark : AppColors.primarySurface;
          }
          return surface;
        }),
        disabledColor: AppColors.surfaceMuted,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        labelStyle: AppTextStyles.badge.copyWith(color: onSurface),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        selectedColor: isDark
            ? AppColors.primaryDark
            : AppColors.primarySurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.chipRadius,
          side: inputBorderSide,
        ),
        side: inputBorderSide,
      ),
      colorScheme: colorScheme,
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.dialogRadius,
        ),
        surfaceTintColor: AppColors.transparent,
        titleTextStyle: AppTextStyles.headingSmall.copyWith(color: onSurface),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.textSecondary : AppColors.divider,
        space: 1,
        thickness: AppBorderWidths.hairline,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.primary,
          ),
          elevation: const WidgetStatePropertyAll<double>(0),
          foregroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.surface,
          ),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(0, AppSpacing.displayLarge),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            AppSpacing.buttonMediumInsets,
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            AppTextStyles.buttonMedium,
          ),
        ),
      ),
      fontFamily: AppTextStyles.fontFamily,
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: inputBorderSide,
        ),
        contentPadding: AppSpacing.inputInsets,
        disabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(
            color: AppColors.textDisabled,
            width: AppBorderWidths.thin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: inputBorderSide,
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: AppBorders.inputErrorSide,
        ),
        errorStyle: AppTextStyles.caption.copyWith(color: AppColors.error),
        filled: true,
        fillColor: surface,
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: AppBorders.inputFocusedSide,
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: AppBorders.inputErrorSide,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSubtle,
        ),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: isDark ? AppColors.textDisabled : AppColors.textBody,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll<Color>(onSurface),
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(0, AppSpacing.displayLarge),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            AppSpacing.buttonMediumInsets,
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          side: WidgetStatePropertyAll<BorderSide>(inputBorderSide),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            AppTextStyles.buttonMedium,
          ),
        ),
      ),
      scaffoldBackgroundColor: background,
      snackBarTheme: SnackBarThemeData(
        actionTextColor: AppColors.primaryLight,
        backgroundColor: isDark ? AppColors.surface : AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimary : AppColors.surface,
        ),
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.inputRadius,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.surface;
          }
          return AppColors.textSubtle;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceMuted;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.primary,
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            AppSpacing.buttonSmallInsets,
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            AppTextStyles.buttonMedium,
          ),
        ),
      ),
      textTheme: textTheme,
      useMaterial3: true,
    );
  }
}
