import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/assets/app_assets.dart';
import 'package:nexoraa_mobile/design_system/borders/app_borders.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';
import 'package:nexoraa_mobile/design_system/radius/app_radius.dart';
import 'package:nexoraa_mobile/design_system/shadows/app_shadows.dart';
import 'package:nexoraa_mobile/design_system/sizes/app_sizes.dart';

enum AppBrandLogoSize { compact, splash }

class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({this.size = AppBrandLogoSize.compact, super.key});

  final AppBrandLogoSize size;

  @override
  Widget build(BuildContext context) {
    final bool isSplash = size == AppBrandLogoSize.splash;
    final double dimension = isSplash
        ? AppSizes.brandLogoSplash
        : AppSizes.brandLogoCompact;
    final double iconSize = isSplash
        ? AppSizes.brandIconSplash
        : AppSizes.brandIconCompact;
    final double radius = isSplash ? AppRadius.sheet : AppRadius.xlPlus;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: isSplash
            ? Border.all(
                color: AppColors.whiteOverlay30,
                width: AppBorderWidths.thin,
              )
            : null,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        boxShadow: AppShadows.small,
        color: AppColors.whiteOverlay18,
      ),
      child: SizedBox.square(
        dimension: dimension,
        child: Icon(
          isSplash ? AppAssets.splashLogo : AppAssets.appLogo,
          color: AppColors.surface,
          size: iconSize,
        ),
      ),
    );
  }
}
