import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/orders/models/order_catalog.dart';

class OrderCatalogApiException implements Exception {
  const OrderCatalogApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OrderCatalogApiService {
  OrderCatalogApiService({
    required AuthTokenStorage tokenStorage,
    http.Client? client,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUri = _apiV1Uri(
         baseUrl ??
             _environment('SERVICE_API_BASE_URL', 'http://10.0.2.2:3010/api'),
       );

  static const Duration _timeout = Duration(seconds: 20);
  static const int _pageSize = 100;

  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final Uri _baseUri;
  String? _branchId;
  String? _tenantId;

  void selectBranch(String? branchId) {
    final String value = branchId?.trim() ?? '';
    _branchId = value.isEmpty || value == 'unavailable' ? null : value;
  }

  Future<List<OrderItemCategory>> allItemCategories() async {
    final List<OrderItemCategory> records = <OrderItemCategory>[];
    int page = 1;
    do {
      final CatalogPage<OrderItemCategory> result = await listItemCategories(
        page: page,
      );
      records.addAll(result.items);
      page += 1;
      if (result.items.isEmpty) break;
      if (records.length >= result.total) break;
    } while (true);
    return records;
  }

  Future<CatalogPage<OrderItemCategory>> listItemCategories({
    int page = 1,
    String search = '',
  }) async {
    final Map<String, dynamic> json = await _getMap(
      _baseUri
          .resolve('item-categories')
          .replace(
            queryParameters: <String, String>{
              'page': '$page',
              'limit': '$_pageSize',
              'status': 'Active',
              'branchId': _requiredBranch,
              'sortBy': 'name',
              'sortDirection': 'asc',
              if (search.trim().isNotEmpty) 'search': search.trim(),
            },
          ),
    );
    return CatalogPage<OrderItemCategory>(
      items: catalogList(json['items'])
          .map((Object? item) => OrderItemCategory.fromJson(catalogMap(item)))
          .where(
            (OrderItemCategory item) =>
                _belongsToCurrentTenant(item.tenantId),
          )
          .toList(growable: false),
      total: catalogRequiredInt(json, 'total'),
      page: catalogRequiredInt(json, 'page'),
      limit: catalogRequiredInt(json, 'limit'),
    );
  }

  Future<List<OrderCatalogService>> allServices() async {
    final List<OrderCatalogService> records = <OrderCatalogService>[];
    int page = 1;
    do {
      final CatalogPage<OrderCatalogService> result = await listServices(
        page: page,
      );
      records.addAll(result.items);
      page += 1;
      if (result.items.isEmpty) break;
      if (records.length >= result.total) break;
    } while (true);
    return records;
  }

  Future<CatalogPage<OrderCatalogService>> listServices({
    int page = 1,
    String search = '',
  }) async {
    final Map<String, dynamic> json = await _getMap(
      _baseUri
          .resolve('services')
          .replace(
            queryParameters: <String, String>{
              'page': '$page',
              'limit': '$_pageSize',
              'status': 'Active',
              'branchId': _requiredBranch,
              'sortBy': 'name',
              'sortDirection': 'asc',
              if (search.trim().isNotEmpty) 'search': search.trim(),
            },
          ),
    );
    return CatalogPage<OrderCatalogService>(
      items: catalogList(json['items'])
          .map((Object? item) => OrderCatalogService.fromJson(catalogMap(item)))
          .where(
            (OrderCatalogService item) =>
                _belongsToCurrentTenant(item.tenantId),
          )
          .toList(growable: false),
      total: catalogRequiredInt(json, 'total'),
      page: catalogRequiredInt(json, 'page'),
      limit: catalogRequiredInt(json, 'limit'),
    );
  }

  Future<OrderCatalogQuote> quote({
    required String serviceId,
    required String itemCategoryId,
    double? quantity,
    double? weight,
  }) async => OrderCatalogQuote.fromJson(
    await _getMap(
      _baseUri
          .resolve('services/$serviceId/quote')
          .replace(
            queryParameters: <String, String>{
              'itemCategoryId': itemCategoryId,
              'branchId': _requiredBranch,
              if (quantity != null) 'quantity': '$quantity',
              if (weight != null) 'weight': '$weight',
            },
          ),
    ),
  );

  String get _requiredBranch {
    final String? branchId = _branchId;
    if (branchId == null) {
      throw const OrderCatalogApiException(
        'Select an active branch to load the service catalog.',
      );
    }
    return branchId;
  }

  Future<Map<String, dynamic>> _getMap(Uri uri) async {
    try {
      return catalogMap(_unwrap(await _get(uri)));
    } on OrderCatalogApiException {
      rethrow;
    } on FormatException {
      throw const OrderCatalogApiException(
        'Service Management returned an invalid response.',
      );
    }
  }

  Future<Object?> _get(Uri uri) async {
    final session = await _tokenStorage.read();
    if (session == null) {
      throw const OrderCatalogApiException('Please sign in again.');
    }
    final String sessionTenantId = session.tenantId?.trim() ?? '';
    _tenantId = sessionTenantId.isEmpty ? null : sessionTenantId;
    final String branchId = _requiredBranch;
    try {
      final http.Response response = await _client
          .get(
            uri,
            headers: <String, String>{
              HttpHeaders.acceptHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
              'x-branch-id': branchId,
            },
          )
          .timeout(_timeout);
      final Object? decoded = response.body.trim().isEmpty
          ? null
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrderCatalogApiException(
          _errorMessage(decoded, response.statusCode),
        );
      }
      return decoded;
    } on OrderCatalogApiException {
      rethrow;
    } on TimeoutException {
      throw const OrderCatalogApiException(
        'The catalog request timed out. Please try again.',
      );
    } on SocketException {
      throw const OrderCatalogApiException(
        'Unable to reach Service Management.',
      );
    } on http.ClientException {
      throw const OrderCatalogApiException(
        'Unable to reach Service Management.',
      );
    } on FormatException {
      throw const OrderCatalogApiException(
        'Service Management returned an invalid response.',
      );
    }
  }

  Object? _unwrap(Object? value) {
    if (value is Map<String, dynamic> && value.containsKey('data')) {
      return value['data'];
    }
    return value;
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
      400 => 'The selected service is not available for this item.',
      401 => 'Please sign in again.',
      403 => 'This catalog is unavailable for the selected branch.',
      404 => 'No active price is available for this selection.',
      _ => 'Unable to load the service catalog. Please try again.',
    };
  }

  String? _message(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is List) {
      final List<String> values = value.whereType<String>().toList();
      if (values.isNotEmpty) return values.join('\n');
    }
    return null;
  }

  bool _belongsToCurrentTenant(String tenantId) =>
      _tenantId == null || tenantId == _tenantId;

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
