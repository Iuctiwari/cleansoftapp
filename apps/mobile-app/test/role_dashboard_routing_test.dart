import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/role_dashboard_screen.dart';

void main() {
  group('role dashboard routing', () {
    test('Owner opens the existing Owner dashboard', () {
      expect(AppRouter.dashboardLocationForRole('Owner'), AppRoutes.dashboard);
      expect(AppRouter.roleDashboardKindForRole('Owner'), isNull);
    });

    test('Staff opens the Staff dashboard', () {
      expect(
        AppRouter.dashboardLocationForRole('Staff'),
        AppRoutes.staffDashboard,
      );
      expect(
        AppRouter.roleDashboardKindForRole('Staff'),
        RoleDashboardKind.staff,
      );
    });

    test('Branch Manager opens the Branch Manager dashboard', () {
      expect(
        AppRouter.dashboardLocationForRole('Branch Manager'),
        AppRoutes.staffDashboard,
      );
      expect(
        AppRouter.roleDashboardKindForRole('Branch Manager'),
        RoleDashboardKind.branchManager,
      );
    });

    test('Cashier preserves its existing dashboard destination', () {
      expect(
        AppRouter.dashboardLocationForRole('Cashier'),
        AppRoutes.dashboard,
      );
      expect(AppRouter.roleDashboardKindForRole('Cashier'), isNull);
    });
  });
}
