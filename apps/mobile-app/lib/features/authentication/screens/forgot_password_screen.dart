import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _linkSent = false;

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

  void _sendResetLink() {
    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Enter your email address to continue.'),
          ),
        );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _linkSent = true);
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
                  child: AnimatedSwitcher(
                    duration: AppDurations.medium,
                    switchInCurve: AppCurves.easeOut,
                    child: _linkSent
                        ? _SuccessState(
                            key: const ValueKey<String>('success'),
                            email: _emailController.text.trim(),
                            onBackToLogin: _backToLogin,
                          )
                        : _RequestState(
                            key: const ValueKey<String>('request'),
                            emailController: _emailController,
                            onBackToLogin: _backToLogin,
                            onSendResetLink: _sendResetLink,
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
    required this.onBackToLogin,
    required this.onSendResetLink,
    super.key,
  });

  final TextEditingController emailController;
  final VoidCallback onBackToLogin;
  final VoidCallback onSendResetLink;

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
          "Enter your email address and we'll send you a link to reset your password.",
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.section),
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
        PrimaryButton(label: 'Send Reset Link', onPressed: onSendResetLink),
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
    super.key,
  });

  final String email;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Align(
          alignment: Alignment.centerLeft,
          child: _StateIcon(
            backgroundColor: AppColors.successSurface,
            color: AppColors.success,
            icon: AppIcons.success,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        const Text('Check your email', style: AppTextStyles.headingLarge),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'We sent a password reset link to $email. Follow the instructions in the email to reset your password.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.section),
        PrimaryButton(label: 'Back to Login', onPressed: onBackToLogin),
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
