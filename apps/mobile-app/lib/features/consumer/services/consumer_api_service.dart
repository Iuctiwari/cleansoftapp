import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_session_storage.dart';
import 'package:nexoraa_mobile/features/salon/models/salon_models.dart';

/// A failed customer API call. [code] is the backend error code when there is
/// one (e.g. `auth.email_not_verified`), else `http.<status>` or `network`;
/// screens turn it into a translated message, falling back to [message].
class ConsumerApiException implements Exception {
  const ConsumerApiException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  bool get isNetwork => code == 'network';
  bool get isSessionExpired => statusCode == HttpStatus.unauthorized && code != 'auth.login_denied';

  @override
  String toString() => message;
}

/// Everything the customer side of the app asks the backend.
class ConsumerApiService {
  ConsumerApiService({
    required Uri Function() authBaseUri,
    required Uri Function() marketplaceBaseUri,
    required ConsumerSessionStorage storage,
    http.Client? client,
  }) : _authBaseUri = authBaseUri,
       _marketplaceBaseUri = marketplaceBaseUri,
       _storage = storage,
       _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 20);

  final Uri Function() _authBaseUri;
  final Uri Function() _marketplaceBaseUri;
  final ConsumerSessionStorage _storage;
  final http.Client _client;

  // ── Account ───────────────────────────────────────────────────────────────

  /// Creates the account and emails a 6-digit code. Returns where it was sent.
  Future<String> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    final Map<String, dynamic> data = _map(
      await _send(
        'POST',
        _auth('v1/auth/consumer/register'),
        body: <String, Object>{
          'fullName': fullName.trim(),
          'email': email.trim(),
          'mobileNumber': mobileNumber.trim(),
          'password': password,
        },
        authenticated: false,
      ),
    );
    return data['deliveryHint'] as String? ?? '';
  }

  Future<void> verifyEmail({required String email, required String otp}) async {
    await _send(
      'POST',
      _auth('v1/auth/consumer/verify-email'),
      body: <String, Object>{'email': email.trim(), 'otp': otp.trim()},
      authenticated: false,
    );
  }

  /// Verifies the account with the proof of the phone number from Firebase instead of the email code.
  Future<void> verifyPhone({required String email, required String idToken}) async {
    await _send(
      'POST',
      _auth('v1/auth/consumer/verify-phone'),
      body: <String, Object>{'email': email.trim(), 'idToken': idToken},
      authenticated: false,
    );
  }

  /// Sends a new code; returns how many seconds until another may be sent.
  Future<int> resendVerification({required String email}) async {
    final Map<String, dynamic> data = _map(
      await _send(
        'POST',
        _auth('v1/auth/consumer/resend-verification'),
        body: <String, Object>{'email': email.trim()},
        authenticated: false,
      ),
    );
    return (data['resendAvailableInSeconds'] as num?)?.toInt() ?? 60;
  }

  /// Signs in with email or mobile number and stores the session.
  Future<ConsumerSession> signIn({required String identifier, required String password}) async {
    final Map<String, dynamic> data = _map(
      await _send(
        'POST',
        _auth('v1/auth/login'),
        body: <String, Object>{
          'context': 'consumer',
          'identifier': identifier.trim(),
          'password': password,
        },
        authenticated: false,
      ),
    );
    final Map<String, dynamic> user = _map(data['user']);
    final ConsumerSession session = ConsumerSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      accessTokenExpiresAt: DateTime.parse(data['accessTokenExpiresAtUtc'] as String).toUtc(),
      refreshTokenExpiresAt: DateTime.parse(data['refreshTokenExpiresAtUtc'] as String).toUtc(),
      consumerId: user['userId'] as String,
      displayName: user['displayName'] as String? ?? '',
      email: user['email'] as String? ?? '',
      mobileNumber: user['mobileNumber'] as String? ?? '',
    );
    await _storage.write(session);
    return session;
  }

  Future<void> signOut() async {
    final ConsumerSession? session = await _storage.read();
    if (session != null) {
      try {
        await _send('POST', _auth('v1/auth/logout'));
      } on ConsumerApiException {
        // Signing out locally is what matters.
      }
    }
    await _storage.clear();
  }

  Future<void> requestPasswordReset({required String identifier}) async {
    await _send(
      'POST',
      _auth('v1/auth/forgot-password'),
      body: <String, Object>{'context': 'consumer', 'identifier': identifier.trim()},
      authenticated: false,
    );
  }

  Future<void> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    await _send(
      'POST',
      _auth('v1/auth/reset-password'),
      body: <String, Object>{
        'context': 'consumer',
        'identifier': identifier.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      },
      authenticated: false,
    );
  }

  // ── Addresses ─────────────────────────────────────────────────────────────

  Future<List<ConsumerAddress>> listAddresses() async =>
      _list(await _send('GET', _market('v1/consumer/addresses'))).map(ConsumerAddress.fromJson).toList();

  Future<ConsumerAddress> createAddress(AddressDraft draft) async => ConsumerAddress.fromJson(
    _map(await _send('POST', _market('v1/consumer/addresses'), body: draft.toJson())),
  );

  Future<ConsumerAddress> updateAddress(String addressId, AddressDraft draft) async =>
      ConsumerAddress.fromJson(
        _map(await _send('PATCH', _market('v1/consumer/addresses/$addressId'), body: draft.toJson())),
      );

  Future<void> setDefaultAddress(String addressId) async {
    await _send('POST', _market('v1/consumer/addresses/$addressId/default'));
  }

  Future<void> deleteAddress(String addressId) async {
    await _send('DELETE', _market('v1/consumer/addresses/$addressId'));
  }

  // ── Shops ─────────────────────────────────────────────────────────────────

  Future<ShopSearchPage> searchShops(ShopSearchFilters filters, {int page = 1}) async =>
      ShopSearchPage.fromJson(
        _map(await _send('GET', _market('v1/marketplace/shops', filters.toQuery(page: page)))),
      );

  Future<ShopDetail> shopDetail(String shopId, {ShopSearchFilters? origin}) async {
    final Map<String, String> query = <String, String>{
      if (origin != null && origin.usesCurrentLocation) ...<String, String>{
        'latitude': '${origin.latitude}',
        'longitude': '${origin.longitude}',
      } else if (origin?.addressId != null)
        'addressId': origin!.addressId!,
    };
    return ShopDetail.fromJson(
      _map(await _send('GET', _market('v1/marketplace/shops/$shopId', query))),
    );
  }

  // ── Salon booking ─────────────────────────────────────────────────────────

  Future<SalonMenu> salonMenu(String shopId) async =>
      SalonMenu.fromJson(_map(await _send('GET', _market('v1/marketplace/salons/$shopId/menu'))));

  /// Slots for a date, worked out for the chosen menu services.
  Future<SalonSlots> salonSlots(String shopId, String date, List<String> serviceIds) async =>
      SalonSlots.fromJson(
        _map(
          await _send(
            'GET',
            _market('v1/marketplace/salons/$shopId/slots', <String, String>{
              'date': date,
              if (serviceIds.isNotEmpty) 'serviceIds': serviceIds.join(','),
            }),
          ),
        ),
      );

  // ── Requests ──────────────────────────────────────────────────────────────

  Future<ServiceRequest> createRequest(ServiceRequestDraft draft) async =>
      ServiceRequest.fromJson(
        _map(await _send('POST', _market('v1/consumer/requests'), body: draft.toJson())),
      );

  Future<ServiceRequestPage> listRequests({RequestStatus? status, int page = 1}) async =>
      ServiceRequestPage.fromJson(
        _map(
          await _send(
            'GET',
            _market('v1/consumer/requests', <String, String>{
              if (status != null) 'status': status.code,
              'page': '$page',
              'limit': '20',
            }),
          ),
        ),
      );

  Future<ServiceRequest> getRequest(String requestId) async =>
      ServiceRequest.fromJson(_map(await _send('GET', _market('v1/consumer/requests/$requestId'))));

  Future<ServiceRequest> cancelRequest(String requestId, {String? reason}) async =>
      ServiceRequest.fromJson(
        _map(
          await _send(
            'POST',
            _market('v1/consumer/requests/$requestId/cancel'),
            body: <String, Object>{if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim()},
          ),
        ),
      );

  // ── plumbing ──────────────────────────────────────────────────────────────

  Uri _auth(String path) => _resolve(_authBaseUri(), path, null);

  Uri _market(String path, [Map<String, String>? query]) =>
      _resolve(_marketplaceBaseUri(), path, query);

  Uri _resolve(Uri base, String path, Map<String, String>? query) {
    final String prefix = base.path.endsWith('/') ? base.path : '${base.path}/';
    return base.replace(
      path: '$prefix$path',
      queryParameters: query == null || query.isEmpty ? null : query,
    );
  }

  Future<Object?> _send(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
    bool authenticated = true,
  }) async {
    String? token;
    if (authenticated) {
      final ConsumerSession? session = await _storage.read();
      if (session == null) {
        throw const ConsumerApiException(
          'session_expired',
          'Your session has expired. Please sign in again.',
          statusCode: HttpStatus.unauthorized,
        );
      }
      token = session.accessToken;
    }

    final http.Response response;
    try {
      final http.Request request = http.Request(method, uri)
        ..headers.addAll(<String, String>{
          HttpHeaders.acceptHeader: 'application/json',
          if (token != null) HttpHeaders.authorizationHeader: 'Bearer $token',
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

    final Object? decoded = _decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // auth-service wraps results in {data: …}; marketplace-service does not.
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('data') &&
          decoded.keys.every((String key) => key == 'data' || key == 'meta')) {
        return decoded['data'];
      }
      return decoded;
    }

    if (response.statusCode == HttpStatus.unauthorized && authenticated) {
      await _storage.clear();
    }
    throw _error(decoded, response.statusCode);
  }

  ConsumerApiException _error(Object? decoded, int statusCode) {
    String code = 'http.$statusCode';
    String? message;
    if (decoded is Map<String, dynamic>) {
      final Object? error = decoded['error'];
      if (error is Map<String, dynamic>) {
        // auth-service: {error: {code, messageKey, fields}}
        code = error['code'] as String? ?? code;
      }
      // marketplace-service: {code: HTTP_ERROR_409, message: "…"}
      final Object? raw = decoded['message'];
      if (raw is String && raw.trim().isNotEmpty) message = raw.trim();
      if (raw is List) {
        final List<String> parts = raw.whereType<String>().toList();
        if (parts.isNotEmpty) message = parts.join('\n');
      }
      final Object? details = decoded['details'];
      if (details is Map<String, dynamic> && details['errors'] is List) {
        final List<String> parts = (details['errors'] as List).whereType<String>().toList();
        if (parts.isNotEmpty) message = parts.join('\n');
      }
    }
    return ConsumerApiException(
      code,
      message ?? 'Something went wrong. Please try again.',
      statusCode: statusCode,
    );
  }

  Object? _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const <String, dynamic>{};

  List<Map<String, dynamic>> _list(Object? value) =>
      value is List ? value.whereType<Map<String, dynamic>>().toList() : const <Map<String, dynamic>>[];
}
