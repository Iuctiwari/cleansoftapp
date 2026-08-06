import 'package:flutter/widgets.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';

@immutable
final class AppDashedBorderToken {
  const AppDashedBorderToken({required this.color, required this.width});

  final Color color;
  final double width;
}

abstract final class AppBorderWidths {
  static const double hairline = 1;
  static const double thin = 1.5;
  static const double medium = 2;
  static const double thick = 3;
}

abstract final class AppBorders {
  static const BorderSide noneSide = BorderSide.none;
  static const Border none = Border();
  static const BorderSide cardDefaultSide = BorderSide(
    color: AppColors.borderSubtle,
    width: AppBorderWidths.hairline,
  );
  static const BorderSide cardElevatedSide = BorderSide(
    color: AppColors.border,
    width: AppBorderWidths.hairline,
  );
  static const BorderSide inputDefaultSide = BorderSide(
    color: AppColors.border,
    width: AppBorderWidths.thin,
  );
  static const BorderSide inputFocusedSide = BorderSide(
    color: AppColors.primary,
    width: AppBorderWidths.thin,
  );
  static const BorderSide inputErrorSide = BorderSide(
    color: AppColors.error,
    width: AppBorderWidths.thin,
  );
  static const BorderSide chipActiveSide = BorderSide(
    color: AppColors.primary,
    width: AppBorderWidths.medium,
  );
  static const BorderSide chipDefaultSide = inputDefaultSide;
  static const BorderSide buttonOutlineSide = inputDefaultSide;
  static const BorderSide toggleSide = BorderSide(
    color: AppColors.surface,
    width: AppBorderWidths.medium,
  );
  static const BorderSide sectionDividerSide = cardDefaultSide;
  static const BorderSide totalDividerSide = inputDefaultSide;
  static const BorderSide frameOuterSide = BorderSide(
    color: AppColors.blackOverlay10,
    width: AppBorderWidths.hairline,
  );
  static const BorderSide successSide = BorderSide(
    color: AppColors.successBorder,
    width: AppBorderWidths.thin,
  );
  static const BorderSide warningSide = BorderSide(
    color: AppColors.warningBorder,
    width: AppBorderWidths.hairline,
  );
  static const BorderSide errorSide = BorderSide(
    color: AppColors.errorBorder,
    width: AppBorderWidths.thin,
  );
  static const BorderSide primarySide = BorderSide(
    color: AppColors.primaryBorder,
    width: AppBorderWidths.hairline,
  );

  static const Border cardDefault = Border.fromBorderSide(cardDefaultSide);
  static const Border cardElevated = Border.fromBorderSide(cardElevatedSide);
  static const Border inputDefault = Border.fromBorderSide(inputDefaultSide);
  static const Border inputFocused = Border.fromBorderSide(inputFocusedSide);
  static const Border inputError = Border.fromBorderSide(inputErrorSide);
  static const Border chipActive = Border.fromBorderSide(chipActiveSide);
  static const Border chipDefault = Border.fromBorderSide(chipDefaultSide);
  static const Border buttonOutline = Border.fromBorderSide(buttonOutlineSide);
  static const Border toggle = Border.fromBorderSide(toggleSide);
  static const Border successCard = Border.fromBorderSide(successSide);
  static const Border warningCard = Border.fromBorderSide(warningSide);
  static const Border errorCard = Border.fromBorderSide(errorSide);
  static const Border primaryCard = Border.fromBorderSide(primarySide);
  static const Border bottomNavigation = Border(top: cardElevatedSide);
  static const Border topBar = Border(bottom: cardDefaultSide);
  static const Border sectionDivider = Border(bottom: sectionDividerSide);
  static const Border totalDivider = Border(bottom: totalDividerSide);
  static const Border frameOuter = Border.fromBorderSide(frameOuterSide);
  static const Border listItemBottom = sectionDivider;

  static const AppDashedBorderToken dashedDefault = AppDashedBorderToken(
    color: AppColors.border,
    width: AppBorderWidths.thin,
  );
  static const AppDashedBorderToken dashedPrimary = AppDashedBorderToken(
    color: AppColors.primary,
    width: AppBorderWidths.thin,
  );
  static const AppDashedBorderToken dashedReceipt = AppDashedBorderToken(
    color: AppColors.border,
    width: AppBorderWidths.medium,
  );

  static BorderSide accent(Color color) {
    return BorderSide(color: color, width: AppBorderWidths.thick);
  }

  static BorderSide timelineAccent(Color color) => accent(color);

  static BorderSide chipActiveCustom(Color color) {
    return BorderSide(color: color, width: AppBorderWidths.medium);
  }
}

abstract final class AppStrokeAlignment {
  static const double inside = BorderSide.strokeAlignInside;
  static const double center = BorderSide.strokeAlignCenter;
  static const double outside = BorderSide.strokeAlignOutside;
}
