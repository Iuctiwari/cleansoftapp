import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

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

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: 'admin@nexoraa.com');
    _passwordController = TextEditingController(text: 'password');
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
    // TODO(frontend): Navigate when the forgot-password screen is available.
  }

  void _handleSignIn() {
    // TODO(frontend): Connect UI behavior after authentication integration.
  }

  void _handleCreateBusinessAccount() {
    // TODO(frontend): Navigate when the registration screen is available.
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
                            PrimaryButton(
                              label: 'Sign In',
                              onPressed: _handleSignIn,
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
