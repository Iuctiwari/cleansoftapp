import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/registration_form.dart';

/// Result returned after a successful tenant registration.
class TenantRegistrationResult {
  final String tenantId;
  final String tenantSlug;
  final String ownerUserId;
  final String businessName;
  final String message;

  const TenantRegistrationResult({
    required this.tenantId,
    required this.tenantSlug,
    required this.ownerUserId,
    required this.businessName,
    required this.message,
  });

  factory TenantRegistrationResult.fromJson(Map<String, dynamic> json) {
    return TenantRegistrationResult(
      tenantId: json['tenantId'] as String,
      tenantSlug: json['tenantSlug'] as String,
      ownerUserId: json['ownerUserId'] as String,
      businessName: json['businessName'] as String,
      message: json['message'] as String,
    );
  }
}

/// Structured API error returned from the backend.
class TenantApiException implements Exception {
  final String code;
  final String messageKey;
  final String category;
  final List<Map<String, dynamic>> fields;

  const TenantApiException({
    required this.code,
    required this.messageKey,
    required this.category,
    this.fields = const [],
  });

  /// Human-readable message for the UI.
  String get userMessage {
    switch (code) {
      case 'tenant.email_already_registered':
        return 'This email address is already registered. Please sign in or use a different email.';
      case 'tenant.password_policy_failed':
        return 'Password must be at least 8 characters with uppercase, lowercase, number, and special character.';
      case 'tenant.terms_not_agreed':
        return 'You must agree to the Terms of Service to continue.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

  /// HTTP client for the tenant-service API.
class TenantApiService {
  /// Base URL of the tenant-service.
  static const String _baseUrl = 'http://localhost:3002';

  /// POST /api/v1/tenants/register
  ///
  /// Registers a new business tenant.
  /// Throws [TenantApiException] for known API errors.
  /// Throws [Exception] for network/parse errors.
  Future<TenantRegistrationResult> registerTenant(RegistrationForm form) async {
    final uri = Uri.parse('$_baseUrl/api/v1/tenants/register');

    late http.Response response;

    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(form.toJson()),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      throw Exception('Network error: unable to reach the server. Please check your connection.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 201) {
      return TenantRegistrationResult.fromJson(body);
    }

    // Parse structured error envelope from backend.
    if (body.containsKey('error')) {
      final error = body['error'] as Map<String, dynamic>;
      throw TenantApiException(
        code: error['code'] as String? ?? 'unknown',
        messageKey: error['messageKey'] as String? ?? 'errors.internal',
        category: error['category'] as String? ?? 'internal',
        fields: (error['fields'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [],
      );
    }

    throw Exception('Unexpected response (${response.statusCode}) from server.');
  }
}
