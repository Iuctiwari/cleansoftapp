import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

/// First screen for a signed-out user: customer or business.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.primarySplash),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxlPlus),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.authenticationContentMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        AppBrandLogo(),
                        Spacer(),
                        LanguageSelectorButton(onDark: true),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.section),
                    Text(context.l10n.welcomeTitle, style: AppTextStyles.headingExtraLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(context.l10n.welcomeSubtitle, style: AppTextStyles.headerSubtitle),
                    const SizedBox(height: AppSpacing.section),
                    _ChoiceCard(
                      key: const Key('welcome.customer'),
                      icon: Icons.search_rounded,
                      title: context.l10n.welcomeCustomerTitle,
                      subtitle: context.l10n.welcomeCustomerSubtitle,
                      onTap: () => context.pushNamed(AppRouteNames.consumerLogin),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ChoiceCard(
                      key: const Key('welcome.business'),
                      icon: Icons.storefront_outlined,
                      title: context.l10n.welcomeBusinessTitle,
                      subtitle: context.l10n.welcomeBusinessSubtitle,
                      onTap: () => context.pushNamed(AppRouteNames.login),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Icon(icon, color: AppColors.primary, size: AppSizes.iconExtraLarge),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              const Icon(AppIcons.chevronRight, color: AppColors.textSubtle),
            ],
          ),
        ),
      ),
    );
  }
}
