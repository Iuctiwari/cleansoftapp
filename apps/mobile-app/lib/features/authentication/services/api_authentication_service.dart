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
  Future<AuthenticationSession?> restoreSession() async {
    try {
      final AuthenticationSession? session = await _tokenStorage.read();
      if (session == null ||
          !DateTime.now().toUtc().isBefore(session.accessTokenExpiresAt)) {
        await _clearStoredSession();
        return null;
      }
      return session;
    } on Exception {
      await _clearStoredSession();
      return null;
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
      if (_tenantSlug != null && _tenantSlug.trim().isNotEmpty)
        'tenantSlug': _tenantSlug.trim(),
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
        throw AuthenticationException(
          _errorMessage(decoded, response.statusCode),
        );
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

  @override
  Future<void> requestPasswordReset({
    required String identifier,
  }) async {
    final Uri normalizedBaseUri = _apiBaseUri.replace(
      path: _apiBaseUri.path.endsWith('/')
          ? _apiBaseUri.path
          : '${_apiBaseUri.path}/',
    );
    final Uri endpoint = normalizedBaseUri.resolve('v1/auth/forgot-password');
    final Map<String, Object> body = <String, Object>{
      'context': _loginContext,
      'identifier': identifier.trim(),
      if (_tenantSlug != null && _tenantSlug.trim().isNotEmpty)
        'tenantSlug': _tenantSlug.trim(),
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
        throw AuthenticationException(
          _errorMessage(decoded, response.statusCode),
        );
      }
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
  Future<void> confirmPasswordReset({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    final Uri normalizedBaseUri = _apiBaseUri.replace(
      path: _apiBaseUri.path.endsWith('/')
          ? _apiBaseUri.path
          : '${_apiBaseUri.path}/',
    );
    final Uri endpoint = normalizedBaseUri.resolve('v1/auth/reset-password');
    final Map<String, Object> body = <String, Object>{
      'context': _loginContext,
      'identifier': identifier.trim(),
      'otp': otp.trim(),
      'newPassword': newPassword,
      if (_tenantSlug != null && _tenantSlug.trim().isNotEmpty)
        'tenantSlug': _tenantSlug.trim(),
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
        throw AuthenticationException(
          _errorMessage(decoded, response.statusCode),
        );
      }
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
    final Map<String, dynamic> user = _asMap(data['user']);
    final Object? tenantValue = data['tenant'];
    final Map<String, dynamic>? tenant = tenantValue == null
        ? null
        : _asMap(tenantValue);
    final Object? branchValue = data['branch'];
    final Map<String, dynamic>? branch = branchValue == null
        ? null
        : _asMap(branchValue);

    return AuthenticationSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: accessExpiry,
      refreshTokenExpiresAt: refreshExpiry,
      tenantId: _optionalString(tenant, 'tenantId'),
      tenantSlug: _optionalString(tenant, 'tenantSlug'),
      ownerUserId: _requiredString(user, 'userId'),
      ownerName: _requiredString(user, 'displayName'),
      ownerEmail: _optionalString(user, 'email'),
      roleCode: _requiredString(user, 'roleCode'),
      permissions: (data['permissions'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      businessName: _optionalString(tenant, 'tenantName'),
      branchId: _optionalString(branch, 'branchId'),
      branchName: _optionalString(branch, 'branchName'),
    );
  }

  String _errorMessage(Object? decoded, int statusCode) {
    if (statusCode == HttpStatus.unauthorized) return _genericLoginError;

    final String? backendMessage = _backendMessage(decoded);
    if (backendMessage != null) return backendMessage;

    switch (statusCode) {
      case HttpStatus.badRequest:
        return 'Please check your sign-in details and try again.';
      case HttpStatus.forbidden:
        return 'You are not authorized to access this account.';
      case HttpStatus.notFound:
        return 'The requested account or tenant was not found.';
      case HttpStatus.conflict:
        return 'The sign-in request conflicts with the current account state.';
      case HttpStatus.internalServerError:
      case HttpStatus.badGateway:
      case HttpStatus.serviceUnavailable:
      case HttpStatus.gatewayTimeout:
        return 'The authentication service is unavailable. Please try again.';
      default:
        return 'Unable to sign in. Please try again.';
    }
  }

  String? _backendMessage(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final Object? error = decoded['error'];
    if (error is String && error.trim().isNotEmpty) return error.trim();
    if (error is Map<String, dynamic>) {
      final Object? message = error['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      if (message is List) {
        final List<String> messages = message.whereType<String>().toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }
    }
    final Object? message = decoded['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    if (message is List) {
      final List<String> messages = message.whereType<String>().toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return null;
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

  String? _optionalString(Map<String, dynamic>? source, String key) {
    final Object? value = source?[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
