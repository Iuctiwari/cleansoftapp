import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';

/// Fetches the Order Service PDF receipt.
///
/// Kept isolated from [OrderApiService] on purpose: the Order module is
/// owned by another developer, and the receipt endpoint returns raw PDF
/// bytes rather than JSON, so it does not fit that service's response
/// parsing. Both services point at the same Order Service base URL.
class ReceiptApiException implements Exception {
  const ReceiptApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReceiptApiService {
  ReceiptApiService({required AuthTokenStorage tokenStorage, http.Client? client, String? baseUrl})
    : _tokenStorage = tokenStorage,
      _client = client ?? http.Client(),
      _baseUri = _apiV1Uri(
        baseUrl ?? _environment('ORDER_API_BASE_URL', 'http://10.0.2.2:3007/api'),
      );

  static const Duration _timeout = Duration(seconds: 30);

  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final Uri _baseUri;

  Future<Uint8List> fetchReceiptPdf({
    required String orderId,
    required String branchId,
  }) async {
    final session = await _tokenStorage.read();
    if (session == null) {
      throw const ReceiptApiException('Please sign in again.');
    }

    final Uri uri = _baseUri.resolve(
      'orders/${Uri.encodeComponent(orderId)}/receipt',
    );

    try {
      final http.Request request = http.Request('GET', uri)
        ..headers.addAll(<String, String>{
          HttpHeaders.acceptHeader: 'application/pdf',
          HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
          'x-branch-id': branchId,
        });
      final http.Response response = await http.Response.fromStream(
        await _client.send(request).timeout(_timeout),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ReceiptApiException(_errorMessage(response.statusCode));
      }
      return response.bodyBytes;
    } on ReceiptApiException {
      rethrow;
    } on TimeoutException {
      throw const ReceiptApiException('The request timed out. Please try again.');
    } on SocketException {
      throw const ReceiptApiException('Unable to reach Order Service.');
    } on http.ClientException {
      throw const ReceiptApiException('Unable to reach Order Service.');
    }
  }

  String _errorMessage(int status) => switch (status) {
    401 => 'Please sign in again.',
    403 => 'You do not have access to this receipt.',
    404 => 'Order not found.',
    _ => 'Unable to generate the receipt. Please try again.',
  };

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
