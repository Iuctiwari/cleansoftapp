import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/screens/admin_session_gate.dart';
import 'package:nexoraa_mobile/features/company_admin/screens/businesses_tab.dart';
import 'package:nexoraa_mobile/features/company_admin/screens/clients_tab.dart';
import 'package:nexoraa_mobile/features/company_admin/screens/settings_tab.dart';
import 'package:nexoraa_mobile/features/company_admin/screens/subscriptions_tab.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

const List<String> _kTabTitles = <String>['Subscriptions', 'Businesses', 'Clients', 'Settings'];

/// Lands here right after admin login. Bottom-nav host for the 4 Company
/// Admin sections — switching tabs is local state (IndexedStack), never a
/// route change, so there is nothing to "go back" out of between tabs.
/// Drilling into a specific plan/business type/tenant pushes a real route
/// with its own AppBar back arrow — see each tab body for those calls.
class CompanyAdminShellScreen extends StatefulWidget {
  const CompanyAdminShellScreen({super.key});

  @override
  State<CompanyAdminShellScreen> createState() => _CompanyAdminShellScreenState();
}

class _CompanyAdminShellScreenState extends State<CompanyAdminShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AdminSessionGate(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_kTabTitles[_index]),
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              icon: const Icon(AppIcons.logout),
              tooltip: 'Log out',
              onPressed: () async {
                await CompanyAdminDependencies.apiService.logout();
                if (context.mounted) context.go(AppRoutes.companyAdminLogin);
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _index,
          children: const <Widget>[
            SubscriptionsTab(),
            BusinessesTab(),
            ClientsTab(),
            SettingsTab(),
          ],
        ),
        bottomNavigationBar: _CompanyAdminBottomNavigation(
          currentIndex: _index,
          onTap: (int value) => setState(() => _index = value),
        ),
      ),
    );
  }
}

class _CompanyAdminBottomNavigation extends StatelessWidget {
  const _CompanyAdminBottomNavigation({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: AppBorders.bottomNavigation,
        boxShadow: AppShadows.subtle,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.bottomNavigation,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            type: BottomNavigationBarType.fixed,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(AppIcons.wallet), label: 'Subscriptions'),
              BottomNavigationBarItem(icon: Icon(AppIcons.tag), label: 'Businesses'),
              BottomNavigationBarItem(icon: Icon(AppIcons.branch), label: 'Clients'),
              BottomNavigationBarItem(icon: Icon(AppIcons.settings), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
