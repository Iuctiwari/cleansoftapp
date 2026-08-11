import 'package:flutter/widgets.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';
import 'package:nexoraa_mobile/design_system/durations/app_durations.dart';

abstract final class AppGradients {
  static const LinearGradient primaryHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.primaryDark, AppColors.primary],
  );
  static const LinearGradient primarySplash = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      AppColors.primaryDark,
      AppColors.primary,
      AppColors.primaryLight,
    ],
    stops: <double>[0, 0.5, 1],
  );
  static const LinearGradient primaryAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.primary, AppColors.primaryLight],
  );
  static const LinearGradient primaryFab = primaryAction;
  static const LinearGradient primaryBar = LinearGradient(
    colors: <Color>[AppColors.primary, AppColors.primaryLight],
  );
  static const LinearGradient darkCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.surfaceDark, AppColors.surfaceDarker],
  );
  static const LinearGradient successCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.successDark, AppColors.successLight],
  );
  static const LinearGradient warningCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.warning, AppColors.warningDark],
  );
  static const LinearGradient secondaryCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.secondary, AppColors.secondaryLight],
  );
  static const LinearGradient revenueChart = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[AppColors.primaryOverlay15, AppColors.primaryOverlay00],
  );
  static const LinearGradient shimmer = LinearGradient(
    colors: <Color>[
      AppColors.surfaceGray,
      AppColors.border,
      AppColors.surfaceGray,
    ],
    stops: <double>[0.25, 0.5, 0.75],
  );
}

abstract final class AppShimmer {
  static const LinearGradient gradient = AppGradients.shimmer;
  static const double backgroundWidthFactor = 2;
  static const Duration duration = AppDurations.shimmer;
  static const Curve curve = AppCurves.linear;
}
