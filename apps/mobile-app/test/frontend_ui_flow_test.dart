import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/controllers/authentication_controller.dart';
import 'package:nexoraa_mobile/features/authentication/services/authentication_service.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/notifications/notifications.dart';
import 'package:nexoraa_mobile/features/tenant/services/tenant_api_service.dart';

class _FakeAuthTokenStorage implements AuthTokenStorage {
  final AuthenticationSession _session = AuthenticationSession(
    accessToken: 'test-access-token',
    refreshToken: 'test-refresh-token',
    accessTokenExpiresAt: DateTime.now().add(const Duration(hours: 1)),
    refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
    tenantId: 'tenant-test',
  );

  @override
  Future<void> clear() async {}

  @override
  Future<AuthenticationSession?> read() async => _session;

  @override
  Future<void> write(AuthenticationSession session) async {}
}

class _MockAuthService implements AuthenticationService {
  @override
  Future<AuthenticationSession?> restoreSession() async => null;

  @override
  Future<AuthenticationSession> signIn({required String identifier, required String password}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> requestPasswordReset({required String identifier}) async {}

  @override
  Future<void> confirmPasswordReset({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}
}

Map<String, dynamic> _notificationJson({
  required String id,
  required String title,
  required String message,
  required String type,
  required bool isRead,
}) => <String, dynamic>{
  'id': id,
  'tenantId': 'tenant-test',
  'branchId': 'branch-test',
  'recipientId': 'user-test',
  'title': title,
  'message': message,
  'type': type,
  'isRead': isRead,
  'createdAt': DateTime.now().toUtc().toIso8601String(),
  'updatedAt': DateTime.now().toUtc().toIso8601String(),
};

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final mockAuth = _MockAuthService();
    AuthenticationDependencies.service = mockAuth;
    AuthenticationDependencies.controller = AuthenticationController(service: mockAuth);
  });
  testWidgets('forgot password swaps to the local success state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const ForgotPasswordScreen()),
    );

    expect(find.text('Forgot your password?'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'owner@example.com');
    await tester.tap(find.text('Send verification code'));
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining('owner@example.com'), findsOneWidget);
    expect(
      find.textContaining('If the account is eligible, a verification code has been sent'),
      findsAtLeast(1),
    );
  });

  testWidgets('notification filters and read actions update immediately', (
    WidgetTester tester,
  ) async {
    final MockClient client = MockClient((http.Request request) async {
      if (request.method == 'GET' &&
          request.url.path == '/api/v1/notifications/unread-count') {
        return http.Response(jsonEncode(<String, int>{'count': 2}), 200);
      }
      if (request.method == 'GET' &&
          request.url.path == '/api/v1/notifications/') {
        return http.Response(
          jsonEncode(<String, Object>{
            'items': <Map<String, dynamic>>[
              _notificationJson(
                id: 'n1',
                title: 'New Order Assigned',
                message: 'ORD-1043 has been assigned to Muhammad Asif.',
                type: 'OrderCreated',
                isRead: false,
              ),
              _notificationJson(
                id: 'n2',
                title: 'Payment Received',
                message: 'Rs. 850 collected from Hassan Ali for ORD-1042.',
                type: 'PaymentReceived',
                isRead: false,
              ),
            ],
            'total': 2,
            'page': 1,
            'limit': 20,
            'totalPages': 1,
          }),
          200,
        );
      }
      if (request.method == 'PATCH' &&
          request.url.path == '/api/v1/notifications/n1/read') {
        return http.Response(
          jsonEncode(
            _notificationJson(
              id: 'n1',
              title: 'New Order Assigned',
              message: 'ORD-1043 has been assigned to Muhammad Asif.',
              type: 'OrderCreated',
              isRead: true,
            ),
          ),
          200,
        );
      }
      if (request.method == 'PATCH' &&
          request.url.path == '/api/v1/notifications/read-all') {
        return http.Response(jsonEncode(<String, int>{'modifiedCount': 1}), 200);
      }
      return http.Response('Not found', 404);
    });

    final NotificationController controller = NotificationController(
      service: NotificationApiService(
        tokenStorage: _FakeAuthTokenStorage(),
        client: client,
        baseUrl: 'http://test',
      ),
    )..selectBranch('branch-test');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: NotificationScreen(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New Order Assigned'), findsOneWidget);
    expect(find.text('Payment Received'), findsOneWidget);
    expect(find.text('2 unread notifications'), findsOneWidget);

    final double summaryTop = tester
        .getTopLeft(find.text('2 unread notifications'))
        .dy;
    final double tabsTop = tester.getTopLeft(find.text('All')).dy;
    expect(summaryTop, lessThan(tabsTop));

    final ChoiceChip selectedTab = tester.widget<ChoiceChip>(
      find.byType(ChoiceChip).first,
    );
    expect(selectedTab.labelStyle?.color, AppColors.textPrimary);
    expect(selectedTab.selectedColor, AppColors.primaryMuted);

    await tester.tap(find.text('New Order Assigned'));
    await tester.pumpAndSettle();
    expect(find.text('1 unread notification'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(find.text('Mark all read'), findsNothing);

    await tester.tap(find.text('Staff'));
    await tester.pumpAndSettle();
    expect(find.text('No notifications'), findsOneWidget);
    expect(find.text('Nothing in this category yet.'), findsOneWidget);
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
            tokenStorage: _FakeAuthTokenStorage(),
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
          builder: (_, _) => Scaffold(
            body: MoreScreen(
              businessName: 'Ahmed Laundry',
              onExpensesTap: () {},
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
