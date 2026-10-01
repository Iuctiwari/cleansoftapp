import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/password_policy.dart';

/// Lets a signed-in user (owner or staff) change their password. auth-service
/// verifies the current password and signs out the user's other devices; this
/// device is then signed out too, so the next login uses the new password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Re-render the rules checklist as the user types.
    _newController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    final String current = _currentController.text;
    final String next = _newController.text;
    final String confirm = _confirmController.text;

    final String? problem = current.isEmpty
        ? 'Enter your current password.'
        : PasswordPolicy.validate(next) ??
              (next != confirm
                  ? 'The new passwords do not match.'
                  : next == current
                  ? 'The new password must be different from the current one.'
                  : null);
    if (problem != null) {
      setState(() => _errorMessage = problem);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final controller = AuthenticationDependencies.controller;
    final bool success = await controller.changePassword(
      currentPassword: current,
      newPassword: next,
    );
    if (!mounted) return;

    if (!success) {
      setState(() {
        _isSaving = false;
        _errorMessage =
            controller.errorMessage ?? 'Unable to change the password. Please try again.';
      });
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Password changed'),
        content: const Text(
          'Your password has been changed and your other devices were signed out. '
          'Please sign in again with your new password.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
    await controller.signOut();
    if (!mounted) return;
    context.goNamed(AppRouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final String newPassword = _newController.text;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(AppIcons.arrowBack),
          tooltip: 'Back',
        ),
        title: const Text('Change Password'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxlPlus),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Enter your current password, then choose a new one.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.section),
              if (_errorMessage != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.errorSurface,
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: AppSpacing.section),
              ],
              AppPasswordField(
                controller: _currentController,
                label: 'Current Password',
              ),
              const SizedBox(height: AppSpacing.xl),
              AppPasswordField(
                controller: _newController,
                label: 'New Password',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final rule in PasswordPolicy.rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        rule.test(newPassword) ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 16,
                        color: rule.test(newPassword) ? AppColors.success : AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(rule.label, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppPasswordField(
                controller: _confirmController,
                label: 'Confirm New Password',
              ),
              const SizedBox(height: AppSpacing.xxlPlus),
              PrimaryButton(
                label: _isSaving ? 'Changing password...' : 'Change Password',
                onPressed: _isSaving ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
