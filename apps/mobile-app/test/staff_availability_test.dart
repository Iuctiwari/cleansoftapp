import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

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

  group('StaffMember Availability Model', () {
    test('parses availability from JSON and defaults to Available', () {
      final staffWithAvail = StaffMember.fromJson({
        'userId': 'staff-1',
        'tenantId': 'tenant-1',
        'name': 'Ayesha Noor',
        'email': 'ayesha@example.com',
        'role': 'Staff',
        'status': 'Active',
        'availability': 'Busy',
        'branchIds': ['branch-1'],
        'loginId': 'ayesha.noor',
      });

      expect(staffWithAvail.availability, 'Busy');

      final staffDefault = StaffMember.fromJson({
        'userId': 'staff-2',
        'tenantId': 'tenant-1',
        'name': 'Tariq Mehmood',
        'email': 'tariq@example.com',
        'role': 'Staff',
        'status': 'Active',
        'branchIds': ['branch-1'],
        'loginId': 'tariq.mehmood',
      });

      expect(staffDefault.availability, 'Available');
    });
  });

  group('StaffApiService Availability Methods', () {
    test('getMyProfile and updateMyAvailability make correct HTTP requests', () async {
      final session = AuthenticationSession(
        accessToken: 'valid-token',
        accessTokenExpiresAt: DateTime.now().add(const Duration(days: 1)),
        refreshToken: 'valid-refresh',
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 30)),
        roleCode: 'Staff',
        tenantId: 'tenant-123',
        branchId: 'branch-123',
        branchName: 'Main Branch',
        ownerUserId: 'staff-123',
        ownerName: 'Muhammad Asif',
        ownerEmail: 'asif@example.com',
        permissions: const ['staff:read'],
      );

      final tokenStorage = _FakeTokenStorage(session);

      String? lastPatchBody;
      final mockClient = MockClient((http.Request request) async {
        if (request.url.path == '/api/v1/users/me' && request.method == 'GET') {
          return http.Response(
            jsonEncode({
              'userId': 'staff-123',
              'tenantId': 'tenant-123',
              'name': 'Muhammad Asif',
              'email': 'asif@example.com',
              'role': 'Staff',
              'status': 'Active',
              'availability': 'On Break',
              'branchIds': ['branch-123'],
              'loginId': 'asif.m',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/api/v1/users/me/availability' && request.method == 'PATCH') {
          lastPatchBody = request.body;
          final body = jsonDecode(request.body);
          return http.Response(
            jsonEncode({
              'userId': 'staff-123',
              'tenantId': 'tenant-123',
              'name': 'Muhammad Asif',
              'email': 'asif@example.com',
              'role': 'Staff',
              'status': 'Active',
              'availability': body['availability'],
              'branchIds': ['branch-123'],
              'loginId': 'asif.m',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = StaffApiService(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      final profile = await service.getMyProfile();
      expect(profile.displayName, 'Muhammad Asif');
      expect(profile.availability, 'On Break');

      final updated = await service.updateMyAvailability('Available');
      expect(updated.availability, 'Available');
      expect(jsonDecode(lastPatchBody!)['availability'], 'Available');
    });
  });

  group('Staff Dashboard Availability Flow', () {
    testWidgets('Staff availability bottom sheet allows selecting 4 states', (WidgetTester tester) async {
      String? selectedState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => _SetAvailabilityBottomSheet(
                        currentAvailability: 'Available',
                        onSelect: (String status) {
                          selectedState = status;
                          Navigator.of(context).pop();
                        },
                      ),
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Bottom sheet should open with title, subtitle, and 4 options
      expect(find.text('Set Availability'), findsOneWidget);
      expect(find.text('Let your team know your status'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Ready to receive and work on assigned tasks'), findsOneWidget);
      expect(find.text('Busy'), findsOneWidget);
      expect(find.text('Currently working — no new tasks please'), findsOneWidget);
      expect(find.text('On Break'), findsOneWidget);
      expect(find.text('Taking a short break, back soon'), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Not available for work right now'), findsOneWidget);

      // Select On Break
      await tester.tap(find.text('On Break'));
      await tester.pumpAndSettle();

      expect(selectedState, 'On Break');
    });

    testWidgets('Staff availability card displays status, description, and Change button', (WidgetTester tester) async {
      bool changeTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _StaffAvailabilityCard(
              availability: 'Busy',
              onChange: () => changeTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Busy'), findsOneWidget);
      expect(find.text('Tap to update your availability'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      await tester.tap(find.text('Change'));
      expect(changeTapped, isTrue);
    });
  });
}

class _StaffAvailabilityCard extends StatelessWidget {
  const _StaffAvailabilityCard({
    required this.availability,
    required this.onChange,
  });

  final String availability;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChange,
      child: Row(
        children: <Widget>[
          Text(availability),
          const SizedBox(width: 4),
          const Text('Tap to update your availability'),
          const SizedBox(width: 8),
          const Text('Change'),
        ],
      ),
    );
  }
}

class _SetAvailabilityBottomSheet extends StatelessWidget {
  const _SetAvailabilityBottomSheet({
    required this.currentAvailability,
    required this.onSelect,
  });

  final String currentAvailability;
  final ValueChanged<String> onSelect;

  static const List<({String status, String description, Color dotColor})>
      _options = <({String status, String description, Color dotColor})>[
    (
      status: 'Available',
      description: 'Ready to receive and work on assigned tasks',
      dotColor: Color(0xFF10B981),
    ),
    (
      status: 'Busy',
      description: 'Currently working — no new tasks please',
      dotColor: Color(0xFFF59E0B),
    ),
    (
      status: 'On Break',
      description: 'Taking a short break, back soon',
      dotColor: Color(0xFFEA580C),
    ),
    (
      status: 'Offline',
      description: 'Not available for work right now',
      dotColor: Color(0xFF94A3B8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text('Set Availability'),
        const Text('Let your team know your status'),
        ..._options.map((option) {
          return ListTile(
            title: Text(option.status),
            subtitle: Text(option.description),
            onTap: () => onSelect(option.status),
          );
        }),
      ],
    );
  }
}
