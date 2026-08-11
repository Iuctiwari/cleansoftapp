import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/screens/forgot_password_screen.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_widgets.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/dashboard_placeholder_screen.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/more_screen.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/notification_screen.dart';
import 'package:nexoraa_mobile/features/tenant/services/tenant_api_service.dart';

void main() {
  testWidgets('forgot password swaps to the local success state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ForgotPasswordScreen()),
    );

    expect(find.text('Forgot your password?'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'owner@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('owner@example.com'), findsOneWidget);
  });

  testWidgets('notification filters and read actions update immediately', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const NotificationScreen()),
    );

    expect(find.text('New Order Assigned'), findsOneWidget);
    expect(find.text('Payment Received'), findsOneWidget);
    expect(find.text('2 unread notifications'), findsOneWidget);

    final double summaryTop = tester
        .getTopLeft(find.text('2 unread notifications'))
        .dy;
    final double markAllTop = tester.getTopLeft(find.text('Mark All Read')).dy;
    final double tabsTop = tester.getTopLeft(find.text('All')).dy;
    expect(markAllTop, lessThan(summaryTop));
    expect(summaryTop, lessThan(tabsTop));

    final ChoiceChip selectedTab = tester.widget<ChoiceChip>(
      find.byType(ChoiceChip).first,
    );
    expect(selectedTab.labelStyle?.color, AppColors.textPrimary);
    expect(selectedTab.selectedColor, AppColors.primaryMuted);

    await tester.tap(find.text('New Order Assigned'));
    await tester.pumpAndSettle();
    expect(find.text('1 unread notification'), findsOneWidget);

    await tester.tap(find.text('Mark All Read'));
    await tester.pumpAndSettle();
    expect(find.text('Mark All Read'), findsNothing);

    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();
    expect(find.text('No notifications'), findsOneWidget);
    expect(find.text("You're all caught up!"), findsOneWidget);
  });

  testWidgets('existing More tab opens More screen and remains selected', (
    WidgetTester tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/branches')) {
        return http.Response(
          jsonEncode([
            {'branchId': 'branch-db', 'branchName': 'Database Branch'},
          ]),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'tenantId': 'tenant-db',
          'businessName': 'Database Laundry',
          'ownerName': 'Database Owner',
          'ownerEmail': 'owner@database.test',
        }),
        200,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DashboardPlaceholderScreen(
          tenantId: 'tenant-db',
          tenantApiService: TenantApiService(
            client: client,
            baseUrl: 'http://test',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Database Owner'), findsOneWidget);
    expect(find.textContaining('Database Laundry'), findsOneWidget);
    expect(find.text('Database Branch'), findsOneWidget);
    expect(find.text('Recent Orders'), findsOneWidget);
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Hassan Ali'), findsNothing);

    final double searchWidth = tester
        .getSize(find.byType(DashboardSearchBar))
        .width;
    final double selectorWidth = tester
        .getSize(find.byType(BranchDropdown))
        .width;
    expect(selectorWidth, searchWidth);

    await tester.tap(find.byType(BranchDropdown));
    await tester.pumpAndSettle();
    expect(find.byType(MenuItemButton), findsOneWidget);
    final double menuItemWidth = tester
        .getSize(find.byType(MenuItemButton).first)
        .width;
    expect(menuItemWidth, selectorWidth);

    await tester.tap(find.byType(MenuItemButton));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<BranchDropdown>(find.byType(BranchDropdown))
          .selectedBranchId,
      'branch-db',
    );

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('Finance'.toUpperCase()), findsOneWidget);
    expect(find.text('Database Owner'), findsOneWidget);
    expect(find.text('owner@database.test'), findsOneWidget);
    final BottomNavigationBar navigation = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(navigation.currentIndex, 3);
  });

  testWidgets('sign out confirms, shows feedback, and clears navigation', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: '/more',
      routes: <RouteBase>[
        GoRoute(
          path: '/more',
          builder: (_, _) => const Scaffold(
            body: MoreScreen(
              businessName: 'Ahmed Laundry',
              role: 'Owner',
              userProfile: MoreUserProfileData.placeholder,
            ),
          ),
        ),
        GoRoute(
          name: AppRouteNames.login,
          path: AppRoutes.login,
          builder: (_, _) => const Scaffold(body: Text('Login screen')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.light),
    );

    await tester.ensureVisible(find.text('Sign Out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to sign out?'), findsOneWidget);

    await tester.tap(find.text('Yes, Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Login screen'), findsOneWidget);
    expect(find.text('Signed out successfully'), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
