import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';

class OrderApiException implements Exception {
  const OrderApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OrderApiService {
  OrderApiService({
    required AuthTokenStorage tokenStorage,
    http.Client? client,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUri = _apiV1Uri(
         baseUrl ??
             _environment('ORDER_API_BASE_URL', 'http://10.0.2.2:3007/api'),
       );

  static const Duration _timeout = Duration(seconds: 20);
  static const int defaultPageSize = 20;

  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final Uri _baseUri;
  String? _branchId;

  void selectBranch(String? branchId) {
    final String value = branchId?.trim() ?? '';
    _branchId = value.isEmpty || value == 'unavailable' ? null : value;
  }

  Future<OrderPage> list({
    int page = 1,
    int limit = defaultPageSize,
    String search = '',
    OrderStatus? status,
    OrderPaymentStatus? paymentStatus,
    String? customerId,
    String sortBy = 'createdAt',
    String sortDirection = 'desc',
  }) async {
    final Uri uri = _ordersUri().replace(
      queryParameters: <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null) 'status': status.apiValue,
        if (paymentStatus != null) 'paymentStatus': paymentStatus.apiValue,
        if (customerId != null && customerId.trim().isNotEmpty)
          'customerId': customerId.trim(),
        'sortBy': sortBy,
        'sortDirection': sortDirection,
      },
    );
    try {
      return OrderPage.fromJson(_map(_unwrap(await _get(uri))));
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned an invalid response.',
      );
    }
  }

  Future<Order> getById(String id) async {
    try {
      return Order.fromJson(
        _map(
          _unwrap(await _get(_ordersUri().resolve(Uri.encodeComponent(id)))),
        ),
      );
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned an invalid response.',
      );
    }
  }

  Future<OrderStatistics> statistics({String? customerId}) async {
    final Uri uri = _ordersUri()
        .resolve('statistics')
        .replace(
          queryParameters: <String, String>{
            if (customerId != null && customerId.trim().isNotEmpty)
              'customerId': customerId.trim(),
          },
        );
    try {
      return OrderStatistics.fromJson(_map(_unwrap(await _get(uri))));
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned invalid statistics.',
      );
    }
  }

  Future<List<OrderStatusHistory>> getHistory(String id) async {
    try {
      final Object? value = _unwrap(
        await _get(_ordersUri().resolve('${Uri.encodeComponent(id)}/history')),
      );
      if (value is! List) {
        throw const FormatException('Expected an order history list.');
      }
      return value
          .map((Object? entry) => OrderStatusHistory.fromJson(_map(entry)))
          .toList(growable: false);
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned invalid status history.',
      );
    }
  }

  Future<Order> changeStatus(
    String id,
    OrderStatus status, {
    String? note,
  }) async {
    try {
      return Order.fromJson(
        _map(
          _unwrap(
            await _request(
              'PATCH',
              _ordersUri().resolve('${Uri.encodeComponent(id)}/status'),
              body: <String, Object?>{
                'status': status.apiValue,
                if (note?.trim().isNotEmpty ?? false) 'note': note!.trim(),
              },
            ),
          ),
        ),
      );
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned an invalid response.',
      );
    }
  }

  Future<Order> create(CreateOrderInput input) async {
    try {
      return Order.fromJson(
        _map(
          _unwrap(await _request('POST', _ordersUri(), body: input.toJson())),
        ),
      );
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned an invalid response.',
      );
    }
  }

  Future<Order> assignWorker(
    String id,
    String staffId, {
    DateTime? dueDate,
    String? note,
  }) async {
    try {
      return Order.fromJson(
        _map(
          _unwrap(
            await _request(
              'POST',
              _ordersUri().resolve('${Uri.encodeComponent(id)}/assign'),
              body: <String, Object?>{
                'assignedTo': staffId.trim(),
                if (dueDate != null)
                  'dueDate': dueDate.toUtc().toIso8601String(),
                if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
              },
            ),
          ),
        ),
      );
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned an invalid response.',
      );
    }
  }

  Future<Order> acceptAssignment(String id) async {
    try {
      return Order.fromJson(
        _map(
          _unwrap(
            await _request(
              'POST',
              _ordersUri().resolve(
                '${Uri.encodeComponent(id)}/assignment/accept',
              ),
            ),
          ),
        ),
      );
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned an invalid response.',
      );
    }
  }

  Future<Order> rejectAssignment(String id, {String? reason}) async {
    try {
      return Order.fromJson(
        _map(
          _unwrap(
            await _request(
              'POST',
              _ordersUri().resolve(
                '${Uri.encodeComponent(id)}/assignment/reject',
              ),
              body: reason?.trim().isNotEmpty == true
                  ? <String, Object?>{'reason': reason!.trim()}
                  : null,
            ),
          ),
        ),
      );
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned an invalid response.',
      );
    }
  }

  Uri _ordersUri() => _baseUri.resolve('orders/');

  Future<Object?> _get(Uri uri) => _request('GET', uri);

  Future<Object?> _request(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
  }) async {
    final session = await _tokenStorage.read();
    if (session == null) throw const OrderApiException('Please sign in again.');
    if (_branchId == null) {
      throw const OrderApiException('Select an active branch to view orders.');
    }

    try {
      final http.Request request = http.Request(method, uri)
        ..headers.addAll(<String, String>{
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
          'x-branch-id': _branchId!,
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
        throw OrderApiException(_errorMessage(decoded, response.statusCode));
      }
      return decoded;
    } on OrderApiException {
      rethrow;
    } on TimeoutException {
      throw const OrderApiException('The request timed out. Please try again.');
    } on SocketException {
      throw const OrderApiException('Unable to reach Order Service.');
    } on http.ClientException {
      throw const OrderApiException('Unable to reach Order Service.');
    } on FormatException {
      throw const OrderApiException(
        'Order Service returned an invalid response.',
      );
    }
  }

  Object? _unwrap(Object? value) {
    if (value is Map<String, dynamic> && value.containsKey('data')) {
      return value['data'];
    }
    return value;
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const OrderApiException(
      'Order Service returned an invalid response.',
    );
  }

  String _errorMessage(Object? value, int status) {
    if (value is Map<String, dynamic>) {
      final Object? error = value['error'];
      if (error is Map<String, dynamic>) {
        final String? nested = _message(error['message']);
        if (nested != null) return nested;
      }
      final String? message = _message(value['message']);
      if (message != null) return message;
    }
    return switch (status) {
      400 => 'The order request is invalid.',
      401 => 'Please sign in again.',
      403 => 'You do not have access to these orders.',
      404 => 'Order not found.',
      409 => 'The order changed while it was being saved. Please try again.',
      _ => 'Unable to load orders. Please try again.',
    };
  }

  String? _message(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List) {
      final List<String> messages = value.whereType<String>().toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }
    return null;
  }

  static Uri _apiV1Uri(String baseUrl) {
    final Uri source = Uri.parse(baseUrl.trim());
    final List<String> segments = source.pathSegments
        .where((String segment) => segment.isNotEmpty)
        .toList();
    if (segments.length < 2 ||
        segments[segments.length - 2] != 'api' ||
        segments.last != 'v1') {
      if (segments.isNotEmpty && segments.last == 'api') {
        segments.add('v1');
      } else {
        segments.addAll(<String>['api', 'v1']);
      }
    }
    return source.replace(pathSegments: <String>[...segments, '']);
  }

  static String _environment(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final String? value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}
