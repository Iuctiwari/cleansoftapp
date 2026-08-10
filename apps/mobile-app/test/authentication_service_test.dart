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
      'uses the gateway login contract and stores returned tokens',
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
          expect(
            request.url.toString(),
            'http://gateway.test/api/v1/auth/login',
          );
          expect(
            request.headers[HttpHeaders.contentTypeHeader],
            contains('application/json'),
          );
          expect(jsonDecode(request.body), <String, Object>{
            'context': 'tenant',
            'identifier': 'owner@example.com',
            'password': 'secret',
            'tenantSlug': 'alpha',
          });
          return http.Response(
            jsonEncode(<String, Object>{
              'data': <String, Object>{
                'accessToken': 'access-token',
                'refreshToken': 'refresh-token',
                'accessTokenExpiresAtUtc': accessExpiry.toIso8601String(),
                'refreshTokenExpiresAtUtc': refreshExpiry.toIso8601String(),
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
          apiBaseUri: Uri.parse('http://gateway.test/api'),
          loginContext: 'tenant',
          tenantSlug: 'alpha',
          tokenStorage: storage,
          client: client,
        );

        final AuthenticationSession session = await service.signIn(
          identifier: ' owner@example.com ',
          password: 'secret',
        );

        expect(session.accessToken, 'access-token');
        expect(storage.session, same(session));
        expect(await service.isAuthenticated(), isTrue);
      },
    );

    test('uses the backend message when login fails', () async {
      final ApiAuthenticationService service = ApiAuthenticationService(
        apiBaseUri: Uri.parse('http://gateway.test/api'),
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
            'Account is disabled',
          ),
        ),
      );
    });

    test('converts connection failures to a user-safe network error', () async {
      final ApiAuthenticationService service = ApiAuthenticationService(
        apiBaseUri: Uri.parse('http://gateway.test/api'),
        loginContext: 'platform',
        tokenStorage: _MemoryTokenStorage(),
        client: MockClient((_) async => throw const SocketException('offline')),
      );

      await expectLater(
        service.signIn(identifier: 'owner@example.com', password: 'secret'),
        throwsA(isA<AuthenticationNetworkException>()),
      );
    });
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
      ),
    );
  }

  @override
  Future<bool> isAuthenticated() async => false;

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
}
