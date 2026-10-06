import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
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
      _showMessage(context.l10n.loginMissingCredentials);
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
          context.l10n.loginInvalidCredentials,
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

  void _handleCompanyAdmin() {
    context.pushNamed(AppRouteNames.companyAdminLogin);
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
                              label: context.l10n.emailAddress,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AppPasswordField(
                              controller: _passwordController,
                              label: context.l10n.password,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Align(
                              alignment: Alignment.centerRight,
                              child: AppLinkButton(
                                label: context.l10n.forgotPassword,
                                onPressed: _handleForgotPassword,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            _SignInButton(
                              isLoading: _isLoading,
                              onPressed: _isLoading ? null : _handleSignIn,
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            AppDivider(label: context.l10n.commonOr),
                            const SizedBox(height: AppSpacing.xl),
                            SecondaryButton(
                              label: context.l10n.createBusinessAccount,
                              onPressed: _handleCreateBusinessAccount,
                            ),
                            const SizedBox(height: AppSpacing.xxlPlus),
                            const _TermsText(),
                            const SizedBox(height: AppSpacing.xl),
                            Align(
                              alignment: Alignment.center,
                              child: AppLinkButton(
                                label: context.l10n.companyAdmin,
                                onPressed: _handleCompanyAdmin,
                              ),
                            ),
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
        PrimaryButton(
          label: isLoading ? '' : context.l10n.signIn,
          onPressed: onPressed,
        ),
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxlPlus,
                    AppSpacing.section,
                    AppSpacing.xxlPlus,
                    AppSpacing.display,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          AppBrandLogo(),
                          Spacer(),
                          LanguageSelectorButton(onDark: true),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        context.l10n.loginWelcomeBack,
                        style: AppTextStyles.headingExtraLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        context.l10n.loginSubtitle,
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
          TextSpan(text: context.l10n.termsAgreementPrefix),
          TextSpan(
            text: context.l10n.termsOfService,
            style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
          ),
          TextSpan(text: context.l10n.termsAgreementSuffix),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
