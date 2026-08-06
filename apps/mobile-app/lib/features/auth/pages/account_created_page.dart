import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';

/// Screen 4 — "Account Created!" success screen.
///
/// Shown after successful tenant registration. The [businessName] is
/// passed via GoRouter extra so it can be displayed or used for navigation.
class AccountCreatedPage extends StatelessWidget {
  final String businessName;

  const AccountCreatedPage({super.key, required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Check icon ───────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: _AnimatedCheckIcon(),
                ),
              ),
              const SizedBox(height: 32),

              // ── Heading ───────────────────────────────────────────────
              const Text(
                'Account Created!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your business account is ready.\nLet\'s set up your workspace.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: kTextSecondary,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // ── Start Setup button ────────────────────────────────────
              ElevatedButton(
                onPressed: () {
                  // TODO: navigate to workspace setup flow
                  context.go('/login');
                },
                child: const Text('Start Setup'),
              ),
              const SizedBox(height: 16),

              // ── Skip for now ──────────────────────────────────────────
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animated check mark icon that scales in on first build.
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
