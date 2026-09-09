import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    this.initialIdentifier = '',
  });

  final String initialIdentifier;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _identifierController;
  late final TextEditingController _otpController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _identifierController = TextEditingController(text: widget.initialIdentifier);
    _otpController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_isLoading) return;

    final String identifier = _identifierController.text.trim();
    final String otp = _otpController.text.trim();
    final String password = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (identifier.isEmpty) {
      _showMessage('Enter your email address to continue.');
      return;
    }
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showMessage('Enter the 6-digit verification code sent to your email.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Passwords do not match.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final bool success = await AuthenticationDependencies.controller.confirmPasswordReset(
      identifier: identifier,
      otp: otp,
      newPassword: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully. Please sign in.'),
          ),
        );
      context.goNamed(AppRouteNames.login);
      return;
    }

    final String error = AuthenticationDependencies.controller.errorMessage ??
        'Failed to reset password. Please verify your code and try again.';
    setState(() => _errorMessage = error);
    _showMessage(error);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _backToLogin() => context.goNamed(AppRouteNames.login);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _backToLogin,
          icon: const Icon(AppIcons.arrowBack),
          tooltip: 'Back to login',
        ),
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.xxlPlus),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.authenticationContentMaxWidth,
              ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxlPlus),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: _StateIcon(
                          backgroundColor: AppColors.primarySurface,
                          color: AppColors.primary,
                          icon: AppIcons.lock,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.section),
                      const Text('Set New Password', style: AppTextStyles.headingLarge),
                      const SizedBox(height: AppSpacing.lg),
                      const Text(
                        'Enter the 6-digit verification code sent to your email and your new password.',
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
                      AppTextField(
                        autofillHints: const <String>[AutofillHints.email],
                        controller: _identifierController,
                        hintText: 'you@business.com',
                        icon: AppIcons.email,
                        keyboardType: TextInputType.emailAddress,
                        label: 'Email Address',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppTextField(
                        controller: _otpController,
                        hintText: '123456',
                        icon: AppIcons.lock,
                        keyboardType: TextInputType.number,
                        label: '6-Digit Verification Code',
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppPasswordField(
                        controller: _passwordController,
                        label: 'New Password',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                      ),
                      const SizedBox(height: AppSpacing.xxlPlus),
                      PrimaryButton(
                        label: _isLoading ? 'Resetting password...' : 'Reset Password',
                        onPressed: _isLoading ? null : _handleResetPassword,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: TextButton(
                          onPressed: _backToLogin,
                          child: const Text('Back to Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  const _StateIcon({
    required this.backgroundColor,
    required this.color,
    required this.icon,
  });

  final Color backgroundColor;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.cardRadius,
      ),
      child: SizedBox.square(
        dimension: AppSizes.emptyStateIcon,
        child: Icon(icon, color: color, size: AppIconSizes.h),
      ),
    );
  }
}
