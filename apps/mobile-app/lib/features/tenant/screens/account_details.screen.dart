import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart' show AppAlertDialog;
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';

import '../../../app/theme.dart';
import '../models/registration_form.dart';
import '../models/tenant_onboarding_data.dart';
import '../services/tenant_api_service.dart';

/// Screen 3 (Step 2/2) — "Create your account".
///
/// Collects email, phone number, password and the terms agreement.
/// On submit calls the tenant-service API; on success navigates to
/// [AccountCreatedPage].
class AccountDetailsPage extends StatefulWidget {
  final RegistrationForm form;

  const AccountDetailsPage({super.key, required this.form});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;

  final _apiService = TenantApiService();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.form.email;
    _phoneController.text = widget.form.mobileNumber;
    _passwordController.text = widget.form.password;
    _agreedToTerms = widget.form.agreedToTerms;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _agreedToTerms && !_isLoading;

  /// Shows the problem inline AND as a pop-up, so "Email is already registered"
  /// and missing required fields can't be missed.
  Future<void> _showError(String message, {String? title}) async {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    await AppAlertDialog.show(
      context,
      title: title ?? AppAlertDialog.titleFor(message),
      message: message,
    );
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      await _showError(
        'Please fill in the highlighted fields — email, phone number and password are required.',
        title: 'Required information',
      );
      return;
    }
    if (!_agreedToTerms) {
      await _showError('You must agree to the Terms of Service.', title: 'Required information');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final updatedForm = widget.form.copyWith(
      email: _emailController.text,
      mobileNumber: _phoneController.text,
      password: _passwordController.text,
      agreedToTerms: _agreedToTerms,
    );

    try {
      final result = await _apiService.registerTenant(updatedForm);
      await AuthenticationDependencies.controller.signIn(
        identifier: updatedForm.email.trim(),
        password: updatedForm.password,
      );
      if (mounted) {
        context.pushReplacement(
          '/register/success',
          extra: TenantOnboardingData(
            registrationForm: updatedForm,
            tenantId: result.tenantId,
            ownerUserId: result.ownerUserId,
            slug: result.slug,
          ),
        );
      }
    } on TenantApiException catch (e) {
      final String message = e.userMessage;
      await _showError(
        message.contains('already registered')
            ? '$message. Log in with that account instead (use "Forgot password?" if needed), '
                  'or use a different one.'
            : message,
      );
    } on TenantApiNetworkException catch (e) {
      await _showError(e.message, title: 'Connection problem');
    } catch (_) {
      await _showError('Unable to complete registration. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: _StepAppBar(title: 'Account Details', step: 'Step 2/2'),
      body: Column(
        children: [
          // ── Progress bar (full) ───────────────────────────────────────
          _StepProgressBar(filledFraction: 1.0),

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
                      'Create your account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "You'll use these to sign in.",
                      style: TextStyle(fontSize: 14, color: kTextSecondary),
                    ),
                    const SizedBox(height: 28),

                    // Email
                    const _FieldLabel('Email Address'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'you@business.com',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone Number
                    const _FieldLabel('Phone Number'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+92 300 1234567',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Phone number is required';
                        }
                        if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(v.trim())) {
                          return 'Enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password
                    const _FieldLabel('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Min. 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: kTextSecondary,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Password is required';
                        if (v.length < 8) return 'Minimum 8 characters';
                        if (!RegExp(r'[A-Z]').hasMatch(v)) {
                          return 'Must contain an uppercase letter';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                          return 'Must contain a number';
                        }
                        if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) {
                          return 'Must contain a special character';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Terms checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) =>
                              setState(() => _agreedToTerms = v ?? false),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _agreedToTerms = !_agreedToTerms,
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 13.5,
                                ),
                                children: [
                                  const TextSpan(text: 'I agree to the '),
                                  const TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' and '),
                                  const TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: kPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Create Account button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _createAccount : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSubmit
                              ? kPrimary
                              : kPrimaryLight,
                          disabledBackgroundColor: kPrimaryLight,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Create Account'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Back button
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text(
                          'Back',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
}

// ── Shared step widgets (duplicated for file independence) ───────────────────

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
  final double filledFraction;

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
