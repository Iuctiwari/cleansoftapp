import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';

import '../models/registration_form.dart';
import '../models/tenant_onboarding_data.dart';

/// Result returned after a successful tenant registration.
class TenantRegistrationResult {
  final String tenantId;
  final String slug;
  final String ownerUserId;
  final String businessName;
  final String message;

  const TenantRegistrationResult({
    required this.tenantId,
    required this.slug,
    required this.ownerUserId,
    required this.businessName,
    required this.message,
  });

  factory TenantRegistrationResult.fromJson(Map<String, dynamic> json) {
    return TenantRegistrationResult(
      tenantId: _requiredString(json, 'tenantId'),
      slug: _requiredString(json, 'slug'),
      ownerUserId: _requiredString(json, 'ownerUserId'),
      businessName: _requiredString(json, 'businessName'),
      message: _requiredString(json, 'message'),
    );
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Registration response is missing $key');
    }
    return value;
  }
}

class TenantProfile {
  final String tenantId;
  final String businessName;
  final String ownerName;
  final String ownerEmail;

  const TenantProfile({
    required this.tenantId,
    required this.businessName,
    required this.ownerName,
    required this.ownerEmail,
  });

  factory TenantProfile.fromJson(Map<String, dynamic> json) {
    return TenantProfile(
      tenantId: TenantRegistrationResult._requiredString(json, 'tenantId'),
      businessName: TenantRegistrationResult._requiredString(
        json,
        'businessName',
      ),
      ownerName: TenantRegistrationResult._requiredString(json, 'ownerName'),
      ownerEmail: TenantRegistrationResult._requiredString(json, 'ownerEmail'),
    );
  }
}

class TenantBranch {
  final String branchId;
  final String branchName;

  const TenantBranch({required this.branchId, required this.branchName});

  factory TenantBranch.fromJson(Map<String, dynamic> json) {
    return TenantBranch(
      branchId: TenantRegistrationResult._requiredString(json, 'branchId'),
      branchName: TenantRegistrationResult._requiredString(json, 'branchName'),
    );
  }
}

/// A request that could not reach the tenant service.
class TenantApiNetworkException implements Exception {
  final String message;

  const TenantApiNetworkException(this.message);
}

/// Structured API error returned from the backend.
class TenantApiException implements Exception {
  final String code;
  final String messageKey;
  final String category;
  final int statusCode;
  final List<Map<String, dynamic>> fields;
  final String? backendMessage;

  const TenantApiException({
    required this.code,
    required this.messageKey,
    required this.category,
    required this.statusCode,
    this.fields = const [],
    this.backendMessage,
  });

  String get userMessage {
    if (_isDuplicateField('email', const <String>{
      'tenant.email_already_registered',
    })) {
      return 'Email is already registered';
    }
    if (_isDuplicateField('mobileNumber', const <String>{
      'tenant.mobile_already_registered',
      'tenant.mobile_number_already_registered',
    })) {
      return 'Mobile number is already registered';
    }

    switch (code) {
      case 'tenant.password_policy_failed':
        return 'Password must be at least 8 characters with uppercase, lowercase, number, and special character.';
      case 'tenant.terms_not_agreed':
        return 'You must agree to the Terms of Service to continue.';
    }

    if (backendMessage != null && backendMessage!.trim().isNotEmpty) {
      return backendMessage!;
    }

    switch (statusCode) {
      case 400:
        return 'Please check the registration details and try again.';
      case 401:
      case 403:
        return 'You are not authorized to create this account.';
      case 404:
        return 'The tenant registration service was not found.';
      case 409:
        return 'An account with these details already exists.';
      case 502:
      case 503:
      case 504:
        return 'Tenant Service unavailable';
      default:
        return 'The tenant service could not complete registration. Please try again.';
    }
  }

  bool _isDuplicateField(String field, Set<String> matchingCodes) {
    if (statusCode != HttpStatus.conflict) return false;
    return matchingCodes.contains(code) ||
        fields.any(
          (error) =>
              error['field'] == field &&
              (matchingCodes.contains(error['code']) ||
                  error['code'] == 'already_registered' ||
                  error['code'] == 'duplicate'),
        );
  }
}

/// HTTP client for the existing tenant-service registration API.
class TenantApiService {
  TenantApiService({
    http.Client? client,
    String? baseUrl,
    AuthTokenStorage? tokenStorage,
  }) : _client = client ?? http.Client(),
       _baseUrl = _normalizeBaseUrl(baseUrl ?? _configuredBaseUrl()),
       _tokenStorage = tokenStorage ?? AuthenticationDependencies.tokenStorage;

  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _environmentKey = 'TENANT_API_BASE_URL';

