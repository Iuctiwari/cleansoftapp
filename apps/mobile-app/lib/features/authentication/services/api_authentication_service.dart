import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/authentication/services/authentication_service.dart';

final class ApiAuthenticationService implements AuthenticationService {
  ApiAuthenticationService({
    required Uri apiBaseUri,
    required String loginContext,
    required AuthTokenStorage tokenStorage,
    String? tenantSlug,
    http.Client? client,
  }) : _apiBaseUri = apiBaseUri,
       _loginContext = loginContext,
       _tenantSlug = tenantSlug,
       _tokenStorage = tokenStorage,
       _client = client ?? http.Client();

  static const Duration _requestTimeout = Duration(seconds: 20);
  static const String _genericLoginError = 'Invalid email or password';

  final Uri _apiBaseUri;
  final http.Client _client;
  final String _loginContext;
  final String? _tenantSlug;
  final AuthTokenStorage _tokenStorage;

  @override
  Future<bool> isAuthenticated() async {
    try {
      final AuthenticationSession? session = await _tokenStorage.read();
      if (session == null ||
          !DateTime.now().toUtc().isBefore(session.accessTokenExpiresAt)) {
        await _clearStoredSession();
        return false;
      }
      return true;
    } on Exception {
      await _clearStoredSession();
      return false;
    }
  }

  @override
  Future<AuthenticationSession> signIn({
    required String identifier,
    required String password,
  }) async {
    if (_loginContext != 'platform' && _loginContext != 'tenant') {
      throw const AuthenticationConfigurationException(
        'The authentication context is not configured correctly.',
      );
    }
    if (_loginContext == 'tenant' &&
        (_tenantSlug == null || _tenantSlug.trim().isEmpty)) {
      throw const AuthenticationConfigurationException(
        'Tenant sign in is not configured for this app installation.',
      );
    }

    final Uri normalizedBaseUri = _apiBaseUri.replace(
      path: _apiBaseUri.path.endsWith('/')
          ? _apiBaseUri.path
          : '${_apiBaseUri.path}/',
    );
    final Uri endpoint = normalizedBaseUri.resolve('v1/auth/login');
    final Map<String, Object> body = <String, Object>{
      'context': _loginContext,
      'identifier': identifier.trim(),
      'password': password,
      if (_loginContext == 'tenant') 'tenantSlug': _tenantSlug!.trim(),
    };

    try {
      final http.Response response = await _client
          .post(
            endpoint,
            headers: const <String, String>{
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.contentTypeHeader: 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      final Object? decoded = _decodeJson(response.body);
      if (response.statusCode < HttpStatus.ok ||
          response.statusCode >= HttpStatus.multipleChoices) {
        throw AuthenticationException(_errorMessage(decoded));
      }

      final AuthenticationSession session = _parseSession(decoded);
      try {
        await _tokenStorage.write(session);
      } on Exception {
        await _clearStoredSession();
        throw const AuthenticationException(
          'Sign in succeeded, but the secure session could not be saved.',
        );
      }
      return session;
    } on AuthenticationException {
      rethrow;
    } on TimeoutException {
      throw const AuthenticationNetworkException();
    } on SocketException {
      throw const AuthenticationNetworkException();
    } on http.ClientException {
      throw const AuthenticationNetworkException();
    } on FormatException {
      throw const AuthenticationException(
        'The server returned an invalid authentication response.',
      );
    }
  }

  @override
  Future<void> signOut() => _tokenStorage.clear();

  Future<void> _clearStoredSession() async {
    try {
      await _tokenStorage.clear();
    } on Exception {
      // A storage failure still represents an unauthenticated local session.
    }
  }

  Object? _decodeJson(String body) {
    if (body.trim().isEmpty) return null;
    return jsonDecode(body);
  }

  AuthenticationSession _parseSession(Object? decoded) {
    final Map<String, dynamic> envelope = _asMap(decoded);
    final Map<String, dynamic> data = _asMap(envelope['data']);
    final String accessToken = _requiredString(data, 'accessToken');
    final String refreshToken = _requiredString(data, 'refreshToken');
    final DateTime accessExpiry = DateTime.parse(
      _requiredString(data, 'accessTokenExpiresAtUtc'),
    ).toUtc();
    final DateTime refreshExpiry = DateTime.parse(
      _requiredString(data, 'refreshTokenExpiresAtUtc'),
    ).toUtc();

    return AuthenticationSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessExpiry,
      refreshTokenExpiresAt: refreshExpiry,
    );
  }

  String _errorMessage(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return _genericLoginError;
    final Object? error = decoded['error'];
    if (error is String && error.trim().isNotEmpty) return error.trim();
    if (error is Map<String, dynamic>) {
      final Object? message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    final Object? message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return _genericLoginError;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Expected a JSON object.');
  }

  String _requiredString(Map<String, dynamic> source, String key) {
    final Object? value = source[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing $key.');
  }
}
