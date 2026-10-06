import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart' show AppAlertDialog;
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

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
    final AppLocalizations l10n = context.l10n;
    if (_hasInvitationInput) {
      if (!_formKey.currentState!.validate()) {
        await AppAlertDialog.show(
          context,
          title: l10n.commonRequiredInformation,
          message: l10n.inviteFixHighlighted,
        );
        return;
      }
      _save();
    } else {
      widget.data.staff.clear();
    }
    setState(() => _isSubmitting = true);

    try {
      // Onboarding and invitations need the owner's login. They're signed in right
      // after sign-up, but re-sign in with the details they just entered if not.
      final auth = AuthenticationDependencies.controller;
      if (!auth.isAuthenticated) {
        await auth.signIn(
          identifier: widget.data.registrationForm.email.trim(),
          password: widget.data.registrationForm.password,
        );
      }

      await _apiService.completeOnboarding(widget.data);
      final ({bool allSent, String message})? report = await _sendInvitations(l10n);
      if (!mounted) return;
      if (report != null) {
        await AppAlertDialog.show(
          context,
          title: report.allSent ? l10n.invitationsSent : l10n.invitationsNeedAttention,
          message: report.message,
          isError: !report.allSent,
        );
        if (!mounted) return;
      }
      widget.data.branchCreated = true;
      widget.data.servicesConfigured = true;
      widget.data.staffInvitationSubmitted = widget.data.staff.isNotEmpty;
      context.pushNamed(AppRouteNames.onboardingAllSet, extra: widget.data);
    } on TenantApiException catch (error) {
      if (mounted) {
        await AppAlertDialog.show(
          context,
          title: AppAlertDialog.titleFor(error.userMessage),
          message: error.userMessage,
        );
      }
    } on TenantApiNetworkException catch (error) {
      if (mounted) {
        await AppAlertDialog.show(
          context,
          title: l10n.commonConnectionProblem,
          message: error.message,
        );
      }
    } catch (_) {
      if (mounted) {
        await AppAlertDialog.show(
          context,
          title: l10n.commonSomethingWentWrong,
          message: l10n.unableToSaveOnboarding,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Creates each invited staff account and emails the invitation. Returns a
  /// summary to show, or null when nothing was invited.
  Future<({bool allSent, String message})?> _sendInvitations(
    AppLocalizations l10n,
  ) async {
    final invites = widget.data.staff.where((s) => s.email.trim().isNotEmpty).toList();
    if (invites.isEmpty) return null;
    final String? branchId = AuthenticationDependencies.controller.session?.branchId;
    final StaffApiService staffApi = StaffApiService();

    final List<String> sent = <String>[];
    final List<String> problems = <String>[];
    for (final StaffInvitationData invite in invites) {
      final String email = invite.email.trim().toLowerCase();
      try {
        final bool emailed = await staffApi.inviteStaff(
          tenantId: widget.data.tenantId,
          name: _nameFromEmail(email),
          email: email,
          mobileNumber: invite.mobileNumber.trim(),
          businessName: widget.data.registrationForm.businessName.trim(),
          branches: <String>[if (branchId != null && branchId.isNotEmpty) branchId],
        );
        if (emailed) {
          sent.add(email);
        } else {
          problems.add(l10n.inviteReportEmailFailed(email));
        }
      } on StaffApiException catch (error) {
        problems.add(
          l10n.inviteReportFailed(
            email,
            error.backendMessage ?? l10n.inviteReportCouldNotInvite,
          ),
        );
      }
    }

    if (problems.isEmpty) {
      return (allSent: true, message: l10n.inviteReportAllSent(sent.join(', ')));
    }
    return (
      allSent: false,
      message: <String>[
        if (sent.isNotEmpty) l10n.inviteReportInvited(sent.join(', ')),
        ...problems,
        l10n.inviteReportFooter,
      ].join('\n\n'),
    );
  }

  /// "ravi.kumar@shop.com" → "Ravi Kumar" (staff can edit their name later).
  static String _nameFromEmail(String email) {
    final String local = email.split('@').first.replaceAll(RegExp(r'[._\-+0-9]+'), ' ').trim();
    if (local.isEmpty) return 'Staff Member';
    return local
        .split(RegExp(r'\s+'))
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return TenantOnboardingScaffold(
      step: 4,
      title: context.l10n.inviteStaffTitle,
      icon: Icons.group_add_outlined,
      actions: TenantOnboardingActions(
        onBack: _back,
        onContinue: _skip,
        continueLabel: _hasValidInvitation
            ? context.l10n.commonContinue
            : context.l10n.commonSkipForNow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.inviteStaffSubtitle,
              style: const TextStyle(
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
                          ? context.l10n.staffEmailLabel
                          : context.l10n.staffEmailNumberedLabel(index + 1),
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
                        // Required once anything is entered in this row — the
                        // invitation (and their login ID) is the email.
                        if (email.isEmpty) {
                          return controllers.mobileNumber.text.trim().isEmpty
                              ? null
                              : context.l10n.emailRequiredForInvite;
                        }
                        if (!_emailPattern.hasMatch(email)) {
                          return context.l10n.invalidEmail;
                        }
                        final duplicates = _controllers
                            .where((c) => c.email.text.trim().toLowerCase() == email.toLowerCase())
                            .length;
                        if (duplicates > 1) return context.l10n.emailEnteredTwice;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TenantFieldLabel(
                      index == 0
                          ? context.l10n.staffMobileLabel
                          : context.l10n.staffMobileNumberedLabel(index + 1),
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
                          return context.l10n.invalidMobile;
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
                label: Text(
                  context.l10n.addAnother,
                  style: const TextStyle(fontWeight: FontWeight.w700),
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
              child: Text(
                context.l10n.inviteStaffNote,
                style: const TextStyle(
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
