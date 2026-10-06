import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
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
                    context.l10n.commonUnableToSignIn,
              ),
            ),
          );
        return;
      }
    }

    if (context.mounted) {
      context.goNamed(AppRouteNames.onboardingChoosePlan, extra: data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TenantOnboardingScaffold(
      step: 5,
      title: context.l10n.allSetTitle,
      icon: Icons.check_circle_outline_rounded,
      actions: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _goToDashboard(context),
          child: Text(context.l10n.goToDashboard),
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
          Text(
            context.l10n.allSetHeading,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.allSetBody,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextSecondary, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          _StatusRow(
            icon: data.branchCreated
                ? Icons.check_circle_outline_rounded
                : Icons.close_rounded,
            text: data.branchCreated
                ? context.l10n.branchCreated(data.branchName.trim())
                : context.l10n.branchNotCreated,
            completed: data.branchCreated,
          ),
          const SizedBox(height: 10),
          _StatusRow(
            icon: data.servicesConfigured
                ? Icons.check_circle_outline_rounded
                : Icons.close_rounded,
            text: data.servicesConfigured
                ? context.l10n.servicesConfigured(data.selectedServices.length)
                : context.l10n.servicesNotConfigured,
            completed: data.servicesConfigured,
          ),
          const SizedBox(height: 10),
          _StatusRow(
            icon: !data.staffInvitationSubmitted
                ? Icons.close_rounded
                : Icons.check_circle_outline_rounded,
            text: !data.staffInvitationSubmitted
                ? context.l10n.staffInvitationSkipped
                : context.l10n.staffInvitationsSent(data.staff.length),
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
