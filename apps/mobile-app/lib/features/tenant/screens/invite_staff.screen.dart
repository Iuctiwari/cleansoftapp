import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../models/tenant_onboarding_data.dart';
import '../widgets/tenant_onboarding_scaffold.dart';

class InviteStaffScreen extends StatefulWidget {
  final TenantOnboardingData data;

  const InviteStaffScreen({super.key, required this.data});

  @override
  State<InviteStaffScreen> createState() => _InviteStaffScreenState();
}

class _InviteStaffScreenState extends State<InviteStaffScreen> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    final emails = widget.data.staffEmails;
    _controllers = emails.isEmpty
        ? [TextEditingController()]
        : emails.map((email) => TextEditingController(text: email)).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    widget.data.staffEmails
      ..clear()
      ..addAll(
        _controllers
            .map((controller) => controller.text.trim())
            .where((email) => email.isNotEmpty),
      );
  }

  void _back() {
    _save();
    context.pop();
  }

  void _skip() {
    _save();
    context.pushNamed(AppRouteNames.onboardingAllSet, extra: widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return TenantOnboardingScaffold(
      step: 4,
      title: 'Invite Staff',
      icon: Icons.group_add_outlined,
      actions: TenantOnboardingActions(
        onBack: _back,
        onContinue: _skip,
        continueLabel: 'Skip for now',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite team members to join your workspace. They\'ll get an email invitation.',
            style: TextStyle(color: kTextSecondary, fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 24),
          ...List.generate(_controllers.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TenantFieldLabel(
                    index == 0 ? 'Staff Email' : 'Staff Email ${index + 1}',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controllers[index],
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'staff@yourshop.com',
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _controllers.add(TextEditingController())),
              style: TextButton.styleFrom(
                backgroundColor: kPrimaryLight,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Another',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD45C)),
            ),
            child: const Text(
              'Staff members will receive an invitation to join your workspace. They\'ll set their own password.',
              style: TextStyle(
                color: Color(0xFF9A4A00),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
