import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../models/tenant_onboarding_data.dart';
import '../widgets/tenant_onboarding_scaffold.dart';

class AllSetScreen extends StatelessWidget {
  final TenantOnboardingData data;

  const AllSetScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return TenantOnboardingScaffold(
      step: 5,
      title: 'All Set!',
      icon: Icons.check_circle_outline_rounded,
      actions: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () =>
              context.goNamed(AppRouteNames.dashboard, extra: data),
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
            icon: Icons.check_circle_outline_rounded,
            text: data.branchName.trim().isEmpty
                ? 'Branch details ready'
                : '${data.branchName.trim()} created',
            completed: true,
          ),
          const SizedBox(height: 10),
          _StatusRow(
            icon: Icons.check_circle_outline_rounded,
            text: '${data.selectedServices.length} services configured',
            completed: true,
          ),
          const SizedBox(height: 10),
          _StatusRow(
            icon: data.staffEmails.isEmpty
                ? Icons.close_rounded
                : Icons.check_circle_outline_rounded,
            text: data.staffEmails.isEmpty
                ? 'Staff invitation skipped'
                : '${data.staffEmails.length} staff invitations ready',
            completed: data.staffEmails.isNotEmpty,
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
