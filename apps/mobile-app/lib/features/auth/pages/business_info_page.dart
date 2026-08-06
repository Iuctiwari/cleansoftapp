import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../models/registration_form.dart';
import '../widgets/business_type_chip.dart';

/// Business types shown as chips — values match the backend enum.
const _kBusinessTypes = [
  ('Laundry', 'laundry'),
  ('Dry Cleaning', 'dry_cleaning'),
  ('Tailoring', 'tailoring'),
  ('Shoe Cleaning', 'shoe_cleaning'),
  ('Carpet Cleaning', 'carpet_cleaning'),
  ('Ironing Services', 'ironing_services'),
  ('Repair Shop', 'repair_shop'),
  ('Other', 'other'),
];

/// Screen 2 (Step 1/2) — "Tell us about your business".
///
/// Collects businessName, businessType, ownerName and navigates to
/// [AccountDetailsPage] passing the updated [RegistrationForm] via GoRouter extra.
class BusinessInfoPage extends StatefulWidget {
  final RegistrationForm form;

  const BusinessInfoPage({super.key, required this.form});

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
    _businessNameController =
        TextEditingController(text: widget.form.businessName);
    _ownerNameController =
        TextEditingController(text: widget.form.ownerName);
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
        const SnackBar(
          content: Text('Please select a business type'),
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

    context.push('/register/account-details', extra: updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: _StepAppBar(title: 'Business Info', step: 'Step 1/2'),
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
                    const Text(
                      'Tell us about your business',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This helps us personalize your experience.',
                      style: TextStyle(fontSize: 14, color: kTextSecondary),
                    ),
                    const SizedBox(height: 28),

                    // Business Name
                    const _FieldLabel('Business Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Ahmed Laundry & Cleaners',
                        prefixIcon: Icon(Icons.store_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Business name is required';
                        }
                        if (v.trim().length < 2) return 'Name is too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Business Type chips
                    const _FieldLabel('Business Type'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _kBusinessTypes.map((entry) {
                        final (label, value) = entry;
                        return BusinessTypeChip(
                          label: label,
                          isSelected: _selectedType == value,
                          onTap: () => setState(() => _selectedType = value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Owner Name
                    const _FieldLabel('Owner Name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        hintText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Owner name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),

                    // Continue button
                    ElevatedButton.icon(
                      onPressed: _onContinue,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text('Continue'),
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
