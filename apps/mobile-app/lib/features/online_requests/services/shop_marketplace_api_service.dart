import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/models/shop_marketplace_models.dart';

/// The shop's side of marketplace-service: its listing and online requests.
/// Uses the shop login; every call is scoped to [branchId] via x-branch-id.
class PhotoSlot {
  const PhotoSlot({required this.key, required this.uploadUrl});

  final String key;
  final String uploadUrl;
}

class ShopMarketplaceApiService {
  ShopMarketplaceApiService({
    required AuthTokenStorage tokenStorage,
    required this.branchId,
    Uri Function()? baseUri,
    http.Client? client,
  }) : _tokenStorage = tokenStorage,
       _baseUri = baseUri ?? ConsumerDependencies.marketplaceBaseUri,
       _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 20);

  final AuthTokenStorage _tokenStorage;
  final Uri Function() _baseUri;
  final http.Client _client;
  final String branchId;

  Future<ShopListing> getListing() async =>
      ShopListing.fromJson(_map(await _send('GET', 'v1/shop-listing/me')));

  Future<ShopListing> saveListing(ShopListingDraft draft) async =>
      ShopListing.fromJson(_map(await _send('PUT', 'v1/shop-listing/me', body: draft.toJson())));

  Future<ShopRequestSummary> summary() async =>
      ShopRequestSummary.fromJson(_map(await _send('GET', 'v1/shop/requests/summary')));

  Future<ShopRequestPage> listRequests({String? status, int page = 1}) async => ShopRequestPage.fromJson(
    _map(
      await _send(
        'GET',
        'v1/shop/requests',
        query: <String, String>{if (status != null) 'status': status, 'page': '$page', 'limit': '20'},
      ),
    ),
  );

  Future<ShopRequest> getRequest(String requestId) async =>
      ShopRequest.fromJson(_map(await _send('GET', 'v1/shop/requests/$requestId')));

  Future<ShopRequest> accept(
    String requestId, {
    DateTime? confirmedAt,
    String? note,
    String? workerId,
    String? workerName,
  }) async => ShopRequest.fromJson(
    _map(
      await _send(
        'POST',
        'v1/shop/requests/$requestId/accept',
        body: <String, Object>{
          if (confirmedAt != null) 'confirmedAt': confirmedAt.toUtc().toIso8601String(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
          if (workerId != null) 'workerId': workerId,
          if (workerName != null) 'workerName': workerName,
        },
      ),
    ),
  );

  Future<ShopRequest> assignWorker(String requestId, {required String workerId, required String workerName}) async =>
      ShopRequest.fromJson(
        _map(
          await _send(
            'POST',
            'v1/shop/requests/$requestId/assign-worker',
            body: <String, Object>{'workerId': workerId, 'workerName': workerName},
          ),
        ),
      );

  /// The automatic delivery date (YYYY-MM-DD) for this many items.
  Future<String> estimateDelivery(String requestId, {required int quantity}) async {
    final Map<String, dynamic> json = _map(
      await _send('GET', 'v1/shop/requests/$requestId/delivery-estimate', query: <String, String>{'quantity': '$quantity'}),
    );
    return json['deliveryDate'] as String? ?? '';
  }

  /// Signed links to upload [count] pickup photos to.
  Future<List<PhotoSlot>> photoUploadSlots(String requestId, {required int count}) async {
    final Map<String, dynamic> json = _map(
      await _send('POST', 'v1/shop/requests/$requestId/photo-upload-urls', body: <String, Object>{'count': count}),
    );
    return (json['slots'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> s) => PhotoSlot(key: s['key'] as String? ?? '', uploadUrl: s['uploadUrl'] as String? ?? ''))
        .toList(growable: false);
  }

  /// Sends one photo straight to S3 (the link already carries the permission).
  Future<void> uploadPhoto(PhotoSlot slot, List<int> bytes) async {
    final http.Response response;
    try {
      response = await _client
          .put(Uri.parse(slot.uploadUrl), headers: <String, String>{HttpHeaders.contentTypeHeader: 'image/jpeg'}, body: bytes)
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const ConsumerApiException('network', 'The photo upload timed out. Please try again.');
    } on SocketException {
      throw const ConsumerApiException('network', 'Unable to reach the server. Check your internet connection.');
    } on http.ClientException {
      throw const ConsumerApiException('network', 'Unable to reach the server. Check your internet connection.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ConsumerApiException('http.${response.statusCode}', 'A photo could not be uploaded. Please try again.', statusCode: response.statusCode);
    }
  }

  Future<ShopRequest> collect(
    String requestId, {
    int? totalItems,
    String? deliveryDate,
    String? note,
    List<String> photoKeys = const <String>[],
  }) async => ShopRequest.fromJson(
    _map(
      await _send(
        'POST',
        'v1/shop/requests/$requestId/collect',
        body: <String, Object>{
          if (totalItems != null) 'totalItems': totalItems,
          if (deliveryDate != null) 'deliveryDate': deliveryDate,
          if (photoKeys.isNotEmpty) 'photoKeys': photoKeys,
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        },
      ),
    ),
  );

  Future<ShopRequest> decline(String requestId, {required String reason}) async => ShopRequest.fromJson(
    _map(await _send('POST', 'v1/shop/requests/$requestId/decline', body: <String, Object>{'reason': reason.trim()})),
  );

  Future<ShopRequest> linkOrder(String requestId, {required String orderId}) async => ShopRequest.fromJson(
    _map(await _send('POST', 'v1/shop/requests/$requestId/link-order', body: <String, Object>{'orderId': orderId})),
  );

  Future<ShopRequest> complete(String requestId, {String? note}) async => ShopRequest.fromJson(
    _map(
      await _send(
        'POST',
        'v1/shop/requests/$requestId/complete',
        body: <String, Object>{if (note != null && note.trim().isNotEmpty) 'note': note.trim()},
      ),
    ),
  );

  Future<Object?> _send(String method, String path, {Map<String, Object?>? body, Map<String, String>? query}) async {
    final AuthenticationSession? session = await _tokenStorage.read();
    if (session == null) {
      throw const ConsumerApiException('session_expired', 'Your session has expired. Please sign in again.', statusCode: 401);
    }
    final Uri base = _baseUri();
    final String prefix = base.path.endsWith('/') ? base.path : '${base.path}/';
    final Uri uri = base.replace(path: '$prefix$path', queryParameters: query == null || query.isEmpty ? null : query);

    final http.Response response;
    try {
      final http.Request request = http.Request(method, uri)
        ..headers.addAll(<String, String>{
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
          if (branchId.isNotEmpty && branchId != 'unavailable') 'x-branch-id': branchId,
          if (body != null) HttpHeaders.contentTypeHeader: 'application/json',
        });
      if (body != null) request.body = jsonEncode(body);
      response = await http.Response.fromStream(await _client.send(request).timeout(_timeout));
    } on TimeoutException {
      throw const ConsumerApiException('network', 'The request timed out. Please try again.');
    } on SocketException {
      throw const ConsumerApiException('network', 'Unable to reach the server. Check your internet connection.');
    } on http.ClientException {
      throw const ConsumerApiException('network', 'Unable to reach the server. Check your internet connection.');
    }

    final Object? decoded = response.body.trim().isEmpty ? null : _tryDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return decoded;

    String message = 'Something went wrong. Please try again.';
    if (decoded is Map<String, dynamic>) {
      final Object? raw = decoded['message'];
      if (raw is String && raw.trim().isNotEmpty) message = raw.trim();
      final Object? details = decoded['details'];
      if (details is Map<String, dynamic> && details['errors'] is List) {
        final List<String> parts = (details['errors'] as List).whereType<String>().toList();
        if (parts.isNotEmpty) message = parts.join('\n');
      }
    }
    throw ConsumerApiException('http.${response.statusCode}', message, statusCode: response.statusCode);
  }

  Object? _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> _map(Object? value) => value is Map<String, dynamic> ? value : const <String, dynamic>{};
}
