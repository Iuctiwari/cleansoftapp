import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';

/// A request that could not reach the branch service.
class BranchApiNetworkException implements Exception {
  const BranchApiNetworkException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Structured API error returned from the branch service.
///
/// The backend's error envelope is `{error: {code, category, messageKey,
/// fields?, retryable, correlationId}}` — there is no free-text `message`,
/// so [userMessage] maps known `code`s to copy instead.
class BranchApiException implements Exception {
  const BranchApiException({
    required this.code,
    required this.category,
    required this.statusCode,
    this.messageKey,
  });

  final String code;
  final String category;
  final String? messageKey;
  final int statusCode;

  String get userMessage {
    switch (code) {
      case 'branch.limit_exceeded':
        return 'Branch limit reached for your subscription plan.';
      case 'branch.code_already_exists':
        return 'That branch code is already in use.';
      case 'branch.manager_not_found':
        return 'The specified manager could not be found for this tenant.';
      case 'branch.manager_inactive':
        return 'The specified manager is not active.';
      case 'branch.manager_not_eligible':
        return 'The specified user is not eligible to manage a branch.';
      case 'branch.already_inactive':
        return 'This branch is already inactive.';
      case 'branch.has_unresolved_orders':
        return 'This branch has unresolved orders and cannot be deactivated yet.';
      case 'branch.last_active_branch':
        return 'You cannot deactivate your only active branch.';
      case 'platform.unauthenticated':
        return 'Your session has expired. Please sign in again.';
    }
    if (statusCode == HttpStatus.notFound) {
      return 'Branch not found.';
    }
    if (statusCode == HttpStatus.forbidden) {
      return 'You are not allowed to perform this action.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  String toString() => userMessage;
}

/// HTTP client for the branch-service `/v1/branches` API.
class BranchApiService {
  BranchApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(baseUrl ?? _configuredBaseUrl());

  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _environmentKey = 'BRANCH_API_BASE_URL';

  final http.Client _client;
  final String _baseUrl;

  static String _configuredBaseUrl() {
    if (dotenv.isInitialized) {
      final String? configured = dotenv.env[_environmentKey]?.trim();
      if (configured != null && configured.isNotEmpty) return configured;
      final String? apiBase = dotenv.env['API_BASE_URL']?.trim();
      if (apiBase != null && apiBase.isNotEmpty) return apiBase;
    }
    return 'http://localhost:3000/api';
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Future<Map<String, String>> _headers() async {
    final session = await AuthenticationDependencies.tokenStorage.read();
    return <String, String>{
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  /// GET /v1/branches
  Future<BranchListResult> listBranches({
    BranchStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, String> query = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
      if (status != null) 'status': branchStatusToJson(status),
    };
    final Uri uri = Uri.parse(
      '$_baseUrl/v1/branches',
    ).replace(queryParameters: query);

    final Map<String, String> headers = await _headers();
    final http.Response response = await _send(
      () => _client.get(uri, headers: headers),
    );
    final Object? decoded = _decodeBody(response);
    final Map<String, dynamic> envelope = _requireEnvelope(decoded, response);
    _throwIfError(envelope, response);

    final List<dynamic> items = envelope['data'] as List<dynamic>? ?? const [];
    final Map<String, dynamic> meta =
        envelope['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return BranchListResult(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(Branch.fromJson)
          .toList(growable: false),
      page: meta['page'] as int? ?? page,
      pageSize: meta['pageSize'] as int? ?? pageSize,
      total: meta['total'] as int? ?? items.length,
    );
  }

  /// GET /v1/branches/statistics
  Future<BranchStatistics> statistics({BranchStatus? status}) async {
    final Uri uri = Uri.parse('$_baseUrl/v1/branches/statistics').replace(
      queryParameters: <String, String>{
        if (status != null) 'status': branchStatusToJson(status),
      },
    );
    final http.Response response = await _send(
      () async => _client.get(uri, headers: await _headers()),
    );
    final Map<String, dynamic> envelope = _requireEnvelope(
      _decodeBody(response),
      response,
    );
    _throwIfError(envelope, response);
    final Object? data = envelope['data'];
    if (data is! Map<String, dynamic>)
      throw _invalidResponse(response.statusCode);
    return BranchStatistics.fromJson(data);
  }

  /// POST /v1/branches
  Future<Branch> createBranch(CreateBranchInput input) async {
    final Map<String, String> headers = await _headers();
    final http.Response response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/v1/branches'),
        headers: headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return _decodeBranch(response);
  }

  /// PATCH /v1/branches/:branchId
  Future<Branch> updateBranch(String branchId, UpdateBranchInput input) async {
    final Map<String, String> headers = await _headers();
    final http.Response response = await _send(
      () => _client.patch(
        Uri.parse('$_baseUrl/v1/branches/$branchId'),
        headers: headers,
        body: jsonEncode(input.toJson()),
      ),
    );
    return _decodeBranch(response);
  }

  /// DELETE /v1/branches/:branchId (soft-deactivates; returns the updated branch)
  Future<Branch> deactivateBranch(String branchId) async {
    final Map<String, String> headers = await _headers();
    final http.Response response = await _send(
      () => _client.delete(
        Uri.parse('$_baseUrl/v1/branches/$branchId'),
        headers: headers,
      ),
    );
    return _decodeBranch(response);
  }

  Branch _decodeBranch(http.Response response) {
    final Object? decoded = _decodeBody(response);
    final Map<String, dynamic> envelope = _requireEnvelope(decoded, response);
    _throwIfError(envelope, response);
    final Map<String, dynamic>? data =
        envelope['data'] as Map<String, dynamic>?;
    if (data == null) throw _invalidResponse(response.statusCode);
    try {
      return Branch.fromJson(data);
    } on FormatException {
      throw _invalidResponse(response.statusCode);
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const BranchApiNetworkException('Branch Service unavailable');
    } on SocketException {
      throw const BranchApiNetworkException('Branch Service unavailable');
    } on http.ClientException {
      throw const BranchApiNetworkException('Branch Service unavailable');
    } catch (e) {
      if (e.toString().contains('XMLHttpRequest') || 
          e.toString().contains('Failed to fetch') ||
          e.toString().contains('NetworkError') ||
          e.toString().contains('ClientException')) {
        throw const BranchApiNetworkException('Branch Service unavailable');
      }
      rethrow;
    }
  }

  Object? _decodeBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw _invalidResponse(response.statusCode);
    }
  }

  Map<String, dynamic> _requireEnvelope(
    Object? decoded,
    http.Response response,
  ) {
    if (decoded is! Map<String, dynamic>) {
      throw _invalidResponse(response.statusCode);
    }
    return decoded;
  }

  void _throwIfError(Map<String, dynamic> envelope, http.Response response) {
    final Object? error = envelope['error'];
    if (error is Map<String, dynamic>) {
      throw BranchApiException(
        code: error['code'] as String? ?? 'branch.unknown',
        category: error['category'] as String? ?? 'internal',
        messageKey: error['messageKey'] as String?,
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BranchApiException(
        code: 'branch.http_${response.statusCode}',
        category: 'http',
        statusCode: response.statusCode,
      );
    }
  }

  BranchApiException _invalidResponse(int statusCode) {
    return BranchApiException(
      code: 'branch.invalid_response',
      category: 'internal',
      statusCode: statusCode,
    );
  }
}
