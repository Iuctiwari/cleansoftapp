import 'package:flutter/widgets.dart';

import '../colors/app_colors.dart';

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
}
