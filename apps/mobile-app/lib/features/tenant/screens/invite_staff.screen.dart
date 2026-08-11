import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../models/tenant_onboarding_data.dart';
import '../services/tenant_api_service.dart';
import '../widgets/tenant_onboarding_scaffold.dart';

class InviteStaffScreen extends StatefulWidget {
  final TenantOnboardingData data;

  const InviteStaffScreen({super.key, required this.data});

  @override
  State<InviteStaffScreen> createState() => _InviteStaffScreenState();
}

class _InviteStaffScreenState extends State<InviteStaffScreen> {
  static final RegExp _mobilePattern = RegExp(r'^\+?[0-9]{7,15}$');
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _formKey = GlobalKey<FormState>();
  late final List<_StaffInviteControllers> _controllers;
  final TenantApiService _apiService = TenantApiService();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final staff = widget.data.staff;
    _controllers = staff.isEmpty
        ? <_StaffInviteControllers>[_StaffInviteControllers()]
        : staff.map(_StaffInviteControllers.fromData).toList();
  }

  @override
  void dispose() {
    for (final controllers in _controllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  void _save() {
    widget.data.staff
      ..clear()
      ..addAll(
        _controllers
            .map(
              (controllers) => StaffInvitationData(
                mobileNumber: controllers.mobileNumber.text.trim(),
                email: controllers.email.text.trim(),
              ),
            )
            .where(
              (invitation) =>
                  invitation.mobileNumber.isNotEmpty ||
                  invitation.email.isNotEmpty,
            ),
      );
  }

  bool get _hasInvitationInput => _controllers.any(
    (controllers) =>
        controllers.mobileNumber.text.trim().isNotEmpty ||
        controllers.email.text.trim().isNotEmpty,
  );

  bool get _hasValidInvitation => _controllers.any((controllers) {
    final mobile = controllers.mobileNumber.text.trim();
    final email = controllers.email.text.trim();
    return (mobile.isNotEmpty && _mobilePattern.hasMatch(mobile)) ||
        (email.isNotEmpty && _emailPattern.hasMatch(email));
  });

  void _back() {
    _save();
    context.pop();
  }

  Future<void> _skip() async {
    if (_isSubmitting) return;
    if (_hasInvitationInput) {
      if (!_formKey.currentState!.validate()) return;
      _save();
    } else {
      widget.data.staff.clear();
    }
    setState(() => _isSubmitting = true);

    try {
      await _apiService.completeOnboarding(widget.data);
      if (mounted) {
        widget.data.branchCreated = true;
        widget.data.servicesConfigured = true;
        widget.data.staffInvitationSubmitted = widget.data.staff.isNotEmpty;
        context.pushNamed(AppRouteNames.onboardingAllSet, extra: widget.data);
      }
    } on TenantApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
      }
    } on TenantApiNetworkException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save onboarding. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
        continueLabel: _hasValidInvitation ? 'Continue' : 'Skip for now',
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invite team members to join your workspace. They\'ll get an email invitation.',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(_controllers.length, (index) {
              final controllers = _controllers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TenantFieldLabel(
                      index == 0
                          ? 'Mobile Number'
                          : 'Mobile Number ${index + 1}',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controllers.mobileNumber,
                      keyboardType: TextInputType.phone,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: '+919876543210',
                      ),
                      validator: (value) {
                        final mobile = value?.trim() ?? '';
                        if (mobile.isEmpty) return null;
                        if (!_mobilePattern.hasMatch(mobile)) {
                          return 'Enter a valid mobile number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TenantFieldLabel(
                      index == 0
                          ? 'Email (Optional)'
                          : 'Email ${index + 1} (Optional)',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: controllers.email,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'staff@yourshop.com',
                      ),
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return null;
                        if (!_emailPattern.hasMatch(email)) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              );
            }),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _controllers.add(_StaffInviteControllers())),
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
      ),
    );
  }
}

class _StaffInviteControllers {
  _StaffInviteControllers({String mobileNumber = '', String email = ''})
    : mobileNumber = TextEditingController(text: mobileNumber),
      email = TextEditingController(text: email);

  factory _StaffInviteControllers.fromData(StaffInvitationData data) {
    return _StaffInviteControllers(
      mobileNumber: data.mobileNumber,
      email: data.email,
    );
  }

  final TextEditingController mobileNumber;
  final TextEditingController email;

  void dispose() {
    mobileNumber.dispose();
    email.dispose();
  }
}
