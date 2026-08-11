import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class TenantOnboardingScaffold extends StatelessWidget {
  final int step;
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? actions;

  const TenantOnboardingScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.icon,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: kPrimary,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.paddingOf(context).top + 22,
              24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index == 4 ? 0 : 10),
                        decoration: BoxDecoration(
                          color: index < step
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: Colors.white, size: 29),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step $step of 5',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: child,
            ),
          ),
          if (actions != null)
            SafeArea(
              top: false,
              child: Container(
                color: kBackground,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: actions,
              ),
            ),
        ],
      ),
    );
  }
}

class TenantOnboardingActions extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final String continueLabel;

  const TenantOnboardingActions({
    super.key,
    required this.onBack,
    required this.onContinue,
    this.continueLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(onPressed: onBack, child: const Text('Back')),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton(
            onPressed: onContinue,
            child: Text(continueLabel),
          ),
        ),
      ],
    );
  }
}

class TenantFieldLabel extends StatelessWidget {
  final String text;

  const TenantFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: kTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
