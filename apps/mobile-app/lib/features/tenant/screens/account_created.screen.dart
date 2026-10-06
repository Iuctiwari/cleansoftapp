import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';

import '../../../app/theme.dart';
import '../models/registration_form.dart';
import '../models/tenant_onboarding_data.dart';

/// Shown after successful tenant registration.
class AccountCreatedPage extends StatelessWidget {
  final String businessName;
  final TenantOnboardingData? onboardingData;

  const AccountCreatedPage({
    super.key,
    required this.businessName,
    this.onboardingData,
  });

  Future<void> _goToDashboard(BuildContext context) async {
    final data = onboardingData;
    if (data != null &&
        !AuthenticationDependencies.controller.isAuthenticated) {
      final authenticated = await AuthenticationDependencies.controller.signIn(
        identifier: data.registrationForm.email.trim(),
        password: data.registrationForm.password,
      );
      if (!context.mounted) return;
      if (!authenticated) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                AuthenticationDependencies.controller.errorMessage ??
                    context.l10n.commonUnableToSignIn,
              ),
            ),
          );
        return;
      }
    }

    if (context.mounted) {
      context.goNamed(AppRouteNames.dashboard, extra: data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: kPrimaryLight,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Center(child: _AnimatedCheckIcon()),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        context.l10n.accountCreatedTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.accountCreatedBody,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: kTextSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () => context.goNamed(
                          AppRouteNames.registerBusinessInfo,
                          extra:
                              onboardingData ??
                              TenantOnboardingData(
                                registrationForm: RegistrationForm(
                                  businessName: businessName,
                                ),
                              ),
                        ),
                        child: Text(context.l10n.startSetup),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _goToDashboard(context),
                        child: Text(
                          context.l10n.commonSkipForNow,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AnimatedCheckIcon extends StatefulWidget {
  const _AnimatedCheckIcon();

  @override
  State<_AnimatedCheckIcon> createState() => _AnimatedCheckIconState();
}

class _AnimatedCheckIconState extends State<_AnimatedCheckIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const Icon(
        Icons.check_circle_outline_rounded,
        size: 48,
        color: kPrimary,
      ),
    );
  }
}
