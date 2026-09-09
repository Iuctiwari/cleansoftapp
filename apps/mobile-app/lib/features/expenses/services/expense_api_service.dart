import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/expenses/models/expense.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_data_source.dart';

class ExpenseApiException implements Exception {
  const ExpenseApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ExpenseApiService implements ExpenseDataSource {
  ExpenseApiService({
    required AuthTokenStorage tokenStorage,
    http.Client? client,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUrl = _normalizeBaseUrl(
         baseUrl ?? BackendEnvironment.resolveBase(_configuredBaseUrl()),
       );

  static const Duration _requestTimeout = Duration(seconds: 15);
  static const String _environmentKey = 'EXPENSE_API_BASE_URL';

  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final String _baseUrl;
  String? _branchId;

  @override
  void selectBranch(String? branchId) {
    final String value = branchId?.trim() ?? '';
    _branchId = value.isEmpty || value == 'unavailable' ? null : value;
  }

  static String _configuredBaseUrl() {
    if (dotenv.isInitialized) {
      final String? configured = dotenv.env[_environmentKey]?.trim();
      if (configured != null && configured.isNotEmpty) return configured;
      final String? apiBase = dotenv.env['API_BASE_URL']?.trim();
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

  Future<Map<String, String>> _headers() async {
    final session = await _tokenStorage.read();
    if (session == null) {
      throw const ExpenseApiException('Please sign in again.');
    }
    if (_branchId == null) {
      throw const ExpenseApiException('Select an active branch to manage expenses.');
    }

    return <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
      'x-branch-id': _branchId!,
    };
  }

  @override
  Future<List<ExpensePaymentOption>> getPaymentMethods() async {
    return ExpensePaymentOption.defaultOptions;
  }

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    final Uri uri = Uri.parse('$_baseUrl/expense-categories');
    final Map<String, String> headers = await _headers();

    final http.Response response = await _send(() => _client.get(uri, headers: headers));
    final Object? decoded = _decodeBody(response);

    if (decoded is List<dynamic>) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ExpenseCategory.fromJson)
          .toList(growable: false);
    }
    if (decoded is Map<String, dynamic> && decoded['data'] is List<dynamic>) {
      return (decoded['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ExpenseCategory.fromJson)
          .toList(growable: false);
    }

    return const <ExpenseCategory>[];
  }

  @override
  Future<List<Expense>> getExpenses({
    ExpenseFilter filter = const ExpenseFilter(),
  }) async {
    final Map<String, String> query = <String, String>{
      'page': '1',
      'limit': '100',
      if (filter.categoryId != null && filter.categoryId!.isNotEmpty)
        'categoryId': filter.categoryId!,
      if (filter.search != null && filter.search!.trim().isNotEmpty)
        'search': filter.search!.trim(),
    };

    final Uri uri = Uri.parse('$_baseUrl/expenses').replace(queryParameters: query);
    final Map<String, String> headers = await _headers();

    final http.Response response = await _send(() => _client.get(uri, headers: headers));
    final Object? decoded = _decodeBody(response);

    if (decoded is Map<String, dynamic>) {
      final dynamic items = decoded['items'] ?? decoded['data'];
      if (items is List<dynamic>) {
        return items
            .whereType<Map<String, dynamic>>()
            .map(Expense.fromJson)
            .toList(growable: false);
      }
    } else if (decoded is List<dynamic>) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Expense.fromJson)
          .toList(growable: false);
    }

    return const <Expense>[];
  }

  @override
  Future<ExpenseStatistics> getStatistics() async {
    final Uri uri = Uri.parse('$_baseUrl/expenses/statistics');
    final Map<String, String> headers = await _headers();
    final http.Response response = await _send(
      () => _client.get(uri, headers: headers),
    );
    final Object? decoded = _decodeBody(response);

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded is Map<String, dynamic>) {
      final Map<String, dynamic> data =
          decoded['data'] is Map<String, dynamic>
          ? decoded['data'] as Map<String, dynamic>
          : decoded;
      return ExpenseStatistics.fromJson(data);
    }

    throw ExpenseApiException(_errorMessage(decoded, response.statusCode));
  }

  @override
  Future<Expense> createExpense(CreateExpenseRequest request) async {
    final Uri uri = Uri.parse('$_baseUrl/expenses');
    final Map<String, String> headers = await _headers();

    final http.Response response = await _send(
      () => _client.post(
        uri,
        headers: <String, String>{
          ...headers,
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ),
    );
    final Object? decoded = _decodeBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        final Map<String, dynamic> data =
            decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        return Expense.fromJson(data);
      }
    }

    throw ExpenseApiException(_errorMessage(decoded, response.statusCode));
  }

  @override
  Future<Expense> updateExpense(String id, UpdateExpenseRequest request) async {
    final Uri uri = Uri.parse('$_baseUrl/expenses/$id');
    final Map<String, String> headers = await _headers();

    final http.Response response = await _send(
      () => _client.patch(
        uri,
        headers: <String, String>{
          ...headers,
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ),
    );
    final Object? decoded = _decodeBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        final Map<String, dynamic> data =
            decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        return Expense.fromJson(data);
      }
    }

    throw ExpenseApiException(_errorMessage(decoded, response.statusCode));
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_requestTimeout);
    } on TimeoutException {
      throw const ExpenseApiException('The expense service request timed out.');
    } on SocketException {
      throw const ExpenseApiException('Unable to reach Expense Service.');
    } on http.ClientException {
      throw const ExpenseApiException('Unable to reach Expense Service.');
    }
  }

  Object? _decodeBody(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } on FormatException {
      throw ExpenseApiException('Invalid response from Expense Service (${response.statusCode})');
    }
  }

  String _errorMessage(Object? decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final dynamic message = decoded['message'] ?? decoded['error'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List<dynamic> && message.isNotEmpty) {
        return message.map((dynamic item) => '$item').join('\n');
      }
      if (message is Map<String, dynamic> && message['message'] is String) {
        return message['message'] as String;
      }
    }
    return 'Expense request failed ($statusCode)';
  }
}