  final http.Client _client;
  final String _baseUrl;
  final AuthTokenStorage _tokenStorage;

  static String _configuredBaseUrl() {
    if (dotenv.isInitialized) {
      final configured = dotenv.env[_environmentKey]?.trim();
      if (configured != null && configured.isNotEmpty) return configured;
      final apiBase = dotenv.env['API_BASE_URL']?.trim();
      if (apiBase != null && apiBase.isNotEmpty) return apiBase;
    }
    return 'http://localhost:3000';
  }

  static String _normalizeBaseUrl(String value) {
    var trimmed = value.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('/api/v1')) {
      trimmed = trimmed.substring(0, trimmed.length - 7);
    } else if (trimmed.endsWith('/v1')) {
      trimmed = trimmed.substring(0, trimmed.length - 3);
    } else if (trimmed.endsWith('/api')) {
      trimmed = trimmed.substring(0, trimmed.length - 4);
    }
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// POST /api/v1/tenants/register
  Future<TenantRegistrationResult> registerTenant(RegistrationForm form) async {
    final uri = Uri.parse('$_baseUrl/api/v1/tenants/register');

    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(form.toJson()),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const TenantApiNetworkException('Tenant Service unavailable');
    } on SocketException {
      throw const TenantApiNetworkException('Tenant Service unavailable');
    } on http.ClientException {
      throw const TenantApiNetworkException('Tenant Service unavailable');
    } catch (e) {
      if (e is TenantApiException || e is TenantApiNetworkException) rethrow;
      throw const TenantApiNetworkException('Tenant Service unavailable');
    }

