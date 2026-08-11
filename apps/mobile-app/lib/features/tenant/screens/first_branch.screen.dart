import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../models/tenant_onboarding_data.dart';
import '../widgets/tenant_onboarding_scaffold.dart';

class FirstBranchScreen extends StatefulWidget {
  final TenantOnboardingData data;

  const FirstBranchScreen({super.key, required this.data});

  @override
  State<FirstBranchScreen> createState() => _FirstBranchScreenState();
}

class _FirstBranchScreenState extends State<FirstBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _branchName;
  late final TextEditingController _streetAddress;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  @override
  void initState() {
    super.initState();
    final data = widget.data;
    _branchName = TextEditingController(text: data.branchName);
    _streetAddress = TextEditingController(text: data.streetAddress);
    _city = TextEditingController(text: data.city);
    _phone = TextEditingController(text: data.phone);
    _email = TextEditingController(text: data.email);
  }

  @override
  void dispose() {
    _branchName.dispose();
    _streetAddress.dispose();
    _city.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  void _save() {
    widget.data
      ..branchName = _branchName.text
      ..streetAddress = _streetAddress.text
      ..city = _city.text
      ..phone = _phone.text
      ..email = _email.text;
  }

  void _back() {
    _save();
    context.pop();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    _save();
    context.pushNamed(AppRouteNames.onboardingServices, extra: widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return TenantOnboardingScaffold(
      step: 2,
      title: 'First Branch',
      icon: Icons.store_outlined,
      actions: TenantOnboardingActions(onBack: _back, onContinue: _continue),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add your first branch',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter the location and contact details for your main branch.',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 15,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 26),
            _field('Branch Name', _branchName, 'Main Branch', required: true),
            _field('Street Address', _streetAddress, 'Street address'),
            _field('City', _city, 'City'),
            _field(
              'Phone',
              _phone,
              '+1 234 567 8900',
              keyboardType: TextInputType.phone,
            ),
            _field(
              'Email',
              _email,
              'branch@yourshop.com',
              keyboardType: TextInputType.emailAddress,
              validateEmail: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    String hint, {
    bool required = false,
    bool validateEmail = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TenantFieldLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (required && text.isEmpty) return '$label is required';
              if (validateEmail &&
                  text.isNotEmpty &&
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(text)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
