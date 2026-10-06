import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/password_policy.dart';

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
      _showMessage(context.l10n.enterEmailToContinue);
      return;
    }
    if (otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showMessage(context.l10n.enterSixDigitCode);
      return;
    }
    final String? passwordProblem = PasswordPolicy.validate(password, context.l10n);
    if (passwordProblem != null) {
      _showMessage(passwordProblem);
      return;
    }
    if (password != confirmPassword) {
      _showMessage(context.l10n.passwordsDoNotMatch);
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
          SnackBar(
            content: Text(context.l10n.passwordResetSuccess),
          ),
        );
      context.goNamed(AppRouteNames.login);
      return;
    }

    final String error = AuthenticationDependencies.controller.errorMessage ??
        context.l10n.passwordResetFailed;
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
          tooltip: context.l10n.backToLoginTooltip,
        ),
        title: Text(context.l10n.resetPasswordTitle),
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
                      Text(context.l10n.setNewPassword, style: AppTextStyles.headingLarge),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        context.l10n.resetPasswordBody,
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
                        label: context.l10n.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppTextField(
                        controller: _otpController,
                        hintText: '123456',
                        icon: AppIcons.lock,
                        keyboardType: TextInputType.number,
                        label: context.l10n.verificationCodeLabel,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppPasswordField(
                        controller: _passwordController,
                        label: context.l10n.newPassword,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(context.l10n.passwordPolicyHint, style: AppTextStyles.bodySmall),
                      const SizedBox(height: AppSpacing.xl),
                      AppPasswordField(
                        controller: _confirmPasswordController,
                        label: context.l10n.confirmNewPassword,
                      ),
                      const SizedBox(height: AppSpacing.xxlPlus),
                      PrimaryButton(
                        label: _isLoading
                            ? context.l10n.resettingPassword
                            : context.l10n.resetPasswordTitle,
                        onPressed: _isLoading ? null : _handleResetPassword,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: TextButton(
                          onPressed: _backToLogin,
                          child: Text(context.l10n.backToLogin),
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
