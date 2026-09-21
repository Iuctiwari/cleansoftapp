import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

/// Wraps every screen under /company-admin/* except the login screen itself.
/// Checks for a valid, non-expired AdminSession on mount; if missing, sends
/// the visitor back to the admin login screen. This is deliberately a
/// per-screen check rather than a go_router `redirect` rule — the router's
/// redirect is synchronous and driven by tenant auth state
/// (AuthenticationDependencies.controller); mixing an async, unrelated admin
/// session check into it would couple two auth systems that must stay separate.
class AdminSessionGate extends StatefulWidget {
  const AdminSessionGate({required this.child, super.key});

  final Widget child;

  @override
  State<AdminSessionGate> createState() => _AdminSessionGateState();
}

class _AdminSessionGateState extends State<AdminSessionGate> {
  bool _checked = false;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final AdminSession? session = await CompanyAdminDependencies.tokenStorage.read();
    final bool authorized =
        session != null && session.accessTokenExpiresAt.isAfter(DateTime.now().toUtc());
    if (!mounted) return;
    if (!authorized) {
      context.go(AppRoutes.companyAdminLogin);
      return;
    }
    setState(() {
      _checked = true;
      _authorized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked || !_authorized) {
      return const Scaffold(body: AppLoadingView());
    }
    return widget.child;
  }
}
