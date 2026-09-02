import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/reports/models/report_data.dart';
import 'package:nexoraa_mobile/features/reports/services/report_data_source.dart';

class ReportApiException implements Exception {
  const ReportApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReportApiService implements ReportDataSource {
  ReportApiService({
    required AuthTokenStorage tokenStorage,
    http.Client? client,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUrl = _normalizeBaseUrl(baseUrl ?? _configuredBaseUrl());

  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _environmentKey = 'REPORT_API_BASE_URL';

  final String _baseUrl;
  final http.Client _client;
  final AuthTokenStorage _tokenStorage;
  String? _branchId;

  @override
  void selectBranch(String? branchId) {
    final String value = branchId?.trim() ?? '';
    _branchId = value.isEmpty || value == 'unavailable' ? null : value;
  }

  @override
  Future<ReportSummary> loadSummary(ReportQuery query) async =>
      ReportSummary.fromJson(await _getReport('summary', query));

  @override
  Future<BranchPerformanceReport> loadBranchPerformance(
    ReportQuery query,
  ) async => BranchPerformanceReport.fromJson(
    await _getReport('branch-performance', query),
  );

  @override
  Future<OrderReport> loadOrders(ReportQuery query) async =>
      OrderReport.fromJson(await _getReport('orders', query));

  @override
  Future<PaymentReport> loadPayments(ReportQuery query) async =>
      PaymentReport.fromJson(await _getReport('payments', query));

  @override
  Future<ExpenseReport> loadExpenses(ReportQuery query) async =>
      ExpenseReport.fromJson(await _getReport('expenses', query));

  Future<Map<String, dynamic>> _getReport(
    String resource,
    ReportQuery query,
  ) async {
    final session = await _tokenStorage.read();
    if (session == null) {
      throw const ReportApiException('Please sign in again.');
    }
    if (_branchId == null) {
      throw const ReportApiException(
        'Select an active branch to view reports.',
      );
    }
    final Uri uri = Uri.parse(
      '$_baseUrl/api/v1/reports/$resource',
    ).replace(queryParameters: query.toQueryParameters());

    try {
      final http.Response response = await _client
          .get(
            uri,
            headers: <String, String>{
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
              'x-branch-id': _branchId!,
            },
          )
          .timeout(_requestTimeout);
      final Object? decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ReportApiException(_errorMessage(decoded, response.statusCode));
      }
      final Object? unwrapped =
          decoded is Map<String, dynamic> && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
      if (unwrapped is Map<String, dynamic>) return unwrapped;
      throw const ReportApiException(
        'Report Service returned an invalid response.',
      );
    } on ReportApiException {
      rethrow;
    } on TimeoutException {
      throw const ReportApiException(
        'The report request timed out. Please try again.',
      );
    } on SocketException {
      throw const ReportApiException('Unable to reach Report Service.');
    } on http.ClientException {
      throw const ReportApiException('Unable to reach Report Service.');
    } on FormatException {
      throw const ReportApiException(
        'Report Service returned an invalid response.',
      );
    }
  }

  static String _configuredBaseUrl() {
    if (dotenv.isInitialized) {
      final String? configured = dotenv.env[_environmentKey]?.trim();
      if (configured != null && configured.isNotEmpty) return configured;
      final String? apiBase = dotenv.env['API_BASE_URL']?.trim();
      if (apiBase != null && apiBase.isNotEmpty) return apiBase;
    }
    return 'http://10.0.2.2:3008/api';
  }

  static String _normalizeBaseUrl(String value) {
    var normalized = value.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    for (final String suffix in <String>['/api/v1', '/v1', '/api']) {
      if (normalized.endsWith(suffix)) {
        normalized = normalized.substring(0, normalized.length - suffix.length);
        break;
      }
    }
    return normalized;
  }

  String _errorMessage(Object? decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final Object? error = decoded['error'];
      if (error is Map<String, dynamic> && error['message'] is String) {
        return error['message'] as String;
      }
      final Object? message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List<dynamic> && message.isNotEmpty) {
        return message.map((Object? item) => '$item').join('\n');
      }
    }
    return 'Report request failed ($statusCode).';
  }
}
