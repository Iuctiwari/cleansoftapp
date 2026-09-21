import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/subscription/models/subscription_models.dart';

/// Talks to platform-admin-service's tenant-facing subscription endpoints
/// (GET/POST /tenant/subscription/*) — the tenant-side counterpart of the
/// Company Admin panel's subscription screens, reusing the exact same
/// assignment/billing logic server-side. Uses the EXISTING tenant/staff
/// AuthTokenStorage, same as TenantConfigClient — never CompanyAdminTokenStorage.
class SubscriptionApiService {
  SubscriptionApiService({AuthTokenStorage? tokenStorage, http.Client? client, String? baseUrl})
    : _tokenStorage = tokenStorage ?? AuthenticationDependencies.tokenStorage,
      _client = client ?? http.Client(),
      _baseUri = _buildBaseUri(
        baseUrl ??
            BackendEnvironment.resolveBase(
              _environment('PLATFORM_ADMIN_API_BASE_URL', 'http://10.0.2.2:3015/api'),
              'RENDER_PLATFORM_ADMIN_API_BASE_URL',
            ),
      );

  static const Duration _timeout = Duration(seconds: 15);

  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final Uri _baseUri;

  Future<List<TenantPlan>> listPlans() async {
    final dynamic body = await _send('GET', 'tenant/subscription/plans');
    if (body is! List) return const <TenantPlan>[];
    return body
        .whereType<Map<String, dynamic>>()
        .map(TenantPlan.fromJson)
        .toList(growable: false);
  }

  Future<TenantSubscriptionStatus> getStatus() async {
    final dynamic body = await _send('GET', 'tenant/subscription/status');
    return TenantSubscriptionStatus.fromJson(body as Map<String, dynamic>);
  }

  /// Assigns/changes the tenant's plan — never itself triggers billing.
  /// Used both by onboarding (any plan) and for switching to a free plan.
  Future<TenantSubscriptionStatus> selectPlan({
    required String planKey,
    required String billingCycle,
  }) async {
    final dynamic body = await _send(
      'POST',
      'tenant/subscription/select-plan',
      payload: <String, dynamic>{'planKey': planKey, 'billingCycle': billingCycle},
    );
    return TenantSubscriptionStatus.fromJson(body as Map<String, dynamic>);
  }

  /// Creates a Razorpay order for the CURRENTLY assigned plan/cycle — call
  /// [selectPlan] first when switching to a different paid plan.
  Future<TenantBillingOrder> createOrder({String? billingCycle}) async {
    final dynamic body = await _send(
      'POST',
      'tenant/subscription/create-order',
      payload: <String, dynamic>{if (billingCycle != null) 'billingCycle': billingCycle},
    );
    return TenantBillingOrder.fromJson(body as Map<String, dynamic>);
  }

  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? payload}) async {
    final AuthenticationSession? session = await _tokenStorage.read();
    if (session == null || session.accessToken.isEmpty) {
      throw const SubscriptionApiException('Your session has expired. Please sign in again.');
    }

    final Uri uri = _baseUri.replace(path: '${_baseUri.path}/$path');
    final Map<String, String> headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
      if (session.branchId != null && session.branchId!.isNotEmpty)
        'x-branch-id': session.branchId!,
      if (payload != null) HttpHeaders.contentTypeHeader: 'application/json',
    };

    http.Response response;
    try {
      response = method == 'POST'
          ? await _client
                .post(uri, headers: headers, body: jsonEncode(payload ?? <String, dynamic>{}))
                .timeout(_timeout)
          : await _client.get(uri, headers: headers).timeout(_timeout);
    } catch (_) {
      throw const SubscriptionApiException(
        'Unable to reach the subscription service. Please try again.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SubscriptionApiException(_errorMessage(response));
    }
    if (response.body.isEmpty) return null;

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) return decoded['data'];
    return decoded;
  }

  String _errorMessage(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final dynamic message = decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) return message;
        if (message is Map<String, dynamic> && message['message'] is String) {
          return message['message'] as String;
        }
      }
    } catch (_) {
      // Fall through to the generic message below.
    }
    return 'Something went wrong. Please try again.';
  }

  static Uri _buildBaseUri(String rawUrl) {
    final Uri parsed = Uri.parse(rawUrl.trim());
    final List<String> segments = parsed.pathSegments.where((s) => s.isNotEmpty).toList();
    if (!segments.contains('api')) segments.add('api');
    if (!segments.contains('v1')) segments.add('v1');
    return parsed.replace(pathSegments: segments);
  }

  static String _environment(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final String? value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}
