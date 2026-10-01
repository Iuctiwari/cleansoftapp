import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/colors/app_colors.dart';
import 'package:nexoraa_mobile/design_system/radius/app_radius.dart';
import 'package:nexoraa_mobile/design_system/spacing/app_spacing.dart';
import 'package:nexoraa_mobile/design_system/typography/app_text_styles.dart';

/// Pop-up for something the user must fix or know before continuing, e.g.
/// "Email is already registered" or a missing required field. Use instead of
/// an easy-to-miss SnackBar / inline text for blocking problems.
abstract final class AppAlertDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = true,
    String buttonLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.dialogRadius,
          ),
          icon: Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? AppColors.error : AppColors.success,
            size: 40,
          ),
          title: Text(title, style: AppTextStyles.headingSmall, textAlign: TextAlign.center),
          content: Text(message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.none,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(buttonLabel),
            ),
          ],
        );
      },
    );
  }

  /// Title for a backend/validation message, so popups read naturally.
  static String titleFor(String message) {
    final String lower = message.toLowerCase();
    if (lower.contains('already') || lower.contains('exists')) return 'Already registered';
    if (lower.contains('required') || lower.contains('enter ') || lower.contains('missing')) {
      return 'Required information';
    }
    if (lower.contains('unable to reach') || lower.contains('unavailable') || lower.contains('timed out')) {
      return 'Connection problem';
    }
    return 'Please check';
  }
}

/// Confirmation dialog for destructive actions, e.g. deactivating a branch.
abstract final class AppConfirmDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancel',
    bool destructive = true,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.dialogRadius,
          ),
          title: Text(title, style: AppTextStyles.headingSmall),
          content: Text(message, style: AppTextStyles.bodyMedium),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.none,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel),
            ),
            ElevatedButton(
              style: destructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.surface,
                    )
                  : null,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }
}
