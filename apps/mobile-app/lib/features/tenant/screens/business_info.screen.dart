import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:nexoraa_mobile/core/localization/l10n.dart';

import '../../../app/theme.dart';
import '../models/registration_form.dart';
import '../models/tenant_onboarding_data.dart';
import '../widgets/business_type_chip.dart';
import '../widgets/tenant_onboarding_scaffold.dart';

/// Business types shown as chips — values match the backend enum.
final List<(String Function(AppLocalizations), String)> _kBusinessTypes = [
  ((l) => l.businessTypeLaundry, 'laundry'),
  ((l) => l.businessTypeDryCleaning, 'dry_cleaning'),
  ((l) => l.businessTypeTailoring, 'tailoring'),
  ((l) => l.businessTypeShoeCleaning, 'shoe_cleaning'),
  ((l) => l.businessTypeApplianceRepair, 'appliance_repair'),
  ((l) => l.businessTypeMobileRepair, 'mobile_repair'),
  ((l) => l.businessTypeVehicleWash, 'vehicle_wash'),
  ((l) => l.businessTypeSalon, 'salon'),
  ((l) => l.businessTypeGeneral, 'general'),
  ((l) => l.businessTypeCustom, 'custom'),
];

/// Screen 2 (Step 1/2) — "Tell us about your business".
///
/// Collects businessName, businessType, ownerName and navigates to
/// [AccountDetailsPage] passing the updated [RegistrationForm] via GoRouter extra.
class BusinessInfoPage extends StatefulWidget {
  final RegistrationForm form;
  final TenantOnboardingData? onboardingData;

  const BusinessInfoPage({super.key, required this.form, this.onboardingData});

  @override
  State<BusinessInfoPage> createState() => _BusinessInfoPageState();
}

class _BusinessInfoPageState extends State<BusinessInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _businessNameController;
  late final TextEditingController _ownerNameController;
  String _selectedType = '';

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(
      text: widget.form.businessName,
    );
    _ownerNameController = TextEditingController(text: widget.form.ownerName);
    _selectedType = widget.form.businessType;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.selectBusinessType),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final updated = widget.form.copyWith(
      businessName: _businessNameController.text,
      businessType: _selectedType,
      ownerName: _ownerNameController.text,
    );

    final onboardingData = widget.onboardingData;
    if (onboardingData != null) {
      onboardingData.registrationForm = updated;
      context.push('/onboarding/first-branch', extra: onboardingData);
      return;
    }

    context.push('/register/account-details', extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onboardingData != null) {
      return _buildOnboardingSummary(context);
    }

    return Scaffold(
      backgroundColor: kSurface,
      appBar: _StepAppBar(
        title: context.l10n.businessInfoTitle,
        step: context.l10n.stepFraction(1, 2),
      ),
      body: Column(
        children: [
          // ── Progress bar ─────────────────────────────────────────────
          _StepProgressBar(filledFraction: 0.5),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    Text(
                      context.l10n.businessInfoHeading,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.businessInfoSubtitle,
                      style: TextStyle(fontSize: 14, color: kTextSecondary),
                    ),
                    const SizedBox(height: 28),

                    // Business Name
                    _FieldLabel(context.l10n.businessName),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: InputDecoration(
                        hintText: context.l10n.businessNameHint,
                        prefixIcon: const Icon(Icons.store_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return context.l10n.businessNameRequired;
                        }
                        if (v.trim().length < 2) return context.l10n.nameTooShort;
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Business Type chips
                    _FieldLabel(context.l10n.businessType),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _kBusinessTypes.map((entry) {
                        final (labelOf, value) = entry;
                        return BusinessTypeChip(
                          label: labelOf(context.l10n),
                          isSelected: _selectedType == value,
                          onTap: () => setState(() => _selectedType = value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Owner Name
                    _FieldLabel(context.l10n.ownerName),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: InputDecoration(
                        hintText: context.l10n.fullNameHint,
                        prefixIcon: const Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return context.l10n.ownerNameRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _onContinue,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: Text(context.l10n.commonContinue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingSummary(BuildContext context) {
    final form = widget.form;
    var businessType = form.businessType;
    for (final entry in _kBusinessTypes) {
      if (entry.$2 == form.businessType) {
        businessType = entry.$1(context.l10n);
        break;
      }
    }

    return TenantOnboardingScaffold(
      step: 1,
      title: context.l10n.businessInfoTitle,
      icon: Icons.business_outlined,
      actions: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.push(
            '/onboarding/first-branch',
            extra: widget.onboardingData,
          ),
          icon: const Icon(Icons.arrow_forward_rounded, size: 20),
          label: Text(context.l10n.commonContinue),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.businessSummaryIntro,
            style: const TextStyle(color: kTextSecondary, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _SummaryRow(label: context.l10n.businessName, value: form.businessName),
                _SummaryRow(label: context.l10n.businessType, value: businessType),
                _SummaryRow(label: context.l10n.owner, value: form.ownerName),
                _SummaryRow(
                  label: context.l10n.commonEmail,
                  value: form.email,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.left,
              style: const TextStyle(color: kTextSecondary, fontSize: 15),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared step widgets ──────────────────────────────────────────────────────

class _StepAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String step;

  const _StepAppBar({required this.title, required this.step});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
      ),
      title: Text(title),
      actions: [
        const Center(child: LanguageSelectorButton()),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 14,
                color: kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StepProgressBar extends StatelessWidget {
  final double filledFraction; // 0.5 = step 1/2, 1.0 = step 2/2

  const _StepProgressBar({required this.filledFraction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final total = constraints.maxWidth;
          final filled = total * filledFraction;
          return Row(
            children: [
              Container(
                width: filled,
                height: 4,
                decoration: BoxDecoration(
                  color: kProgressBar,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: total - filled,
                height: 4,
                decoration: BoxDecoration(
                  color: kProgressBarBg,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: kTextPrimary,
      ),
    );
  }
}
