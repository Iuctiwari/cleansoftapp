import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';

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
                      const Text(
                        'Account Created!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your business account is ready.\nLet\'s set up your workspace.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
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
                        child: const Text('Start Setup'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.goNamed(
                          AppRouteNames.dashboard,
                          extra: onboardingData,
                        ),
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(
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
