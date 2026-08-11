import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/controllers/splash_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  final SplashController _splashController = SplashController(
    authenticationController: AuthenticationDependencies.controller,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDurations.standard,
      vsync: this,
    );
    final CurvedAnimation curvedAnimation = CurvedAnimation(
      parent: _animationController,
      curve: AppDurations.emphasizedCurve,
    );
    _fadeAnimation = Tween<double>(
      begin: AppOpacity.transparent,
      end: AppOpacity.opaque,
    ).animate(curvedAnimation);
    _scaleAnimation = Tween<double>(
      begin: AppOpacity.disabled,
      end: AppOpacity.opaque,
    ).animate(curvedAnimation);

    unawaited(_animationController.forward());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_resolveStartup());
      }
    });
  }

  Future<void> _resolveStartup() async {
    final StartupDestination destination = await _splashController
        .resolveDestination();
    if (!mounted) {
      return;
    }

    switch (destination) {
      case StartupDestination.dashboard:
        context.goNamed(AppRouteNames.dashboard);
      case StartupDestination.login:
        context.goNamed(AppRouteNames.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppGradients.primarySplash),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const Positioned(
              right: -AppSizes.splashDecorationLargeOffset,
              top: -AppSizes.splashDecorationLargeOffset,
              child: _SplashDecoration(
                color: AppColors.whiteOverlay06,
                size: AppSizes.splashDecorationLarge,
              ),
            ),
            const Positioned(
              bottom: -AppSizes.splashDecorationSmallOffset,
              left: -AppSizes.splashDecorationSmallOffset,
              child: _SplashDecoration(
                color: AppColors.whiteOverlay05,
                size: AppSizes.splashDecorationSmall,
              ),
            ),
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        AppBrandLogo(size: AppBrandLogoSize.splash),
                        SizedBox(height: AppSpacing.xxl),
                        Text('Nexoraa', style: AppTextStyles.displaySmall),
                        SizedBox(height: AppSpacing.xs),
                        Text('CLEANSOFT', style: AppTextStyles.splashSubtitle),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.section),
                  child: _SplashFooter(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplashDecoration extends StatelessWidget {
  const _SplashDecoration({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: SizedBox.square(dimension: size),
    );
  }
}

class _SplashFooter extends StatelessWidget {
  const _SplashFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _ProgressDot(),
            SizedBox(width: AppSpacing.sm),
            _ProgressDot(active: true),
            SizedBox(width: AppSpacing.sm),
            _ProgressDot(),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Business Management Platform',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.whiteOverlay40,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Version 0.0.0',
          style: AppTextStyles.micro.copyWith(color: AppColors.whiteOverlay40),
        ),
      ],
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.standard,
      height: AppSpacing.sm,
      width: active ? AppSpacing.xxl : AppSpacing.sm,
      decoration: BoxDecoration(
        borderRadius: AppRadius.circular,
        color: active ? AppColors.surface : AppColors.whiteOverlay35,
      ),
    );
  }
}
