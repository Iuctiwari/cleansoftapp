import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/payments/models/payment.dart';

class PaymentApiService {
  PaymentApiService({
    required AuthTokenStorage tokenStorage,
    http.Client? client,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUrl = _apiV1Url(
         baseUrl ??
             BackendEnvironment.resolveBase(
               _environment('PAYMENT_API_BASE_URL', 'http://10.0.2.2:3008'),
             ),
       );

  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final String _baseUrl;
  String? _branchId;

  void selectBranch(String branchId) => _branchId = branchId.trim();

  Future<Order> createAdvance({
    required String idempotencyKey,
    required String orderId,
    required String customerId,
    required double amount,
    required PaymentMethod method,
  }) async {
    final session = await _tokenStorage.read();
    if (session == null) throw const OrderApiException('Please sign in again.');
    if (_branchId == null || _branchId!.isEmpty) {
      throw const OrderApiException(
        'Select an active branch before recording payment.',
      );
    }
    try {
      final http.Response response = await _client
          .post(
            Uri.parse('$_baseUrl/payments'),
            headers: <String, String>{
              HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
              HttpHeaders.contentTypeHeader: 'application/json',
              'idempotency-key': idempotencyKey,
              'x-branch-id': _branchId!,
            },
            body: jsonEncode(<String, Object>{
              'amountMinor': (amount * 100).round(),
              'currency': 'INR',
              'customerId': customerId,
              'method': method.apiValue,
              'orderId': orderId,
              'paymentType': 'Advance',
            }),
          )
          .timeout(const Duration(seconds: 20));
      final Object? decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrderApiException(_message(decoded));
      }
      final Map<String, dynamic> body = _map(decoded);
      return Order.fromJson(_map(body['order']));
    } on OrderApiException {
      rethrow;
    } on TimeoutException {
      throw const OrderApiException(
        'The payment request timed out. Please retry.',
      );
    } on SocketException {
      throw const OrderApiException('Unable to reach Payment Management.');
    } on http.ClientException {
      throw const OrderApiException('Unable to reach Payment Management.');
    } on FormatException {
      throw const OrderApiException(
        'Payment Management returned an invalid response.',
      );
    }
  }

  Future<PaymentPage> list({
    int page = 1,
    int limit = 20,
    PaymentTransactionStatus? status,
    String? customerId,
    String sortDirection = 'desc',
  }) async {
    final session = await _tokenStorage.read();
    if (session == null) throw const OrderApiException('Please sign in again.');
    if (_branchId == null || _branchId!.isEmpty) {
      throw const OrderApiException(
        'Select an active branch to view payments.',
      );
    }
    final Uri uri = Uri.parse('$_baseUrl/payments').replace(
      queryParameters: <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (status != null) 'status': status.apiValue,
        if (customerId != null && customerId.trim().isNotEmpty)
          'customerId': customerId.trim(),
        'sortDirection': sortDirection,
      },
    );
    try {
      final http.Response response = await _client
          .get(
            uri,
            headers: <String, String>{
              HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
              'x-branch-id': _branchId!,
            },
          )
          .timeout(const Duration(seconds: 20));
      final Object? decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrderApiException(_message(decoded));
      }
      return PaymentPage.fromJson(_map(decoded));
    } on OrderApiException {
      rethrow;
    } on TimeoutException {
      throw const OrderApiException('The request timed out. Please try again.');
    } on SocketException {
      throw const OrderApiException('Unable to reach Payment Management.');
    } on http.ClientException {
      throw const OrderApiException('Unable to reach Payment Management.');
    } on FormatException {
      throw const OrderApiException(
        'Payment Management returned an invalid response.',
      );
    }
  }

  Future<PaymentStatistics> statistics({String? customerId}) async {
    final Uri uri = Uri.parse('$_baseUrl/payments/statistics').replace(
      queryParameters: <String, String>{
        if (customerId != null && customerId.trim().isNotEmpty)
          'customerId': customerId.trim(),
      },
    );
    try {
      return PaymentStatistics.fromJson(_map(await _get(uri)));
    } on OrderApiException {
      rethrow;
    } on FormatException {
      throw const OrderApiException(
        'Payment Management returned invalid statistics.',
      );
    }
  }

  Future<Object?> _get(Uri uri) async {
    final session = await _tokenStorage.read();
    if (session == null) throw const OrderApiException('Please sign in again.');
    if (_branchId == null || _branchId!.isEmpty) {
      throw const OrderApiException(
        'Select an active branch to view payments.',
      );
    }
    try {
      final http.Response response = await _client
          .get(
            uri,
            headers: <String, String>{
              HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
              'x-branch-id': _branchId!,
            },
          )
          .timeout(const Duration(seconds: 20));
      final Object? decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrderApiException(_message(decoded));
      }
      return decoded;
    } on OrderApiException {
      rethrow;
    } on TimeoutException {
      throw const OrderApiException('The request timed out. Please try again.');
    } on SocketException {
      throw const OrderApiException('Unable to reach Payment Management.');
    } on http.ClientException {
      throw const OrderApiException('Unable to reach Payment Management.');
    }
  }

  String _message(Object? value) {
    if (value is Map<String, dynamic>) {
      final Object? message = value['message'];
      if (message is String && message.trim().isNotEmpty) return message.trim();
      if (message is List) return message.whereType<String>().join('\n');
    }
    return 'Unable to record the advance payment.';
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const FormatException('Expected a JSON object.');
  }

  static String _apiV1Url(String value) {
    final Uri source = Uri.parse(value.trim());
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
    return source.replace(pathSegments: segments).toString();
  }

  static String _environment(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final String? value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}
