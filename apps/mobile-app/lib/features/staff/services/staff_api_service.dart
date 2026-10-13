import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/backend_environment.dart';
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

  @override
  String toString() => userMessage;
}

class StaffApiService {
  StaffApiService({
    http.Client? client,
    String? baseUrl,
    AuthTokenStorage? tokenStorage,
  }) : _client = client ?? http.Client(),
       _baseUrl = _normalizeBaseUrl(
         baseUrl ??
             BackendEnvironment.resolveBase(
               _configuredBaseUrl(),
               'RENDER_USER_API_BASE_URL',
             ),
       ),
       _tokenStorage = tokenStorage ?? SecureAuthTokenStorage();

  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _environmentKey = 'USER_API_BASE_URL';

  final http.Client _client;
  final String _baseUrl;
  final AuthTokenStorage _tokenStorage;
  String? _branchId;

  void selectBranch(String? branchId) {
    final String value = branchId?.trim() ?? '';
    _branchId = value.isEmpty || value == 'unavailable' ? null : value;
  }

  static String _configuredBaseUrl() {
    if (dotenv.isInitialized) {
      final configured = dotenv.env[_environmentKey]?.trim();
      if (configured != null && configured.isNotEmpty) return configured;
    }
    return 'http://127.0.0.1:3013';
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  /// Tenant profile/branches live on tenant-service, not user-service (this
  /// class's own [_baseUrl]) or auth-service — resolved separately here.
  ///
  /// Returns the bare host: callers append `/api/v1/...` themselves, but
  /// RENDER_TENANT_API_BASE_URL is configured as `https://host/api/v1` (the
  /// form TenantApiService expects), so a trailing `/api/v1`, `/v1` or `/api`
  /// is stripped here the same way TenantApiService does — otherwise requests
  /// go to `/api/v1/api/v1/tenants/...` and 404.
  static String _tenantServiceBaseUrl() {
    var base = _normalizeBaseUrl(
      BackendEnvironment.resolveBase(
        dotenv.env['TENANT_API_BASE_URL']?.trim() ?? 'http://127.0.0.1:3006',
        'RENDER_TENANT_API_BASE_URL',
      ),
    );
    for (final String suffix in const <String>['/api/v1', '/v1', '/api']) {
      if (base.endsWith(suffix)) {
        base = base.substring(0, base.length - suffix.length);
        break;
      }
    }
    return _normalizeBaseUrl(base);
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
      final branchId = _branchId ?? session?.branchId;
      if (branchId != null && branchId.isNotEmpty) {
        headers['x-branch-id'] = branchId;
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
      response = await _client
          .get(uri, headers: headers)
          .timeout(_requestTimeout);
    } catch (_) {
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

  Future<StaffMember> getMyProfile() async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/me');
    final headers = await _authHeaders();
    late http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(_requestTimeout);
    } catch (_) {
      throw const StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service.',
      );
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      return StaffMember.fromJson(decoded);
    } else {
      final decoded = jsonDecode(response.body);
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage:
            decoded['message']?.toString() ?? 'Failed to load user profile.',
      );
    }
  }

  Future<StaffMember> updateMyAvailability(String availability) async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/me/availability');
    final headers = await _authHeaders();
    late http.Response response;
    try {
      response = await _client
          .patch(
            uri,
            headers: headers,
            body: jsonEncode({'availability': availability}),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw const StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service.',
      );
    }

    if (response.statusCode == 200 || response.statusCode == 204) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      return StaffMember.fromJson(decoded);
    } else {
      final decoded = jsonDecode(response.body);
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage:
            decoded['message']?.toString() ?? 'Failed to update availability.',
      );
    }
  }

  Future<StaffStatistics> getStaffStatistics(
    String tenantId, {
    String? branchId,
  }) async {
    final queryParams = branchId != null && branchId.isNotEmpty
        ? '?branchId=$branchId'
        : '';
    final uri = Uri.parse(
      '$_baseUrl/api/v1/users/tenant/$tenantId/statistics$queryParams',
    );
    final headers = await _authHeaders();

    late http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(_requestTimeout);
    } catch (_) {
      throw const StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service.',
      );
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      return StaffStatistics.fromJson(decoded);
    } else {
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage: 'Failed to load staff statistics.',
      );
    }
  }

  Future<StaffMember> getStaffMember(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/$userId');
    final headers = await _authHeaders();
    late http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(_requestTimeout);
    } catch (e) {
      throw StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service. Details: $e',
      );
    }

    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      return StaffMember.fromJson(decoded);
    } else {
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage: 'Failed to load staff profile.',
      );
    }
  }

  Future<Map<String, dynamic>> getTenantProfile(String tenantId) async {
    final tenantServiceUrl = _tenantServiceBaseUrl();
    final uri = Uri.parse('$tenantServiceUrl/api/v1/tenants/$tenantId');
    final headers = await _authHeaders();
    late http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(_requestTimeout);
    } catch (e) {
      throw StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the tenant service. Details: $e',
      );
    }

    if (response.statusCode == 200) {
      final tenantData = jsonDecode(response.body) as Map<String, dynamic>;

      try {
        final branchesUri = Uri.parse(
          '$tenantServiceUrl/api/v1/tenants/$tenantId/branches',
        );
        final branchesRes = await _client
            .get(branchesUri, headers: headers)
            .timeout(_requestTimeout);
        if (branchesRes.statusCode == 200) {
          final List branches = jsonDecode(branchesRes.body);
          final headOffice = branches.cast<Map<String, dynamic>>().firstWhere(
            (b) => b['isHeadOffice'] == true,
            orElse: () => <String, dynamic>{},
          );
          if (headOffice.isNotEmpty && headOffice['city'] != null) {
            tenantData['location'] = headOffice['city'];
          }
        }
      } catch (_) {
        // Fallback silently if branches fail
      }

      return tenantData;
    } else {
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage: 'Failed to load tenant profile.',
      );
    }
  }

  Future<void> updateTenantProfile({
    required String tenantId,
    String? ownerName,
    String? mobileNumber,
    String? businessName,
    String? location,
  }) async {
    final uri = Uri.parse('${_tenantServiceBaseUrl()}/api/v1/tenants/$tenantId/profile');
    final headers = await _authHeaders();
    final body = <String, dynamic>{};
    if (ownerName != null && ownerName.isNotEmpty)
      body['ownerName'] = ownerName;
    if (mobileNumber != null && mobileNumber.isNotEmpty)
      body['mobileNumber'] = mobileNumber;
    if (businessName != null && businessName.isNotEmpty)
      body['businessName'] = businessName;
    if (location != null && location.isNotEmpty) body['location'] = location;

    late http.Response response;
    try {
      response = await _client
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout);
    } catch (e) {
      throw StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the tenant service. Details: $e',
      );
    }

    if (response.statusCode != 200) {
      String backendMessage = 'Failed to update profile.';
      try {
        final decoded = jsonDecode(response.body);
        final msg = decoded['message'];
        // tenant-service errors come as {"error": {"code": ...}} with no message.
        final error = decoded['error'];
        final code = error is Map ? error['code'] : null;
        if (code == 'tenant.mobile_already_registered') {
          backendMessage =
              'This mobile number is already used by another account. Please use a different number.';
        } else if (msg is List) {
          backendMessage = msg.join('\n');
        } else if (msg != null) {
          backendMessage = msg.toString();
        }
      } catch (_) {}
      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage: backendMessage,
      );
    }
  }

  Future<List<SystemRole>> getSystemRoles() async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/roles');
    final headers = await _authHeaders();
    late http.Response response;
    try {
      response = await _client
          .get(uri, headers: headers)
          .timeout(_requestTimeout);
    } catch (e) {
      throw StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service. Details: $e',
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
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'name': name,
              'loginId': loginId,
              'password': password,
              if (email != null && email.isNotEmpty) 'email': email,
              if (mobileNumber != null && mobileNumber.isNotEmpty)
                'mobileNumber': mobileNumber,
              if (department != null && department.isNotEmpty)
                'department': department,
              'role': role,
              'branchIds': branches,
            }),
          )
          .timeout(_requestTimeout);
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
      String backendMessage = 'Failed to register staff.';
      final msg = decoded['message'];
      if (msg is List) {
        backendMessage = msg.join('\n');
      } else if (msg != null) {
        backendMessage = msg.toString();
      } else if (decoded['error'] is Map) {
        backendMessage =
            decoded['error']['messageKey'] ??
            decoded['error']['code'] ??
            backendMessage;
      }

      throw StaffApiException(
        code: 'error',
        messageKey: 'error',
        statusCode: response.statusCode,
        backendMessage: backendMessage,
      );
    }
  }

  /// Creates a staff account WITHOUT a password and emails them an invitation;
  /// they set their own password with "Forgot password?". Returns whether the
  /// invitation email was sent (the account is created either way).
  Future<bool> inviteStaff({
    required String tenantId,
    required String name,
    required String email,
    String? mobileNumber,
    required String businessName,
    required List<String> branches,
    String role = 'Staff',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/tenant/$tenantId/register');
    final headers = await _authHeaders();

    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({
              'name': name,
              'loginId': email,
              'email': email,
              if (mobileNumber != null && mobileNumber.isNotEmpty)
                'mobileNumber': mobileNumber,
              'role': role,
              'branchIds': branches,
              'sendInvite': true,
              'businessName': businessName,
            }),
          )
          .timeout(_requestTimeout);
    } catch (_) {
      throw const StaffApiException(
        code: 'network_error',
        messageKey: 'network_error',
        statusCode: 0,
        backendMessage: 'Unable to reach the staff service.',
      );
    }

    final Object? decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode == 201) {
      return decoded is Map && decoded['inviteSent'] == true;
    }
    final Object? msg = decoded is Map ? decoded['message'] : null;
    throw StaffApiException(
      code: response.statusCode == 409 ? 'duplicate' : 'error',
      messageKey: 'error',
      statusCode: response.statusCode,
      backendMessage: msg is List
          ? msg.join('\n')
          : msg?.toString() ?? 'Could not invite this staff member.',
    );
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
    String? accessMode,
    List<String>? permissions,
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
      if (accessMode != null) body['accessMode'] = accessMode;
      if (permissions != null) body['permissions'] = permissions;

      final response = await _client
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(_requestTimeout);

      if (response.statusCode != 200) {
        final decoded = jsonDecode(response.body);
        String backendMessage = 'Failed to update staff member.';
        final msg = decoded['message'];
        if (msg is List) {
          backendMessage = msg.join('\n');
        } else if (msg != null) {
          backendMessage = msg.toString();
        } else if (decoded['error'] is Map) {
          backendMessage =
              decoded['error']['messageKey'] ??
              decoded['error']['code'] ??
              backendMessage;
        }

        throw StaffApiException(
          code: 'error',
          messageKey: 'error',
          statusCode: response.statusCode,
          backendMessage: backendMessage,
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
    await _patchAction(
      '/api/v1/users/$userId/suspend',
      'Failed to suspend staff.',
    );
  }

  Future<void> reactivateStaff(String userId) async {
    await _patchAction(
      '/api/v1/users/$userId/reactivate',
      'Failed to reactivate staff.',
    );
  }

  Future<void> removeStaff(String userId) async {
    final uri = Uri.parse('$_baseUrl/api/v1/users/$userId');
    final headers = await _authHeaders();
    try {
      final response = await _client
          .delete(uri, headers: headers)
          .timeout(_requestTimeout);
      if (response.statusCode != 200 && response.statusCode != 204) {
        String backendMessage = 'Failed to remove staff.';
        try {
          final decoded = jsonDecode(response.body);
          final msg = decoded['message'];
          if (msg is List) {
            backendMessage = msg.join('\n');
          } else if (msg != null) {
            backendMessage = msg.toString();
          } else if (decoded['error'] is Map) {
            backendMessage =
                decoded['error']['messageKey'] ??
                decoded['error']['code'] ??
                backendMessage;
          }
        } catch (_) {}
        throw StaffApiException(
          code: 'error',
          messageKey: 'error',
          statusCode: response.statusCode,
          backendMessage: backendMessage,
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
      final response = await _client
          .patch(uri, headers: headers)
          .timeout(_requestTimeout);
      if (response.statusCode != 204 && response.statusCode != 200) {
        String backendMessage = errorMessage;
        try {
          final decoded = jsonDecode(response.body);
          final msg = decoded['message'];
          if (msg is List) {
            backendMessage = msg.join('\n');
          } else if (msg != null) {
            backendMessage = msg.toString();
          } else if (decoded['error'] is Map) {
            backendMessage =
                decoded['error']['messageKey'] ??
                decoded['error']['code'] ??
                backendMessage;
          }
        } catch (_) {}
        throw StaffApiException(
          code: 'error',
          messageKey: 'error',
          statusCode: response.statusCode,
          backendMessage: backendMessage,
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
}
