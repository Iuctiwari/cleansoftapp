import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/core/localization/app_language.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

/// Bottom sheet listing every supported language; picking one applies it
/// immediately and remembers it on the device.
Future<void> showLanguagePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (BuildContext sheetContext) {
      final LocaleController controller = LocaleDependencies.controller;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.none,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(sheetContext.l10n.chooseLanguage, style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(sheetContext.l10n.chooseLanguageSubtitle, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.lg),
              for (final AppLanguage language in AppLanguage.values)
                _LanguageOption(
                  language: language,
                  selected: language == controller.language,
                  onTap: () {
                    controller.setLanguage(language);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected ? AppColors.primarySurface : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: BorderSide(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: AppRadius.cardRadius,
          onTap: onTap,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        language.nativeName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: selected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (language.nativeName != language.englishName)
                        Text(language.englishName, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact "🌐 हिन्दी ▾" pill for the login and sign-up screens.
///
/// Set [onDark] when it sits on the blue gradient header.
class LanguageSelectorButton extends StatelessWidget {
  const LanguageSelectorButton({this.onDark = false, super.key});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final LocaleController controller = LocaleDependencies.controller;
    final Color foreground = onDark ? AppColors.surface : AppColors.primary;
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        return Tooltip(
          message: context.l10n.chooseLanguage,
          child: Material(
            color: onDark ? AppColors.whiteOverlay08 : AppColors.primarySurface,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => showLanguagePicker(context),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.language_rounded, size: 18, color: foreground),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      controller.language.nativeName,
                      style: AppTextStyles.captionBold.copyWith(color: foreground),
                    ),
                    Icon(Icons.arrow_drop_down_rounded, size: 20, color: foreground),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
