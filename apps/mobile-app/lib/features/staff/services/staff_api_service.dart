import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../features/authentication/services/auth_token_storage.dart';
import '../models/staff_member.dart';
import '../models/system_role.dart';

class StaffApiException implements Exception {
  final String code;
  final String messageKey;
  final int statusCode;
  final String? backendMessage;

  const StaffApiException({
    required this.code,
    required this.messageKey,
    required this.statusCode,
    this.backendMessage,
  });

  String get userMessage {
    if (backendMessage != null && backendMessage!.trim().isNotEmpty) {
      return backendMessage!;
    }
    return 'Staff Service Error';
  }
}

class StaffApiService {
  StaffApiService({http.Client? client, String? baseUrl, AuthTokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(baseUrl ?? _configuredBaseUrl()),
      _tokenStorage = tokenStorage ?? SecureAuthTokenStorage();

  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _environmentKey = 'USER_API_BASE_URL';

  final http.Client _client;
  final String _baseUrl;
  final AuthTokenStorage _tokenStorage;

  static String _configuredBaseUrl() {
    if (dotenv.isInitialized) {
      final configured = dotenv.env[_environmentKey]?.trim();
      if (configured != null && configured.isNotEmpty) return configured;
    }
    return 'http://10.0.2.2:3002';
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  /// Returns headers with Authorization token if available.
  Future<Map<String, String>> _authHeaders() async {
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    try {
      final session = await _tokenStorage.read();
      final token = session?.accessToken;
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Proceed without token
    }
    return headers;
  }

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<StaffMember>> getStaffMembers(String tenantId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/tenant/$tenantId');
    final headers = await _authHeaders();

    late http.Response response;
    try {
      response = await _client.get(uri, headers: headers).timeout(_requestTimeout);
    } catch (e) {
      throw const StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service.',
      );
    }

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => StaffMember.fromJson(e)).toList();
    } else {
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage: 'Failed to load staff members.',
      );
    }
  }

  Future<List<SystemRole>> getSystemRoles() async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/roles');
    final headers = await _authHeaders();
    late http.Response response;
    try {
      response = await _client.get(uri, headers: headers).timeout(_requestTimeout);
    } catch (e) {
      throw const StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service.',
      );
    }

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((e) => SystemRole.fromJson(e)).toList();
    } else {
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage: 'Failed to load system roles.',
      );
    }
  }

  // ── Register ─────────────────────────────────────────────────────────────

  /// Registers a new staff member with direct credentials.
  /// The employee can log in immediately with [loginId] + [password].
  Future<StaffMember> registerStaff({
    required String tenantId,
    required String name,
    required String loginId,
    required String password,
    String? email,
    String? mobileNumber,
    String? department,
    required String role,
    required List<String> branches,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/tenant/$tenantId/register');
    final headers = await _authHeaders();

    late http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'name': name,
          'loginId': loginId,
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email,
          if (mobileNumber != null && mobileNumber.isNotEmpty) 'mobileNumber': mobileNumber,
          if (department != null && department.isNotEmpty) 'department': department,
          'role': role,
          'branchIds': branches,
        }),
      ).timeout(_requestTimeout);
    } catch (e) {
      throw const StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service.',
      );
    }

    if (response.statusCode == 201) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      return StaffMember.fromJson(decoded);
    } else {
      final decoded = jsonDecode(response.body);
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage: decoded['message']?.toString() ?? 'Failed to register staff.',
      );
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> updateStaff({
    required String userId,
    String? name,
    String? email,
    String? mobileNumber,
    String? department,
    String? role,
    List<String>? branchIds,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/$userId');
    final headers = await _authHeaders();
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (mobileNumber != null) body['mobileNumber'] = mobileNumber;
      if (department != null) body['department'] = department;
      if (role != null) body['role'] = role;
      if (branchIds != null) body['branchIds'] = branchIds;

      final response = await _client.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(_requestTimeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final decoded = jsonDecode(response.body);
        throw StaffApiException(
          code: 'error',
          messageKey: 'error',
          statusCode: response.statusCode,
          backendMessage: decoded['message']?.toString() ?? 'Failed to update staff.',
        );
      }
    } on StaffApiException {
      rethrow;
    } catch (e) {
      throw const StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service.',
      );
    }
  }

  // ── Status actions ────────────────────────────────────────────────────────

  Future<void> suspendStaff(String userId) async {
    await _patchAction('/api/v1/users/$userId/suspend', 'Failed to suspend staff.');
  }

  Future<void> reactivateStaff(String userId) async {
    await _patchAction('/api/v1/users/$userId/reactivate', 'Failed to reactivate staff.');
  }

  Future<void> removeStaff(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/$userId');
    final headers = await _authHeaders();
    try {
      final response = await _client.delete(uri, headers: headers).timeout(_requestTimeout);
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw StaffApiException(
          code: 'error',
          messageKey: 'error',
          statusCode: response.statusCode,
          backendMessage: 'Failed to remove staff.',
        );
      }
    } on StaffApiException {
      rethrow;
    } catch (e) {
      throw const StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service.',
      );
    }
  }

  Future<void> _patchAction(String path, String errorMessage) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = await _authHeaders();
    try {
      final response = await _client.patch(uri, headers: headers).timeout(_requestTimeout);
      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception();
      }
    } catch (e) {
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: 0,
        backendMessage: errorMessage,
      );
    }
  }
}
