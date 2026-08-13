import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';
import 'package:nexoraa_mobile/design_system/radius/app_radius.dart';
import 'package:nexoraa_mobile/design_system/shadows/app_shadows.dart';
import 'package:nexoraa_mobile/design_system/spacing/app_spacing.dart';

/// Token-driven surface container, matching the card styling already used
/// ad hoc across the app (e.g. `more_screen.dart`'s `_MoreSurface`).
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardInsets,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.fromBorderSide(
          BorderSide(color: borderColor ?? AppColors.borderSubtle, width: 1),
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadius.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: AppRadius.cardRadius,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
