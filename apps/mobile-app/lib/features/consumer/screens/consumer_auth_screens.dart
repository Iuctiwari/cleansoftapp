import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/core/phone/phone_verifier.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_auth_scaffold.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';

/// What the verify screen needs: the email, and the password so it can sign
/// in straight after a successful code.
class ConsumerVerifyArgs {
  const ConsumerVerifyArgs({required this.email, this.password, this.deliveryHint});

  final String email;
  final String? password;
  final String? deliveryHint;
}

// ── Sign in ──────────────────────────────────────────────────────────────────

class ConsumerLoginScreen extends StatefulWidget {
  const ConsumerLoginScreen({super.key});

  @override
  State<ConsumerLoginScreen> createState() => _ConsumerLoginScreenState();
}

class _ConsumerLoginScreenState extends State<ConsumerLoginScreen> {
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final String identifier = _identifier.text.trim();
    if (identifier.isEmpty || _password.text.isEmpty) {
      context.showConsumerToast(context.l10n.loginMissingCredentials);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      await ConsumerDependencies.controller.signIn(identifier: identifier, password: _password.text);
      if (mounted) context.goNamed(AppRouteNames.consumerHome);
    } on ConsumerApiException catch (error) {
      if (mounted) setState(() => _busy = false);
      if (!mounted) return;
      if (error.code == 'auth.email_not_verified' && identifier.contains('@')) {
        // Send a fresh code and finish verification.
        unawaited(ConsumerDependencies.api.resendVerification(email: identifier).catchError((Object _) => 0));
        context.pushNamed(
          AppRouteNames.consumerVerify,
          extra: ConsumerVerifyArgs(email: identifier, password: _password.text),
        );
      } else {
        await context.showConsumerError(error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConsumerAuthScaffold(
      title: context.l10n.consumerLoginTitle,
      subtitle: context.l10n.consumerLoginSubtitle,
      children: <Widget>[
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppTextField(
                key: const Key('consumerLogin.identifier'),
                controller: _identifier,
                label: context.l10n.consumerIdentifierLabel,
                icon: AppIcons.user,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email, AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppPasswordField(controller: _password, label: context.l10n.password),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: AppLinkButton(
            label: context.l10n.forgotPassword,
            onPressed: () => context.pushNamed(AppRouteNames.consumerForgotPassword),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ConsumerPrimaryButton(
          key: const Key('consumerLogin.submit'),
          label: context.l10n.signIn,
          busy: _busy,
          onPressed: _signIn,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppDivider(label: context.l10n.consumerNewHere),
        const SizedBox(height: AppSpacing.xl),
        SecondaryButton(
          label: context.l10n.consumerCreateAccount,
          onPressed: () => context.pushNamed(AppRouteNames.consumerSignup),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: AppLinkButton(
            label: context.l10n.consumerBusinessLink,
            onPressed: () => context.goNamed(AppRouteNames.login),
          ),
        ),
      ],
    );
  }
}

// ── Create account ───────────────────────────────────────────────────────────

class ConsumerSignupScreen extends StatefulWidget {
  const ConsumerSignupScreen({super.key});

  @override
  State<ConsumerSignupScreen> createState() => _ConsumerSignupScreenState();
}

class _ConsumerSignupScreenState extends State<ConsumerSignupScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _mobile = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_name, _email, _mobile, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      final String hint = await ConsumerDependencies.api.register(
        fullName: _name.text,
        email: _email.text,
        mobileNumber: _mobile.text,
        password: _password.text,
      );
      if (!mounted) return;
      context.pushReplacementNamed(
        AppRouteNames.consumerVerify,
        extra: ConsumerVerifyArgs(email: _email.text.trim(), password: _password.text, deliveryHint: hint),
      );
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (mounted) await context.showConsumerError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConsumerAuthScaffold(
      title: context.l10n.consumerSignupTitle,
      subtitle: context.l10n.consumerSignupSubtitle,
      children: <Widget>[
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _name,
                  label: context.l10n.consumerFullName,
                  icon: AppIcons.user,
                  autofillHints: const <String>[AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: (String? v) => (v?.trim().length ?? 0) < 2 ? context.l10n.consumerFullNameRequired : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _mobile,
                  label: context.l10n.consumerMobileNumber,
                  hintText: '98765 43210',
                  icon: AppIcons.phone,
                  keyboardType: TextInputType.phone,
                  autofillHints: const <String>[AutofillHints.telephoneNumber],
                  textInputAction: TextInputAction.next,
                  validator: (String? v) => ConsumerValidators.mobile(context, v),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _email,
                  label: context.l10n.emailAddress,
                  hintText: 'you@example.com',
                  icon: AppIcons.email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (String? v) => ConsumerValidators.email(context, v),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _password,
                  label: context.l10n.password,
                  icon: AppIcons.lock,
                  obscureText: true,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: (String? v) => ConsumerValidators.password(context, v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(context.l10n.passwordPolicyHint, style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _confirm,
                  label: context.l10n.consumerConfirmPassword,
                  icon: AppIcons.lock,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (String? v) => v == _password.text ? null : context.l10n.passwordsDoNotMatch,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ConsumerPrimaryButton(label: context.l10n.consumerCreateAccount, busy: _busy, onPressed: _submit),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: AppLinkButton(
            label: context.l10n.consumerHaveAccount,
            onPressed: () => context.canPop() ? context.pop() : context.goNamed(AppRouteNames.consumerLogin),
          ),
        ),
      ],
    );
  }
}

// ── Verify email ─────────────────────────────────────────────────────────────

class ConsumerVerifyEmailScreen extends StatefulWidget {
  const ConsumerVerifyEmailScreen({required this.args, super.key});

  final ConsumerVerifyArgs args;

  @override
  State<ConsumerVerifyEmailScreen> createState() => _ConsumerVerifyEmailScreenState();
}

class _ConsumerVerifyEmailScreenState extends State<ConsumerVerifyEmailScreen> {
  final TextEditingController _code = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _phoneCode = TextEditingController();
  bool _phoneMode = false;
  PhoneCodeSession? _phoneSession;
  String? _phoneSentTo;
  bool _busy = false;
  int _wait = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown(60);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    _phone.dispose();
    _phoneCode.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _wait = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted || _wait <= 1) {
        timer.cancel();
        if (mounted) setState(() => _wait = 0);
        return;
      }
      setState(() => _wait--);
    });
  }

  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      context.showConsumerToast(context.l10n.enterSixDigitCode);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      await ConsumerDependencies.api.verifyEmail(email: widget.args.email, otp: _code.text);
      // A brand-new customer adds their address straight away.
      await _afterVerified();
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (mounted) await context.showConsumerError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// After either kind of code is accepted: sign in (new sign-up) or go to the sign-in screen.
  Future<void> _afterVerified() async {
    final String? password = widget.args.password;
    if (password != null) {
      await ConsumerDependencies.controller.signIn(identifier: widget.args.email, password: password);
      if (mounted) context.goNamed(AppRouteNames.consumerHome);
    } else if (mounted) {
      context.goNamed(AppRouteNames.consumerLogin);
    }
  }

  Future<void> _sendPhoneCode() async {
    final String digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    final String ten = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (ten.length != 10) {
      context.showConsumerToast(context.l10n.consumerPhoneInvalid);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      final PhoneCodeSession session = await PhoneVerification.verifier.sendCode('+91$ten');
      if (!mounted) return;
      setState(() {
        _phoneSession = session;
        _phoneSentTo = '+91 $ten';
        _busy = false;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (mounted) await _showPhoneError(error);
    }
  }

  Future<void> _verifyPhone() async {
    final PhoneCodeSession? session = _phoneSession;
    if (session == null) return;
    if (!RegExp(r'^\d{6}$').hasMatch(_phoneCode.text.trim())) {
      context.showConsumerToast(context.l10n.enterSixDigitCode);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    try {
      final String idToken = await session.confirm(_phoneCode.text);
      await ConsumerDependencies.api.verifyPhone(email: widget.args.email, idToken: idToken);
      await _afterVerified();
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (mounted) await _showPhoneError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPhoneError(Object error) async {
    if (error is PhoneVerificationException) {
      await AppAlertDialog.show(context, title: AppAlertDialog.titleFor(error.message), message: error.message);
    } else {
      await context.showConsumerError(error);
    }
  }

  Future<void> _resend() async {
    try {
      final int wait = await ConsumerDependencies.api.resendVerification(email: widget.args.email);
      if (!mounted) return;
      context.showConsumerToast(context.l10n.consumerCodeSent);
      _startCountdown(wait);
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (mounted) await context.showConsumerError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConsumerAuthScaffold(
      title: context.l10n.consumerVerifyTitle,
      subtitle: context.l10n.consumerVerifySubtitle(widget.args.email),
      children: _phoneMode ? _phoneChildren(context) : <Widget>[
        TextField(
          key: const Key('consumerVerify.code'),
          controller: _code,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.headingLarge.copyWith(letterSpacing: 8),
          decoration: InputDecoration(labelText: context.l10n.verificationCodeLabel, counterText: ''),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ConsumerPrimaryButton(label: context.l10n.consumerVerifyButton, busy: _busy, onPressed: _verify),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: _wait > 0 ? null : _resend,
            child: Text(_wait > 0 ? context.l10n.consumerResendIn(_wait) : context.l10n.consumerResendCode),
          ),
        ),
        Center(
          child: TextButton(
            key: const Key('consumerVerify.phoneToggle'),
            onPressed: () => setState(() => _phoneMode = true),
            child: Text(context.l10n.consumerPhoneInstead),
          ),
        ),
      ],
    );
  }

  List<Widget> _phoneChildren(BuildContext context) {
    final bool sent = _phoneSession != null;
    return <Widget>[
      if (!sent) ...<Widget>[
        TextField(
          key: const Key('consumerVerify.phone'),
          controller: _phone,
          autofocus: true,
          keyboardType: TextInputType.phone,
          maxLength: 13,
          decoration: InputDecoration(labelText: context.l10n.consumerPhoneLabel, prefixText: '+91 ', counterText: ''),
          onSubmitted: (_) => _sendPhoneCode(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ConsumerPrimaryButton(
          key: const Key('consumerVerify.phoneSend'),
          label: context.l10n.consumerPhoneSend,
          busy: _busy,
          onPressed: _sendPhoneCode,
        ),
      ] else ...<Widget>[
        Text(context.l10n.consumerPhoneSentTo(_phoneSentTo ?? ''), textAlign: TextAlign.center, style: AppTextStyles.bodySmall),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const Key('consumerVerify.phoneCode'),
          controller: _phoneCode,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.headingLarge.copyWith(letterSpacing: 8),
          decoration: InputDecoration(labelText: context.l10n.verificationCodeLabel, counterText: ''),
          onSubmitted: (_) => _verifyPhone(),
        ),
        const SizedBox(height: AppSpacing.xxl),
        ConsumerPrimaryButton(
          key: const Key('consumerVerify.phoneConfirm'),
          label: context.l10n.consumerVerifyButton,
          busy: _busy,
          onPressed: _verifyPhone,
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Center(
        child: TextButton(
          key: const Key('consumerVerify.emailToggle'),
          onPressed: () => setState(() {
            _phoneMode = false;
            _phoneSession = null;
          }),
          child: Text(context.l10n.consumerPhoneUseEmail),
        ),
      ),
    ];
  }
}

// ── Forgot password ──────────────────────────────────────────────────────────

class ConsumerForgotPasswordScreen extends StatefulWidget {
  const ConsumerForgotPasswordScreen({super.key});

  @override
  State<ConsumerForgotPasswordScreen> createState() => _ConsumerForgotPasswordScreenState();
}

class _ConsumerForgotPasswordScreenState extends State<ConsumerForgotPasswordScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _code = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[_identifier, _code, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_identifier.text.trim().isEmpty) {
      context.showConsumerToast(context.l10n.consumerIdentifierRequired);
      return;
    }
    setState(() => _busy = true);
    try {
      await ConsumerDependencies.api.requestPasswordReset(identifier: _identifier.text);
      if (mounted) setState(() => _codeSent = true);
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (mounted) await context.showConsumerError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ConsumerDependencies.api.resetPassword(
        identifier: _identifier.text,
        otp: _code.text,
        newPassword: _password.text,
      );
      if (!mounted) return;
      context.showConsumerToast(context.l10n.consumerPasswordResetDone);
      context.goNamed(AppRouteNames.consumerLogin);
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (mounted) await context.showConsumerError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConsumerAuthScaffold(
      title: context.l10n.consumerForgotTitle,
      subtitle: _codeSent ? context.l10n.codeSentGeneric : context.l10n.consumerForgotSubtitle,
      children: <Widget>[
        AppTextField(
          controller: _identifier,
          label: context.l10n.consumerIdentifierLabel,
          icon: AppIcons.user,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!_codeSent)
          ConsumerPrimaryButton(label: context.l10n.consumerSendCode, busy: _busy, onPressed: _sendCode)
        else
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppTextField(
                  controller: _code,
                  label: context.l10n.verificationCodeLabel,
                  icon: AppIcons.key,
                  keyboardType: TextInputType.number,
                  validator: (String? v) =>
                      RegExp(r'^\d{6}$').hasMatch(v?.trim() ?? '') ? null : context.l10n.enterSixDigitCode,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _password,
                  label: context.l10n.newPassword,
                  icon: AppIcons.lock,
                  obscureText: true,
                  validator: (String? v) => ConsumerValidators.password(context, v),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _confirm,
                  label: context.l10n.consumerConfirmPassword,
                  icon: AppIcons.lock,
                  obscureText: true,
                  validator: (String? v) => v == _password.text ? null : context.l10n.passwordsDoNotMatch,
                ),
                const SizedBox(height: AppSpacing.xxl),
                ConsumerPrimaryButton(label: context.l10n.consumerResetButton, busy: _busy, onPressed: _reset),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : _sendCode,
                    child: Text(context.l10n.consumerResendCode),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
