import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../models/tenant_onboarding_data.dart';
import '../widgets/tenant_onboarding_scaffold.dart';

class AllSetScreen extends StatelessWidget {
  final TenantOnboardingData data;

  const AllSetScreen({super.key, required this.data});

  Future<void> _goToDashboard(BuildContext context) async {
    if (!AuthenticationDependencies.controller.isAuthenticated) {
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
                    'Unable to sign in. Please try again.',
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
    return TenantOnboardingScaffold(
      step: 5,
      title: 'All Set!',
      icon: Icons.check_circle_outline_rounded,
      actions: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _goToDashboard(context),
          child: const Text('Go to Dashboard'),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 68,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "You're all set!",
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your workspace is configured and ready. Start adding orders and managing your business.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSecondary, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          _StatusRow(
            icon: data.branchCreated
                ? Icons.check_circle_outline_rounded
                : Icons.close_rounded,
            text: data.branchCreated
                ? '${data.branchName.trim()} created'
                : 'Branch not created',
            completed: data.branchCreated,
          ),
          const SizedBox(height: 10),
          _StatusRow(
            icon: data.servicesConfigured
                ? Icons.check_circle_outline_rounded
                : Icons.close_rounded,
            text: data.servicesConfigured
                ? '${data.selectedServices.length} services configured'
                : 'Services not configured',
            completed: data.servicesConfigured,
          ),
          const SizedBox(height: 10),
          _StatusRow(
            icon: !data.staffInvitationSubmitted
                ? Icons.close_rounded
                : Icons.check_circle_outline_rounded,
            text: !data.staffInvitationSubmitted
                ? 'Staff invitation skipped'
                : '${data.staff.length} staff invitation${data.staff.length == 1 ? '' : 's'} sent',
            completed: data.staffInvitationSubmitted,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool completed;

  const _StatusRow({
    required this.icon,
    required this.text,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final color = completed ? const Color(0xFF079447) : kTextSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFEDFCF2) : kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed ? const Color(0xFFA7EFC1) : kBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
