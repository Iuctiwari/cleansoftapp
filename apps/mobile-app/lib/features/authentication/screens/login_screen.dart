import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/tenant/models/registration_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _headerController;
  late final Animation<double> _headerAnimation;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _headerController = AnimationController(
      duration: AppDurations.standard,
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerController,
      curve: AppDurations.emphasizedCurve,
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _headerController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleForgotPassword() {
    context.pushNamed(AppRouteNames.forgotPassword);
  }

  Future<void> _handleSignIn() async {
    if (_isLoading) return;

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter your email and password to continue.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);
    final bool authenticated = await AuthenticationDependencies.controller
        .signIn(identifier: email, password: password);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (authenticated) {
      context.goNamed(AppRouteNames.dashboard);
      return;
    }

    _showMessage(
      AuthenticationDependencies.controller.errorMessage ??
          'Invalid email or password',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleCreateBusinessAccount() {
    context.pushNamed(
      AppRouteNames.registerBusinessInfo,
      extra: RegistrationForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          FadeTransition(
            opacity: _headerAnimation,
            child: const _LoginHeader(),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double horizontalPadding =
                    constraints.maxWidth >= AppSizes.tabletBreakpoint
                    ? AppSpacing.section
                    : AppSpacing.xxlPlus;

                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.xxxl,
                    horizontalPadding,
                    AppSpacing.xxxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.authenticationContentMaxWidth,
                      ),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            AppTextField(
                              autofillHints: const <String>[
                                AutofillHints.email,
                              ],
                              controller: _emailController,
                              hintText: 'you@business.com',
                              icon: AppIcons.email,
                              keyboardType: TextInputType.emailAddress,
                              label: 'Email Address',
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AppPasswordField(
                              controller: _passwordController,
                              label: 'Password',
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Align(
                              alignment: Alignment.centerRight,
                              child: AppLinkButton(
                                label: 'Forgot password?',
                                onPressed: _handleForgotPassword,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _SignInButton(
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _handleSignIn,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            const AppDivider(label: 'or'),
                            const SizedBox(height: AppSpacing.xl),
                            SecondaryButton(
                              label: 'Create Business Account',
                              onPressed: _handleCreateBusinessAccount,
                            ),
                            const SizedBox(height: AppSpacing.xxlPlus),
                            const _TermsText(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        PrimaryButton(label: isLoading ? '' : 'Sign In', onPressed: onPressed),
        if (isLoading)
          const SizedBox.square(
            dimension: AppIconSizes.xl,
            child: CircularProgressIndicator(
              color: AppColors.surface,
              strokeWidth: AppBorderWidths.medium,
            ),
          ),
      ],
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.primaryHeader),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: -AppSpacing.display,
            top: -AppSpacing.display,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.whiteOverlay08,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: AppSizes.loginHeaderDecoration),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.authenticationContentMaxWidth,
                ),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xxlPlus,
                    AppSpacing.section,
                    AppSpacing.xxlPlus,
                    AppSpacing.display,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      AppBrandLogo(),
                      SizedBox(height: AppSpacing.xl),
                      Text(
                        'Welcome back',
                        style: AppTextStyles.headingExtraLarge,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Sign in to your business account',
                        style: AppTextStyles.headerSubtitle,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.caption,
        children: <InlineSpan>[
          const TextSpan(text: 'By signing in you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
