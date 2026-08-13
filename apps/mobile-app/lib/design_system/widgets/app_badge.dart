import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';
import 'package:nexoraa_mobile/design_system/radius/app_radius.dart';
import 'package:nexoraa_mobile/design_system/spacing/app_spacing.dart';
import 'package:nexoraa_mobile/design_system/typography/app_text_styles.dart';

enum AppBadgeTone { success, neutral, warning, error, info }

/// Small status pill, e.g. active/inactive branch status.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({required this.label, required this.tone, super.key});

  final String label;
  final AppBadgeTone tone;

  AppSemanticColor get _colors {
    switch (tone) {
      case AppBadgeTone.success:
        return const AppSemanticColor(
          text: AppColors.success,
          background: AppColors.successSurface,
        );
      case AppBadgeTone.neutral:
        return const AppSemanticColor(
          text: AppColors.textMuted,
          background: AppColors.surfaceMuted,
        );
      case AppBadgeTone.warning:
        return const AppSemanticColor(
          text: AppColors.warningDark,
          background: AppColors.warningSurface,
        );
      case AppBadgeTone.error:
        return const AppSemanticColor(
          text: AppColors.error,
          background: AppColors.errorSurface,
        );
      case AppBadgeTone.info:
        return const AppSemanticColor(
          text: AppColors.info,
          background: AppColors.infoSurface,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSemanticColor colors = _colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: AppTextStyles.badge.copyWith(color: colors.text),
        ),
      ),
    );
  }
}
