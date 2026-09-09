import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isLoading = false;
  bool _codeSent = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetCode() async {
    if (_isLoading) return;

    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email address to continue.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final bool success = await AuthenticationDependencies.controller
        .requestPasswordReset(identifier: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _codeSent = true);
      _showMessage('If the account is eligible, a verification code has been sent.');
      try {
        context.pushNamed(AppRouteNames.resetPassword, extra: email);
      } catch (_) {
        // Fallback when GoRouter is not in the widget tree (e.g. unit tests)
      }
      return;
    }

    final String error = AuthenticationDependencies.controller.errorMessage ??
        'Unable to send verification code. Please try again.';
    setState(() => _errorMessage = error);
    _showMessage(error);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _backToLogin() => context.goNamed(AppRouteNames.login);

  void _goToResetPassword() {
    context.pushNamed(
      AppRouteNames.resetPassword,
      extra: _emailController.text.trim(),
    );
  }

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
                  child: AnimatedSwitcher(
                    duration: AppDurations.medium,
                    switchInCurve: AppCurves.easeOut,
                    child: _codeSent
                        ? _SuccessState(
                            key: const ValueKey<String>('success'),
                            email: _emailController.text.trim(),
                            onBackToLogin: _backToLogin,
                            onEnterCode: _goToResetPassword,
                          )
                        : _RequestState(
                            key: const ValueKey<String>('request'),
                            emailController: _emailController,
                            isLoading: _isLoading,
                            errorMessage: _errorMessage,
                            onBackToLogin: _backToLogin,
                            onSendResetCode: _handleSendResetCode,
                          ),
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

class _RequestState extends StatelessWidget {
  const _RequestState({
    required this.emailController,
    required this.isLoading,
    required this.errorMessage,
    required this.onBackToLogin,
    required this.onSendResetCode,
    super.key,
  });

  final TextEditingController emailController;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onBackToLogin;
  final VoidCallback onSendResetCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Align(
          alignment: Alignment.centerLeft,
          child: _StateIcon(
            backgroundColor: AppColors.primarySurface,
            color: AppColors.primary,
            icon: AppIcons.email,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const Text('Forgot your password?', style: AppTextStyles.headingLarge),
        const SizedBox(height: AppSpacing.lg),
        const Text(
          "Enter your email address and we'll send you a 6-digit verification code to reset your password.",
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.section),
        if (errorMessage != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              borderRadius: AppRadius.cardRadius,
            ),
            child: Text(
              errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          const SizedBox(height: AppSpacing.section),
        ],
        AppTextField(
          autofillHints: const <String>[AutofillHints.email],
          controller: emailController,
          hintText: 'you@business.com',
          icon: AppIcons.email,
          keyboardType: TextInputType.emailAddress,
          label: 'Email Address',
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.xxlPlus),
        PrimaryButton(
          label: isLoading ? 'Sending code...' : 'Send verification code',
          onPressed: isLoading ? null : onSendResetCode,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppLinkButton(label: 'Back to Login', onPressed: onBackToLogin),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({
    required this.email,
    required this.onBackToLogin,
    required this.onEnterCode,
    super.key,
  });

  final String email;
  final VoidCallback onBackToLogin;
  final VoidCallback onEnterCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Align(
          alignment: Alignment.centerLeft,
          child: _StateIcon(
            backgroundColor: AppColors.primarySurface,
            color: AppColors.primary,
            icon: AppIcons.brandCheck,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const Text('Check your email', style: AppTextStyles.headingLarge),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'If the account is eligible, a verification code has been sent to $email. Follow the instructions to reset your password.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.section),
        PrimaryButton(label: 'Enter Verification Code', onPressed: onEnterCode),
        const SizedBox(height: AppSpacing.xl),
        AppLinkButton(label: 'Back to Login', onPressed: onBackToLogin),
      ],
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
