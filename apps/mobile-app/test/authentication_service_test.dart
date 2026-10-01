import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/authentication.dart';

void main() {
  group('ApiAuthenticationService', () {
    test(
      'uses the auth login contract without a fixed tenant slug and stores the session',
      () async {
        final _MemoryTokenStorage storage = _MemoryTokenStorage();
        final DateTime accessExpiry = DateTime.now().toUtc().add(
          const Duration(minutes: 15),
        );
        final DateTime refreshExpiry = DateTime.now().toUtc().add(
          const Duration(days: 7),
        );
        final MockClient client = MockClient((http.Request request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), 'http://auth.test/api/v1/auth/login');
          expect(
            request.headers[HttpHeaders.contentTypeHeader],
            contains('application/json'),
          );
          expect(jsonDecode(request.body), <String, Object>{
            'context': 'tenant',
            'identifier': 'owner@example.com',
            'password': 'secret',
          });
          return http.Response(
            jsonEncode(<String, Object>{
              'data': <String, Object>{
                'accessToken': 'access-token',
                'refreshToken': 'refresh-token',
                'accessTokenExpiresAtUtc': accessExpiry.toIso8601String(),
                'refreshTokenExpiresAtUtc': refreshExpiry.toIso8601String(),
                'user': <String, String>{
                  'userId': 'owner-1',
                  'displayName': 'Owner Name',
                  'email': 'owner@example.com',
                  'roleCode': 'Owner',
                },
                'branch': <String, String>{
                  'branchId': 'branch-1',
                  'branchName': 'Assigned Branch',
                },
                'permissions': <String>['orders:read', 'orders:write'],
                'tenant': <String, String>{
                  'tenantId': 'tenant-1',
                  'tenantSlug': 'alpha',
                  'tenantName': 'Alpha Laundry',
                },
              },
              'meta': <String, String>{'correlationId': 'request-1'},
            }),
            HttpStatus.ok,
            headers: <String, String>{
              HttpHeaders.contentTypeHeader: 'application/json',
            },
          );
        });
        final ApiAuthenticationService service = ApiAuthenticationService(
          apiBaseUri: Uri.parse('http://auth.test/api'),
          loginContext: 'tenant',
          tokenStorage: storage,
          client: client,
        );

        final AuthenticationSession session = await service.signIn(
          identifier: ' owner@example.com ',
          password: 'secret',
        );

        expect(session.accessToken, 'access-token');
        expect(session.tenantId, 'tenant-1');
        expect(session.ownerUserId, 'owner-1');
        expect(session.ownerName, 'Owner Name');
        expect(session.businessName, 'Alpha Laundry');
        expect(session.roleCode, 'Owner');
        expect(session.branchId, 'branch-1');
        expect(session.branchName, 'Assigned Branch');
        expect(session.permissions, contains('orders:read'));
        expect(storage.session, same(session));
        expect(await service.restoreSession(), same(session));
      },
    );

    test('uses a safe invalid-credentials message for 401 responses', () async {
      final ApiAuthenticationService service = ApiAuthenticationService(
        apiBaseUri: Uri.parse('http://auth.test/api'),
        loginContext: 'platform',
        tokenStorage: _MemoryTokenStorage(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(<String, Object>{
              'error': <String, String>{'message': 'Account is disabled'},
            }),
            HttpStatus.unauthorized,
          ),
        ),
      );

      await expectLater(
        service.signIn(identifier: 'owner@example.com', password: 'wrong'),
        throwsA(
          isA<AuthenticationException>().having(
            (AuthenticationException error) => error.message,
            'message',
            'Invalid email or password',
          ),
        ),
      );
    });

    test('converts connection failures to a user-safe network error', () async {
      final ApiAuthenticationService service = ApiAuthenticationService(
        apiBaseUri: Uri.parse('http://auth.test/api'),
        loginContext: 'platform',
        tokenStorage: _MemoryTokenStorage(),
        client: MockClient((_) async => throw const SocketException('offline')),
      );

      try {
        await service.signIn(
          identifier: 'owner@example.com',
          password: 'secret',
        );
        fail('Expected a network failure');
      } on AuthenticationNetworkException catch (error) {
        expect(
          error.message,
          'Unable to connect to the authentication server. Please ensure it is running and try again.',
        );
      }
    });

    test('uses a backend validation message for a 400 response', () async {
      final ApiAuthenticationService service = ApiAuthenticationService(
        apiBaseUri: Uri.parse('http://auth.test/api'),
        loginContext: 'tenant',
        tokenStorage: _MemoryTokenStorage(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(<String, Object>{
              'message': <String>['identifier must not be empty'],
            }),
            HttpStatus.badRequest,
          ),
        ),
      );

      await expectLater(
        service.signIn(identifier: 'owner@example.com', password: 'secret'),
        throwsA(
          isA<AuthenticationException>().having(
            (AuthenticationException error) => error.message,
            'message',
            'identifier must not be empty',
          ),
        ),
      );
    });

    test('does not map HTTP authorization errors to network errors', () async {
      final ApiAuthenticationService service = ApiAuthenticationService(
        apiBaseUri: Uri.parse('http://auth.test/api'),
        loginContext: 'tenant',
        tokenStorage: _MemoryTokenStorage(),
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(<String, Object>{
              'error': <String, String>{
                'message': 'This account is not allowed to sign in',
              },
            }),
            HttpStatus.forbidden,
          ),
        ),
      );

      await expectLater(
        service.signIn(identifier: 'owner@example.com', password: 'secret'),
        throwsA(
          isA<AuthenticationException>()
              .having(
                (AuthenticationException error) => error.message,
                'message',
                'This account is not allowed to sign in',
              )
              .having(
                (AuthenticationException error) =>
                    error is AuthenticationNetworkException,
                'is network error',
                isFalse,
              ),
        ),
      );
    });

    for (final scenario in <(int, String)>[
      (HttpStatus.notFound, 'The requested account or tenant was not found.'),
      (
        HttpStatus.conflict,
        'The sign-in request conflicts with the current account state.',
      ),
      (
        HttpStatus.internalServerError,
        'The authentication service is unavailable. Please try again.',
      ),
    ]) {
      test(
        'maps HTTP ${scenario.$1} without reporting a network error',
        () async {
          final ApiAuthenticationService service = ApiAuthenticationService(
            apiBaseUri: Uri.parse('http://auth.test/api'),
            loginContext: 'tenant',
            tokenStorage: _MemoryTokenStorage(),
            client: MockClient((_) async => http.Response('{}', scenario.$1)),
          );

          await expectLater(
            service.signIn(identifier: 'owner@example.com', password: 'secret'),
            throwsA(
              isA<AuthenticationException>()
                  .having(
                    (AuthenticationException error) => error.message,
                    'message',
                    scenario.$2,
                  )
                  .having(
                    (AuthenticationException error) =>
                        error is AuthenticationNetworkException,
                    'is network error',
                    isFalse,
                  ),
            ),
          );
        },
      );
    }
  });

  test('AuthenticationController prevents concurrent login requests', () async {
    final _DeferredAuthenticationService service =
        _DeferredAuthenticationService();
    final AuthenticationController controller = AuthenticationController(
      service: service,
    );

    final Future<bool> first = controller.signIn(
      identifier: 'owner@example.com',
      password: 'secret',
    );
    final bool second = await controller.signIn(
      identifier: 'owner@example.com',
      password: 'secret',
    );
    expect(second, isFalse);
    expect(service.signInCalls, 1);

    service.complete();
    expect(await first, isTrue);
    expect(controller.isAuthenticated, isTrue);
    expect(controller.session?.tenantId, 'tenant-1');
  });
}

final class _MemoryTokenStorage implements AuthTokenStorage {
  AuthenticationSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<AuthenticationSession?> read() async => session;

  @override
  Future<void> write(AuthenticationSession value) async => session = value;
}

final class _DeferredAuthenticationService implements AuthenticationService {
  final Completer<AuthenticationSession> _completer =
      Completer<AuthenticationSession>();
  int signInCalls = 0;

  void complete() {
    final DateTime expiry = DateTime.now().toUtc().add(
      const Duration(hours: 1),
    );
    _completer.complete(
      AuthenticationSession(
        accessToken: 'access',
        refreshToken: 'refresh',
        accessTokenExpiresAt: expiry,
        refreshTokenExpiresAt: expiry,
        tenantId: 'tenant-1',
      ),
    );
  }

  @override
  Future<AuthenticationSession?> restoreSession() async => null;

  @override
  Future<AuthenticationSession> signIn({
    required String identifier,
    required String password,
  }) {
    signInCalls += 1;
    return _completer.future;
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
