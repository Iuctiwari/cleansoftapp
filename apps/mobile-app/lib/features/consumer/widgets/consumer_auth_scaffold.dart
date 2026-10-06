import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

/// Gradient header + form body shared by the customer sign-in screens,
/// matching the shop login's look.
class ConsumerAuthScaffold extends StatelessWidget {
  const ConsumerAuthScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          DecoratedBox(
            decoration: const BoxDecoration(gradient: AppGradients.primaryHeader),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xxlPlus,
                  AppSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        if (context.canPop())
                          IconButton(
                            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                            onPressed: () => context.pop(),
                            icon: const Icon(AppIcons.arrowBack, color: AppColors.surface),
                          ),
                        const Spacer(),
                        const LanguageSelectorButton(onDark: true),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: AppSpacing.md),
                          Text(title, style: AppTextStyles.headingExtraLarge),
                          const SizedBox(height: AppSpacing.sm),
                          Text(subtitle, style: AppTextStyles.headerSubtitle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppSpacing.xxlPlus),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSizes.authenticationContentMaxWidth),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Field validators for the customer forms.
abstract final class ConsumerValidators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _mobile = RegExp(r'^(\+?91|0)?[6-9]\d{9}$');

  static String? email(BuildContext context, String? value) =>
      _email.hasMatch(value?.trim() ?? '') ? null : context.l10n.invalidEmailAddress;

  static String? mobile(BuildContext context, String? value) =>
      _mobile.hasMatch((value ?? '').replaceAll(RegExp(r'[\s-]'), ''))
          ? null
          : context.l10n.invalidMobile;

  static String? password(BuildContext context, String? value) {
    final String text = value ?? '';
    final bool strong = text.length >= 8 &&
        RegExp('[A-Z]').hasMatch(text) &&
        RegExp('[a-z]').hasMatch(text) &&
        RegExp(r'\d').hasMatch(text) &&
        RegExp('[^A-Za-z0-9]').hasMatch(text);
    return strong ? null : context.l10n.consumerErrPasswordPolicy;
  }

  static String? required(String? value, String message) =>
      (value?.trim().isEmpty ?? true) ? message : null;
}
