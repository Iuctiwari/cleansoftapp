import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/notifications/controllers/notification_controller.dart';
import 'package:nexoraa_mobile/features/notifications/screens/notification_screen.dart';
import 'package:nexoraa_mobile/features/notifications/services/notification_api_service.dart';

class _FakeTokenStorage implements AuthTokenStorage {
  _FakeTokenStorage(this.session);
  AuthenticationSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<AuthenticationSession?> read() async => session;

  @override
  Future<void> write(AuthenticationSession value) async => session = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notification Read & Disappear Behavior', () {
    late AuthenticationSession session;

    setUp(() {
      session = AuthenticationSession(
        accessToken: 'tok',
        accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
        refreshToken: 'ref',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
        roleCode: 'Owner',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
      );
    });

    testWidgets(
      'Tapping a notification marks it as read and immediately removes it from the panel',
      (WidgetTester tester) async {
        final List<Map<String, dynamic>> fakeNotifications = [
          {
            'id': 'notif-1',
            'tenantId': 'tenant-1',
            'branchId': 'branch-1',
            'recipientId': 'user-1',
            'type': 'System',
            'title': 'System Update',
            'message': 'System maintenance scheduled',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'notif-2',
            'tenantId': 'tenant-1',
            'branchId': 'branch-1',
            'recipientId': 'user-1',
            'type': 'System',
            'title': 'New Feature',
            'message': 'Check out new reports',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ];

        bool markReadCalled = false;

        final client = MockClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.contains('/notifications/unread-count')) {
            return http.Response(
              jsonEncode({'count': fakeNotifications.length}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET' &&
              request.url.path.contains('/notifications')) {
            return http.Response(
              jsonEncode({
                'items': fakeNotifications,
                'page': 1,
                'limit': 20,
                'total': fakeNotifications.length,
                'totalPages': 1,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'PATCH' && request.url.path.contains('/read')) {
            markReadCalled = true;
            return http.Response(
              jsonEncode({...fakeNotifications[0], 'isRead': true}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        });

        final service = NotificationApiService(
          client: client,
          tokenStorage: _FakeTokenStorage(session),
        );
        final controller = NotificationController(service: service);
        controller.selectBranch('branch-1');

        await tester.pumpWidget(
          MaterialApp(home: NotificationScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        // Initially both notifications appear
        expect(find.text('System Update'), findsOneWidget);
        expect(find.text('New Feature'), findsOneWidget);

        // Tap the first notification
        await tester.tap(find.text('System Update'));
        await tester.pumpAndSettle();

        expect(markReadCalled, isTrue);

        // The tapped notification is immediately removed from the panel
        expect(find.text('System Update'), findsNothing);
        expect(find.text('New Feature'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Mark all as read removes all notifications immediately and displays empty state',
      (WidgetTester tester) async {
        final List<Map<String, dynamic>> fakeNotifications = [
          {
            'id': 'notif-1',
            'tenantId': 'tenant-1',
            'branchId': 'branch-1',
            'recipientId': 'user-1',
            'type': 'System',
            'title': 'System Update',
            'message': 'System maintenance scheduled',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
          {
            'id': 'notif-2',
            'tenantId': 'tenant-1',
            'branchId': 'branch-1',
            'recipientId': 'user-1',
            'type': 'System',
            'title': 'New Feature',
            'message': 'Check out new reports',
            'isRead': false,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        ];

        bool markAllReadCalled = false;

        final client = MockClient((http.Request request) async {
          if (request.method == 'GET' &&
              request.url.path.contains('/notifications/unread-count')) {
            return http.Response(
              jsonEncode({'count': fakeNotifications.length}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'GET' &&
              request.url.path.contains('/notifications')) {
            return http.Response(
              jsonEncode({
                'items': fakeNotifications,
                'page': 1,
                'limit': 20,
                'total': fakeNotifications.length,
                'totalPages': 1,
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.method == 'PATCH' &&
              request.url.path.contains('/read-all')) {
            markAllReadCalled = true;
            return http.Response(
              jsonEncode({'modifiedCount': 2}),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        });

        final service = NotificationApiService(
          client: client,
          tokenStorage: _FakeTokenStorage(session),
        );
        final controller = NotificationController(service: service);
        controller.selectBranch('branch-1');

        await tester.pumpWidget(
          MaterialApp(home: NotificationScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        // Both notifications appear and "Mark all read" button is visible
        expect(find.text('System Update'), findsOneWidget);
        expect(find.text('New Feature'), findsOneWidget);
        expect(find.text('Mark all read'), findsOneWidget);

        // Tap "Mark all read"
        await tester.tap(find.text('Mark all read'));
        await tester.pumpAndSettle();

        expect(markAllReadCalled, isTrue);

        // All notifications are removed and empty state is displayed
        expect(find.text('System Update'), findsNothing);
        expect(find.text('New Feature'), findsNothing);
        expect(find.text('No notifications'), findsOneWidget);
        expect(find.text("You're all caught up!"), findsOneWidget);
        expect(find.text('Mark all read'), findsNothing);
      },
    );
  });
}
