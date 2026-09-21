import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_token_storage.dart';

class CompanyAdminApiException implements Exception {
  const CompanyAdminApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Talks to platform-admin-service (Phases 1-4). Uses CompanyAdminTokenStorage
/// exclusively — never AuthTokenStorage — so admin auth and tenant/staff auth
/// can never collide, matching platform-admin-service's own isolation from
/// auth-service's tenant/platform-kind system.
class CompanyAdminApiService {
  CompanyAdminApiService({
    required CompanyAdminTokenStorage tokenStorage,
    http.Client? client,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUri = _buildBaseUri(
         baseUrl ??
             BackendEnvironment.resolveBase(
               _environment(
                 'PLATFORM_ADMIN_API_BASE_URL',
                 'http://10.0.2.2:3015/api',
               ),
               'RENDER_PLATFORM_ADMIN_API_BASE_URL',
             ),
       );

  static const Duration _timeout = Duration(seconds: 20);

  final CompanyAdminTokenStorage _tokenStorage;
  final http.Client _client;
  final Uri _baseUri;

  Uri _path(String path) => _baseUri.replace(path: '${_baseUri.path}$path');

  // ─────────────────────────────────────────────────────────────────────────
  // AUTH
  // ─────────────────────────────────────────────────────────────────────────
  Future<AdminSession> login(String email, String password) async {
    final dynamic data = await _post(_path('/platform-admin/auth/login'), <String, dynamic>{
      'email': email,
      'password': password,
    }, requireAuth: false);
    final AdminSession session = AdminSession.fromLoginResponse(
      data as Map<String, dynamic>,
    );
    await _tokenStorage.write(session);
    return session;
  }

  Future<void> logout() => _tokenStorage.clear();

  // ─────────────────────────────────────────────────────────────────────────
  // BUSINESS TYPES (Phase 1)
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<BusinessTypeModel>> listBusinessTypes() async {
    final dynamic data = await _get(_path('/platform-admin/business-types'));
    if (data is List) {
      return data
          .map((e) => BusinessTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const <BusinessTypeModel>[];
  }

  Future<BusinessTypeModel> createBusinessType({
    required String value,
    required String label,
    String? description,
    BusinessTypeTerminologyModel? defaultTerminology,
    List<String>? defaultOrderStatuses,
    List<String>? defaultServices,
    List<String>? defaultItemCategories,
    List<String>? defaultExpenseCategories,
  }) async {
    final dynamic data = await _post(_path('/platform-admin/business-types'), <String, dynamic>{
      'value': value,
      'label': label,
      if (description != null && description.isNotEmpty) 'description': description,
      if (defaultTerminology != null) 'defaultTerminology': defaultTerminology.toJson(),
      if (defaultOrderStatuses != null) 'defaultOrderStatuses': defaultOrderStatuses,
      if (defaultServices != null) 'defaultServices': defaultServices,
      if (defaultItemCategories != null) 'defaultItemCategories': defaultItemCategories,
      if (defaultExpenseCategories != null) 'defaultExpenseCategories': defaultExpenseCategories,
    });
    return BusinessTypeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<BusinessTypeModel> updateBusinessType(
    String id, {
    String? label,
    String? description,
    bool? isActive,
    BusinessTypeTerminologyModel? defaultTerminology,
    List<String>? defaultOrderStatuses,
    List<String>? defaultServices,
    List<String>? defaultItemCategories,
    List<String>? defaultExpenseCategories,
  }) async {
    final dynamic data = await _patch(_path('/platform-admin/business-types/$id'), <String, dynamic>{
      if (label != null) 'label': label,
      if (description != null) 'description': description,
      if (isActive != null) 'isActive': isActive,
      if (defaultTerminology != null) 'defaultTerminology': defaultTerminology.toJson(),
      if (defaultOrderStatuses != null) 'defaultOrderStatuses': defaultOrderStatuses,
      if (defaultServices != null) 'defaultServices': defaultServices,
      if (defaultItemCategories != null) 'defaultItemCategories': defaultItemCategories,
      if (defaultExpenseCategories != null) 'defaultExpenseCategories': defaultExpenseCategories,
    });
    return BusinessTypeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteBusinessType(String id) =>
      _delete(_path('/platform-admin/business-types/$id'));

  // ─────────────────────────────────────────────────────────────────────────
  // TENANT DIRECTORY (Phase 5)
  // ─────────────────────────────────────────────────────────────────────────
  Future<TenantDirectoryPageModel> listTenants({
    String? search,
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final Uri uri = _path('/platform-admin/tenants').replace(
      queryParameters: <String, String>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final dynamic data = await _get(uri);
    return TenantDirectoryPageModel.fromJson(data as Map<String, dynamic>);
  }

  /// Enriched tenant list (plan/subscription-status/days-remaining) — the
  /// Clients tab and "tenants on this plan" both call this.
  Future<TenantOverviewPageModel> listTenantsOverview({
    String? tenantId,
    String? search,
    String? onboardingStatus,
    String? subscriptionStatus,
    String? planKey,
    int page = 1,
    int limit = 20,
  }) async {
    final Uri uri = _path('/platform-admin/tenants/overview').replace(
      queryParameters: <String, String>{
        if (tenantId != null && tenantId.isNotEmpty) 'tenantId': tenantId,
        if (search != null && search.isNotEmpty) 'search': search,
        if (onboardingStatus != null && onboardingStatus.isNotEmpty)
          'onboardingStatus': onboardingStatus,
        if (subscriptionStatus != null && subscriptionStatus.isNotEmpty)
          'subscriptionStatus': subscriptionStatus,
        if (planKey != null && planKey.isNotEmpty) 'planKey': planKey,
        'page': '$page',
        'limit': '$limit',
      },
    );
    final dynamic data = await _get(uri);
    return TenantOverviewPageModel.fromJson(data as Map<String, dynamic>);
  }

  Future<TenantResourceCountsModel> getResourceCounts(String tenantId) async {
    final dynamic data = await _get(
      _path('/platform-admin/tenants/$tenantId/resource-counts'),
    );
    return TenantResourceCountsModel.fromJson(data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBSCRIPTIONS & BILLING (Phases 2-3)
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<SubscriptionPlanModel>> listSubscriptionPlans() async {
    final dynamic data = await _get(_path('/platform-admin/subscription-plans'));
    if (data is List) {
      return data
          .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const <SubscriptionPlanModel>[];
  }

  /// Keyed by planKey — how many tenants currently sit on each plan.
  Future<Map<String, int>> getSubscriptionPlanTenantCounts() async {
    final dynamic data = await _get(_path('/platform-admin/subscription-plans/tenant-counts'));
    if (data is Map<String, dynamic>) {
      return data.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
    }
    return const <String, int>{};
  }

  Future<SubscriptionPlanModel> createSubscriptionPlan({
    required String planKey,
    required String displayName,
    required int monthlyPriceInPaise,
    required int annualPriceInPaise,
    required int maxBranches,
    required int maxStaff,
    required int maxMonthlyOrders,
    required int trialDays,
    List<String>? includedModuleKeys,
  }) async {
    final dynamic data = await _post(_path('/platform-admin/subscription-plans'), <String, dynamic>{
      'planKey': planKey,
      'displayName': displayName,
      'monthlyPriceInPaise': monthlyPriceInPaise,
      'annualPriceInPaise': annualPriceInPaise,
      'maxBranches': maxBranches,
      'maxStaff': maxStaff,
      'maxMonthlyOrders': maxMonthlyOrders,
      'trialDays': trialDays,
      if (includedModuleKeys != null) 'includedModuleKeys': includedModuleKeys,
    });
    return SubscriptionPlanModel.fromJson(data as Map<String, dynamic>);
  }

  Future<SubscriptionPlanModel> updateSubscriptionPlan(
    String planKey, {
    String? displayName,
    int? monthlyPriceInPaise,
    int? annualPriceInPaise,
    int? maxBranches,
    int? maxStaff,
    int? maxMonthlyOrders,
    int? trialDays,
    List<String>? includedModuleKeys,
    bool? isActive,
  }) async {
    final dynamic data = await _patch(
      _path('/platform-admin/subscription-plans/$planKey'),
      <String, dynamic>{
        if (displayName != null) 'displayName': displayName,
        if (monthlyPriceInPaise != null) 'monthlyPriceInPaise': monthlyPriceInPaise,
        if (annualPriceInPaise != null) 'annualPriceInPaise': annualPriceInPaise,
        if (maxBranches != null) 'maxBranches': maxBranches,
        if (maxStaff != null) 'maxStaff': maxStaff,
        if (maxMonthlyOrders != null) 'maxMonthlyOrders': maxMonthlyOrders,
        if (trialDays != null) 'trialDays': trialDays,
        if (includedModuleKeys != null) 'includedModuleKeys': includedModuleKeys,
        if (isActive != null) 'isActive': isActive,
      },
    );
    return SubscriptionPlanModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteSubscriptionPlan(String planKey) =>
      _delete(_path('/platform-admin/subscription-plans/$planKey'));

  Future<List<BillingAttemptModel>> getBillingHistory(String tenantId) async {
    final dynamic data = await _get(_path('/platform-admin/billing/tenants/$tenantId/history'));
    if (data is List) {
      return data
          .map((e) => BillingAttemptModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const <BillingAttemptModel>[];
  }

  Future<TenantSubscriptionModel?> getTenantSubscription(String tenantId) async {
    try {
      final dynamic data = await _get(
        _path('/platform-admin/tenant-subscriptions/$tenantId'),
      );
      return TenantSubscriptionModel.fromJson(data as Map<String, dynamic>);
    } on CompanyAdminApiException {
      return null; // no subscription assigned yet
    }
  }

  Future<List<SubscriptionHistoryModel>> getSubscriptionHistory(String tenantId) async {
    final dynamic data = await _get(
      _path('/platform-admin/tenant-subscriptions/$tenantId/history'),
    );
    if (data is List) {
      return data
          .map((e) => SubscriptionHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const <SubscriptionHistoryModel>[];
  }

  Future<TenantSubscriptionModel> assignPlan(
    String tenantId, {
    required String planKey,
    required String billingCycle,
  }) async {
    final dynamic data = await _post(
      _path('/platform-admin/tenant-subscriptions/$tenantId/assign-plan'),
      <String, dynamic>{'planKey': planKey, 'billingCycle': billingCycle},
    );
    return TenantSubscriptionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<TenantSubscriptionModel> updateSubscriptionStatus(
    String tenantId, {
    required String status,
    String? reason,
  }) async {
    final dynamic data = await _patch(
      _path('/platform-admin/tenant-subscriptions/$tenantId/status'),
      <String, dynamic>{'status': status, if (reason != null) 'reason': reason},
    );
    return TenantSubscriptionModel.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createBillingOrder(
    String tenantId, {
    String? billingCycle,
  }) async {
    final dynamic data = await _post(
      _path('/platform-admin/billing/tenants/$tenantId/create-order'),
      <String, dynamic>{if (billingCycle != null) 'billingCycle': billingCycle},
    );
    return data as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODULE MATRIX (Phase 5 controller addition)
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<ModuleMatrixEntryModel>> getModuleMatrix(String tenantId) async {
    final dynamic data = await _get(_path('/platform-admin/tenants/$tenantId/modules'));
    if (data is List) {
      return data
          .map((e) => ModuleMatrixEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }
    return const <ModuleMatrixEntryModel>[];
  }

  Future<ModuleMatrixEntryModel> setModule(
    String tenantId,
    String moduleKey, {
    required bool isEnabled,
  }) async {
    final dynamic data = await _put(
      _path('/platform-admin/tenants/$tenantId/modules/$moduleKey'),
      <String, dynamic>{'isEnabled': isEnabled},
    );
    return ModuleMatrixEntryModel.fromJson(data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // THEME (Phase 4)
  // ─────────────────────────────────────────────────────────────────────────
  Future<EffectiveTenantThemeModel> getTheme(String tenantId) async {
    final dynamic data = await _get(_path('/platform-admin/tenants/$tenantId/theme'));
    return EffectiveTenantThemeModel.fromJson(data as Map<String, dynamic>);
  }

  Future<EffectiveTenantThemeModel> setTheme(
    String tenantId, {
    String? primaryColorHex,
    String? secondaryColorHex,
    String? accentColorHex,
    bool? darkThemeEnabled,
    String? customAppTitle,
    String? logoUrl,
    String? bannerUrl,
  }) async {
    final dynamic data = await _put(_path('/platform-admin/tenants/$tenantId/theme'), <String, dynamic>{
      if (primaryColorHex != null) 'primaryColorHex': primaryColorHex,
      if (secondaryColorHex != null) 'secondaryColorHex': secondaryColorHex,
      if (accentColorHex != null) 'accentColorHex': accentColorHex,
      if (darkThemeEnabled != null) 'darkThemeEnabled': darkThemeEnabled,
      if (customAppTitle != null) 'customAppTitle': customAppTitle,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (bannerUrl != null) 'bannerUrl': bannerUrl,
    });
    return EffectiveTenantThemeModel.fromJson(data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HTTP HELPERS
  // ─────────────────────────────────────────────────────────────────────────
  Future<dynamic> _get(Uri uri) async {
    final Map<String, String> headers = await _headers();
    try {
      final http.Response response = await _client.get(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> _post(
    Uri uri,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final Map<String, String> headers = await _headers(requireAuth: requireAuth);
    try {
      final http.Response response = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> _put(Uri uri, Map<String, dynamic> body) async {
    final Map<String, String> headers = await _headers();
    try {
      final http.Response response = await _client
          .put(uri, headers: headers, body: jsonEncode(body))
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

  Future<Map<String, String>> _headers({bool requireAuth = true}) async {
    if (!requireAuth) {
      return <String, String>{
        HttpHeaders.acceptHeader: 'application/json',
        HttpHeaders.contentTypeHeader: 'application/json',
      };
    }
    final AdminSession? session = await _tokenStorage.read();
    if (session == null || session.accessToken.isEmpty) {
      throw const CompanyAdminApiException('Admin session is required.');
    }
    return <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
    };
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      if (response.body.isNotEmpty) {
        decoded = jsonDecode(response.body);
      }
    } catch (_) {
      throw const CompanyAdminApiException('Invalid response from Platform Admin Service.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    if (response.statusCode == 401) {
      throw const CompanyAdminApiException('Admin session expired. Please log in again.');
    }
    if (response.statusCode == 403) {
      throw const CompanyAdminApiException('This admin role cannot perform that action.');
    }
    if (response.statusCode == 404) {
      throw CompanyAdminApiException(_extractErrorMessage(decoded) ?? 'Not found.');
    }
    if (response.statusCode == 409) {
      throw CompanyAdminApiException(
        _extractErrorMessage(decoded) ?? 'This value is already in use.',
      );
    }

    final String message =
        _extractErrorMessage(decoded) ?? 'Request failed (${response.statusCode}).';
    throw CompanyAdminApiException(message);
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] is String) return decoded['message'] as String;
      if (decoded['message'] is List) {
        return (decoded['message'] as List).whereType<String>().join('\n');
      }
    }
    return null;
  }

  CompanyAdminApiException _handleError(Object error) {
    if (error is CompanyAdminApiException) return error;
    if (error is SocketException || error is http.ClientException) {
      return const CompanyAdminApiException(
        'Unable to reach the Company Admin service. Please check connection.',
      );
    }
    if (error is TimeoutException) {
      return const CompanyAdminApiException('Request timed out. Please try again.');
    }
    return CompanyAdminApiException(error.toString());
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

    return parsed.replace(pathSegments: segments);
  }

  static String _environment(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final String? value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}