    final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object');
      }
      body = decoded;
    } on FormatException {
      throw TenantApiException(
        code: 'tenant.invalid_response',
        messageKey: 'errors.invalid_response',
        category: 'internal',
        statusCode: response.statusCode,
        backendMessage: 'The tenant service returned an invalid response.',
      );
    }

    if (response.statusCode == 201) {
      try {
        return TenantRegistrationResult.fromJson(body);
      } on FormatException {
        throw TenantApiException(
          code: 'tenant.invalid_response',
          messageKey: 'errors.invalid_response',
          category: 'internal',
          statusCode: response.statusCode,
          backendMessage:
              'The tenant service returned an incomplete registration response.',
        );
      }
    }

    final structuredError = body['error'];
    if (structuredError is Map<String, dynamic>) {
      throw TenantApiException(
        code: structuredError['code'] as String? ?? 'unknown',
        messageKey:
            structuredError['messageKey'] as String? ?? 'errors.internal',
        category: structuredError['category'] as String? ?? 'internal',
        statusCode: response.statusCode,
        fields:
            (structuredError['fields'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            const [],
        backendMessage: _extractMessage(
          structuredError['message'] ?? body['message'],
        ),
      );
    }

    final backendMessage = _extractMessage(body['message']);

    throw TenantApiException(
      code: 'tenant.http_${response.statusCode}',
      messageKey: 'errors.http_${response.statusCode}',
      category: 'http',
      statusCode: response.statusCode,
      backendMessage: backendMessage,
    );
  }

  static String? _extractMessage(Object? rawMessage) {
    if (rawMessage is List) {
      final messages = rawMessage.whereType<String>().toList();
      return messages.isEmpty ? null : messages.join('\n');
    }
    if (rawMessage is String && rawMessage.trim().isNotEmpty) {
      return rawMessage.trim();
    }
    return null;
  }

  /// PATCH /api/v1/tenants/:tenantId
  ///
  /// Sends the complete onboarding payload in one request.
  Future<void> completeOnboarding(TenantOnboardingData data) async {
    final tenantId = data.tenantId.trim();
    if (tenantId.isEmpty) {
      throw const TenantApiException(
        code: 'tenant.missing_tenant_id',
        messageKey: 'errors.tenant.missing_tenant_id',
        category: 'validation',
        statusCode: 400,
        backendMessage:
            'Tenant information is missing. Please create the account again.',
      );
    }

    late http.Response response;
    try {
      response = await _client
          .patch(
            Uri.parse('$_baseUrl/api/v1/tenants/$tenantId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data.toOnboardingJson()),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const TenantApiNetworkException(
        'The tenant service timed out. Please try again.',
      );
    } on SocketException {
      throw const TenantApiNetworkException(
        'Unable to reach the tenant service. Check that it is running and reachable from this device.',
      );
    } on http.ClientException {
      throw const TenantApiNetworkException(
        'Unable to reach the tenant service. Check that it is running and reachable from this device.',
      );
    } catch (e) {
      if (e is TenantApiException || e is TenantApiNetworkException) rethrow;
      throw const TenantApiNetworkException(
        'Unable to reach the tenant service. Check that it is running and reachable from this device.',
      );
    }

    final Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      body = decoded;
    } on FormatException {
      throw _invalidResponse(statusCode: response.statusCode);
    }

    if (response.statusCode == 200) {
      if (body['tenantId'] != tenantId) throw _invalidResponse();
      return;
    }

    final structuredError = body['error'];
    if (structuredError is Map<String, dynamic>) {
      throw TenantApiException(
        code: structuredError['code'] as String? ?? 'unknown',
        messageKey:
            structuredError['messageKey'] as String? ?? 'errors.internal',
        category: structuredError['category'] as String? ?? 'internal',
        statusCode: response.statusCode,
        fields:
            (structuredError['fields'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            const [],
      );
    }

    final rawMessage = body['message'];
    throw TenantApiException(
      code: 'tenant.http_${response.statusCode}',
      messageKey: 'errors.http_${response.statusCode}',
      category: 'http',
      statusCode: response.statusCode,
      backendMessage: rawMessage is List
          ? rawMessage.whereType<String>().join('\n')
          : rawMessage is String
          ? rawMessage
          : null,
    );
  }

  /// GET /api/v1/tenants/:tenantId
  Future<TenantProfile> getTenantProfile(String tenantId) async {
    final decoded = await _get('/api/v1/tenants/$tenantId');
    if (decoded is! Map<String, dynamic>) {
      throw _invalidResponse();
    }
    try {
      return TenantProfile.fromJson(decoded);
    } on FormatException {
      throw _invalidResponse();
    }
  }

  /// GET /api/v1/tenants/:tenantId/branches
  Future<List<TenantBranch>> listBranches(String tenantId) async {
    final decoded = await _get('/api/v1/tenants/$tenantId/branches');
    if (decoded is! List<dynamic>) throw _invalidResponse();
    try {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(TenantBranch.fromJson)
          .toList(growable: false);
    } on FormatException {
      throw _invalidResponse();
    }
  }

  Future<Object?> _get(String path) async {
    final session = await _tokenStorage.read();
    if (session == null) {
      throw const TenantApiException(
        code: 'tenant.unauthenticated',
        messageKey: 'errors.unauthenticated',
        category: 'unauthenticated',
        statusCode: 401,
        backendMessage: 'Please sign in again.',
      );
    }
    late http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const TenantApiNetworkException(
        'The tenant service timed out. Please try again.',
      );
    } on SocketException {
      throw const TenantApiNetworkException(
        'Unable to reach the tenant service. Check that it is running and reachable from this device.',
      );
    } on http.ClientException {
      throw const TenantApiNetworkException(
        'Unable to reach the tenant service. Check that it is running and reachable from this device.',
      );
    } catch (e) {
      if (e is TenantApiException || e is TenantApiNetworkException) rethrow;
      throw const TenantApiNetworkException(
        'Unable to reach the tenant service. Check that it is running and reachable from this device.',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw _invalidResponse(statusCode: response.statusCode);
    }

    if (response.statusCode == 200) return decoded;

    final body = decoded is Map<String, dynamic>
        ? decoded
        : const <String, dynamic>{};
    final structuredError = body['error'];
    if (structuredError is Map<String, dynamic>) {
      throw TenantApiException(
        code: structuredError['code'] as String? ?? 'unknown',
        messageKey:
            structuredError['messageKey'] as String? ?? 'errors.internal',
        category: structuredError['category'] as String? ?? 'internal',
        statusCode: response.statusCode,
      );
    }

    throw TenantApiException(
      code: 'tenant.http_${response.statusCode}',
      messageKey: 'errors.http_${response.statusCode}',
      category: 'http',
      statusCode: response.statusCode,
    );
  }

  TenantApiException _invalidResponse({int statusCode = 200}) {
    return TenantApiException(
      code: 'tenant.invalid_response',
      messageKey: 'errors.invalid_response',
      category: 'internal',
      statusCode: statusCode,
      backendMessage: 'The tenant service returned an invalid response.',
    );
  }
}
