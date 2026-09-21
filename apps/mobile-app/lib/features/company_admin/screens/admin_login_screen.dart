import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

/// Reachable only by direct URL (/company-admin) — never linked from any
/// tenant-facing screen or nav item. Uses CompanyAdminApiService exclusively;
/// has no knowledge of, and no shared code path with, the tenant/staff login
/// screen or AuthenticationDependencies.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_isLoading) return;
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Enter the admin email and password to continue.');
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);
    try {
      await CompanyAdminDependencies.apiService.login(email, password);
      if (!mounted) return;
      context.goNamed(AppRouteNames.companyAdminDashboard);
    } on CompanyAdminApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxlPlus),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.authenticationContentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Nexoraa Company Admin', style: AppTextStyles.headingExtraLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Internal access only.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'admin@nexoraa.com',
                    icon: AppIcons.email,
                    keyboardType: TextInputType.emailAddress,
                    label: 'Admin Email',
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppPasswordField(controller: _passwordController, label: 'Password'),
                  const SizedBox(height: AppSpacing.xl),
                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      PrimaryButton(
                        label: _isLoading ? '' : 'Sign In',
                        onPressed: _isLoading ? null : _handleSignIn,
                      ),
                      if (_isLoading)
                        const SizedBox.square(
                          dimension: AppIconSizes.xl,
                          child: CircularProgressIndicator(
                            color: AppColors.surface,
                            strokeWidth: AppBorderWidths.medium,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
