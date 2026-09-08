import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/settings/models/settings_models.dart';

class SettingsApiException implements Exception {
  const SettingsApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class SettingsApiService {
  SettingsApiService({
    required AuthTokenStorage tokenStorage,
    http.Client? client,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUri = _buildBaseUri(
         baseUrl ??
             _environment('SETTINGS_API_BASE_URL', 'http://10.0.2.2:3014/api'),
       );

  static const Duration _timeout = Duration(seconds: 20);

  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final Uri _baseUri;

  // ─────────────────────────────────────────────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────────────────────────────────────────────
  Future<BusinessCatalogSummaryModel> getSummary() async {
    final dynamic data = await _get(_baseUri);
    if (data is Map<String, dynamic>) {
      return BusinessCatalogSummaryModel.fromJson(data);
    }
    throw const SettingsApiException('Invalid summary response from server.');
  }

  Future<List<SettingsCatalogTemplateModel>> getTemplates() async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/templates');
    try {
      final dynamic data = await _get(uri);
      if (data is List) {
        return data
            .map(
              (e) => SettingsCatalogTemplateModel.fromJson(
                e as Map<String, dynamic>,
              ),
            )
            .toList(growable: false);
      }
    } catch (_) {
      // Fallback gracefully if templates endpoint is unreachable
    }
    return const <SettingsCatalogTemplateModel>[];
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SERVICES
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<SettingsServiceModel>> listServices({
    String? status,
    String? search,
  }) async {
    final Uri uri = _baseUri.replace(
      path: '${_baseUri.path}/services',
      queryParameters: <String, String>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final dynamic data = await _get(uri);
    if (data is List) {
      return data
          .map((e) => SettingsServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const <SettingsServiceModel>[];
  }

  Future<SettingsServiceModel> createService({
    required String serviceName,
    required String code,
    required String pricingType,
    String? description,
    String? categoryId,
    int? estimatedTimeMins,
    List<String>? branchIds,
    String status = 'Active',
    double? basePrice,
    List<String>? itemCategoryIds,
  }) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/services');
    final dynamic data = await _post(uri, <String, dynamic>{
      'serviceName': serviceName,
      'code': code,
      'pricingType': pricingType,
      if (description != null) 'description': description,
      if (categoryId != null) 'categoryId': categoryId,
      if (estimatedTimeMins != null) 'estimatedTimeMins': estimatedTimeMins,
      if (branchIds != null) 'branchIds': branchIds,
      'status': status,
      if (basePrice != null) 'basePrice': basePrice,
      if (itemCategoryIds != null) 'itemCategoryIds': itemCategoryIds,
    });
    return SettingsServiceModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SettingsServiceModel> updateService(
    String id, {
    String? serviceName,
    String? pricingType,
    String? description,
    String? categoryId,
    int? estimatedTimeMins,
    List<String>? branchIds,
    String? status,
  }) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/services/$id');
    final dynamic data = await _patch(uri, <String, dynamic>{
      if (serviceName != null) 'serviceName': serviceName,
      if (pricingType != null) 'pricingType': pricingType,
      if (description != null) 'description': description,
      if (categoryId != null) 'categoryId': categoryId,
      if (estimatedTimeMins != null) 'estimatedTimeMins': estimatedTimeMins,
      if (branchIds != null) 'branchIds': branchIds,
      if (status != null) 'status': status,
    });
    return SettingsServiceModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SettingsServiceModel> deleteService(String id) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/services/$id');
    final dynamic data = await _delete(uri);
    return SettingsServiceModel.fromJson(data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ITEMS
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<SettingsItemModel>> listItems({
    String? status,
    String? search,
  }) async {
    final Uri uri = _baseUri.replace(
      path: '${_baseUri.path}/items',
      queryParameters: <String, String>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final dynamic data = await _get(uri);
    if (data is List) {
      return data
          .map((e) => SettingsItemModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const <SettingsItemModel>[];
  }

  Future<SettingsItemModel> createItem({
    required String name,
    required String code,
    required String unitType,
    String? description,
    String? category,
    List<String>? catalogGroupCodes,
    List<String>? branchIds,
    String status = 'Active',
    double? basePrice,
    List<String>? serviceIds,
  }) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/items');
    final dynamic data = await _post(uri, <String, dynamic>{
      'name': name,
      'code': code,
      'unitType': unitType,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (catalogGroupCodes != null) 'catalogGroupCodes': catalogGroupCodes,
      if (branchIds != null) 'branchIds': branchIds,
      'status': status,
      if (basePrice != null) 'basePrice': basePrice,
      if (serviceIds != null) 'serviceIds': serviceIds,
    });
    return SettingsItemModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SettingsItemModel> updateItem(
    String id, {
    String? name,
    String? unitType,
    String? description,
    String? category,
    List<String>? catalogGroupCodes,
    List<String>? branchIds,
    String? status,
  }) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/items/$id');
    final dynamic data = await _patch(uri, <String, dynamic>{
      if (name != null) 'name': name,
      if (unitType != null) 'unitType': unitType,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (catalogGroupCodes != null) 'catalogGroupCodes': catalogGroupCodes,
      if (branchIds != null) 'branchIds': branchIds,
      if (status != null) 'status': status,
    });
    return SettingsItemModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SettingsItemModel> deleteItem(String id) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/items/$id');
    final dynamic data = await _delete(uri);
    return SettingsItemModel.fromJson(data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<SettingsCategoryModel>> listCategories({
    String? status,
    String? search,
  }) async {
    final Uri uri = _baseUri.replace(
      path: '${_baseUri.path}/categories',
      queryParameters: <String, String>{
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final dynamic data = await _get(uri);
    if (data is List) {
      return data
          .map((e) => SettingsCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const <SettingsCategoryModel>[];
  }

  Future<SettingsCategoryModel> createCategory({
    required String name,
    required String code,
    String? description,
    List<String>? branchIds,
    String status = 'Active',
  }) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/categories');
    final dynamic data = await _post(uri, <String, dynamic>{
      'name': name,
      'code': code,
      if (description != null) 'description': description,
      if (branchIds != null) 'branchIds': branchIds,
      'status': status,
    });
    return SettingsCategoryModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SettingsCategoryModel> updateCategory(
    String id, {
    String? name,
    String? description,
    List<String>? branchIds,
    String? status,
  }) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/categories/$id');
    final dynamic data = await _patch(uri, <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (branchIds != null) 'branchIds': branchIds,
      if (status != null) 'status': status,
    });
    return SettingsCategoryModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SettingsCategoryModel> deleteCategory(String id) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/categories/$id');
    final dynamic data = await _delete(uri);
    return SettingsCategoryModel.fromJson(data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRICING
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<SettingsPricingModel>> listPricing({
    String? serviceId,
    String? itemCategoryId,
    String? branchId,
  }) async {
    final Uri uri = _baseUri.replace(
      path: '${_baseUri.path}/pricing',
      queryParameters: <String, String>{
        if (serviceId != null) 'serviceId': serviceId,
        if (itemCategoryId != null) 'itemCategoryId': itemCategoryId,
        if (branchId != null) 'branchId': branchId,
      },
    );
    final dynamic data = await _get(uri);
    if (data is List) {
      return data
          .map((e) => SettingsPricingModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const <SettingsPricingModel>[];
  }

  Future<SettingsPricingModel> updatePricing(
    String id, {
    required double basePrice,
    double? taxPct,
    String? effectiveFrom,
    String? effectiveTo,
    String? status,
    String? branchId,
  }) async {
    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/pricing/$id');
    final dynamic data = await _patch(uri, <String, dynamic>{
      'basePrice': basePrice,
      if (taxPct != null) 'taxPct': taxPct,
      if (effectiveFrom != null) 'effectiveFrom': effectiveFrom,
      if (effectiveTo != null) 'effectiveTo': effectiveTo,
      if (status != null) 'status': status,
      if (branchId != null) 'branchId': branchId,
    });
    return SettingsPricingModel.fromJson(data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HTTP HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Future<dynamic> _get(Uri uri) async {
    final Map<String, String> headers = await _headers();
    try {
      final http.Response response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> _post(Uri uri, Map<String, dynamic> body) async {
    final Map<String, String> headers = await _headers();
    try {
      final http.Response response = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> _patch(Uri uri, Map<String, dynamic> body) async {
    final Map<String, String> headers = await _headers();
    try {
      final http.Response response = await _client
          .patch(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> _delete(Uri uri) async {
    final Map<String, String> headers = await _headers();
    try {
      final http.Response response = await _client
          .delete(uri, headers: headers)
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, String>> _headers() async {
    final session = await _tokenStorage.read();
    if (session == null || session.accessToken.isEmpty) {
      throw const SettingsApiException('Authentication session is required.');
    }
    return <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
      if (session.branchId != null && session.branchId!.isNotEmpty)
        'x-branch-id': session.branchId!,
    };
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body);
      }
    } catch (_) {
      throw const SettingsApiException(
        'Invalid response from Settings Service.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    if (response.statusCode == 401) {
      throw const SettingsApiException('Session expired. Please log in again.');
    }
    if (response.statusCode == 403) {
      throw const SettingsApiException(
        'You do not have permission to manage Business Settings.',
      );
    }
    if (response.statusCode == 409) {
      final String msg =
          _extractErrorMessage(decoded) ??
          'A record with this code already exists.';
      throw SettingsApiException(msg);
    }

    final String message =
        _extractErrorMessage(decoded) ??
        'Settings request failed (${response.statusCode}).';
    throw SettingsApiException(message);
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] is String) return decoded['message'] as String;
      if (decoded['message'] is List) {
        return (decoded['message'] as List).whereType<String>().join('\n');
      }
      if (decoded['error'] is Map &&
          (decoded['error'] as Map)['message'] is String) {
        return (decoded['error'] as Map)['message'] as String;
      }
    }
    return null;
  }

  SettingsApiException _handleError(Object error) {
    if (error is SettingsApiException) return error;
    if (error is SocketException || error is http.ClientException) {
      return const SettingsApiException(
        'Unable to reach Settings Service. Please check connection.',
      );
    }
    if (error is TimeoutException) {
      return const SettingsApiException(
        'Settings request timed out. Please try again.',
      );
    }
    return SettingsApiException(error.toString());
  }

  static Uri _buildBaseUri(String rawUrl) {
    final Uri parsed = Uri.parse(rawUrl.trim());
    final List<String> segments = parsed.pathSegments
        .where((s) => s.isNotEmpty)
        .toList();

    if (!segments.contains('api')) {
      segments.add('api');
    }
    if (!segments.contains('v1')) {
      segments.add('v1');
    }
    if (!segments.contains('settings-services')) {
      segments.add('settings-services');
    }

    return parsed.replace(pathSegments: segments);
  }

  static String _environment(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final String? value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}
