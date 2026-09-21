import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';

class CustomerApiException implements Exception {
  const CustomerApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CustomerApiService {
  CustomerApiService({
    required AuthTokenStorage tokenStorage,
    http.Client? client,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUri = Uri.parse(
         baseUrl ??
             BackendEnvironment.resolveBase(
               _environment('CUSTOMER_API_BASE_URL', 'http://10.0.2.2:3003'),
               'RENDER_CUSTOMER_API_BASE_URL',
             ),
       );

  static const Duration _timeout = Duration(seconds: 20);
  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final Uri _baseUri;
  String? _branchId;

  void selectBranch(String? branchId) {
    final String normalized = branchId?.trim() ?? '';
    _branchId = normalized.isEmpty || normalized == 'unavailable'
        ? null
        : normalized;
  }

  Future<CustomerPage> list({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final Uri uri = _customersUri().replace(
      queryParameters: <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (search.trim().isNotEmpty) 'search': search.trim(),
      },
    );
    final Object? decoded = await _request('GET', uri);
    final Map<String, dynamic> json = _map(_unwrap(decoded));
    return CustomerPage(
      items: (json['items'] as List<dynamic>)
          .map((dynamic item) => Customer.fromJson(_map(item)))
          .toList(growable: false),
      total: (json['total'] as num).toInt(),
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
    );
  }

  Future<CustomerStatistics> statistics() async => CustomerStatistics.fromJson(
    _map(_unwrap(await _request('GET', _customersUri().resolve('statistics')))),
  );

  Future<Customer> getById(String id) async => Customer.fromJson(
    _map(_unwrap(await _request('GET', _customersUri().resolve(id)))),
  );

  Future<Customer> create(CustomerDraft draft) async => Customer.fromJson(
    _map(
      _unwrap(await _request('POST', _customersUri(), body: draft.toJson())),
    ),
  );

  Future<Customer> update(String id, CustomerDraft draft) async =>
      Customer.fromJson(
        _map(
          _unwrap(
            await _request(
              'PATCH',
              _customersUri().resolve(id),
              body: draft.toJson(clearEmptyOptional: true),
            ),
          ),
        ),
      );

  Future<void> delete(String id) async {
    await _request('DELETE', _customersUri().resolve(id));
  }

  Uri _customersUri() => _baseUri.replace(path: '${_baseUri.path}/customers/');

  Future<Object?> _request(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
  }) async {
    final session = await _tokenStorage.read();
    if (session == null)
      throw const CustomerApiException('Please sign in again.');
    try {
      final http.Request request = http.Request(method, uri)
        ..headers.addAll(<String, String>{
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
          if (_branchId != null) 'x-branch-id': _branchId!,
          if (body != null) HttpHeaders.contentTypeHeader: 'application/json',
        });
      if (body != null) request.body = jsonEncode(body);
      final http.Response response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      );
      final Object? decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CustomerApiException(_errorMessage(decoded, response.statusCode));
      }
      return decoded;
    } on CustomerApiException {
      rethrow;
    } on TimeoutException {
      throw const CustomerApiException(
        'The request timed out. Please try again.',
      );
    } on SocketException catch (_) {
      throw const CustomerApiException('Unable to reach Customer Service.');
    } on http.ClientException catch (_) {
      throw const CustomerApiException('Unable to reach Customer Service.');
    } on FormatException catch (_) {
      throw const CustomerApiException(
        'Customer Service returned an invalid response.',
      );
    }
  }

  Object? _unwrap(Object? value) {
    if (value is Map<String, dynamic> && value.containsKey('data'))
      return value['data'];
    return value;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const CustomerApiException(
      'Customer Service returned an invalid response.',
    );
  }

  String _errorMessage(Object? value, int status) {
    if (value is Map<String, dynamic>) {
      final Object? message = value['message'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List<dynamic> && message.isNotEmpty) {
        return message.map((dynamic item) => '$item').join('\n');
      }
    }
    return status == 404
        ? 'Customer not found.'
        : 'Customer request failed. Please try again.';
  }

  static String _environment(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final String? value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}
