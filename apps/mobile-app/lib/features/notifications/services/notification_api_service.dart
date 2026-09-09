import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/notifications/models/notification.dart';

class NotificationApiException implements Exception {
  const NotificationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class NotificationApiService {
  NotificationApiService({
    required AuthTokenStorage tokenStorage,
    http.Client? client,
    String? baseUrl,
  }) : _tokenStorage = tokenStorage,
       _client = client ?? http.Client(),
       _baseUri = _apiV1Uri(
         baseUrl ??
             BackendEnvironment.resolveBase(
               _environment(
                 'NOTIFICATION_API_BASE_URL',
                 'http://10.0.2.2:3015/api',
               ),
             ),
       );

  static const Duration _timeout = Duration(seconds: 20);
  static const int defaultPageSize = 20;

  final AuthTokenStorage _tokenStorage;
  final http.Client _client;
  final Uri _baseUri;
  String? _branchId;

  /// Bare host (no path), for the WebSocket connection to the same service.
  Uri get socketUri =>
      Uri(scheme: _baseUri.scheme, host: _baseUri.host, port: _baseUri.port);

  void selectBranch(String? branchId) {
    final String value = branchId?.trim() ?? '';
    _branchId = value.isEmpty || value == 'unavailable' ? null : value;
  }

  Future<String?> currentAuthorizationHeader() async {
    final session = await _tokenStorage.read();
    return session == null ? null : 'Bearer ${session.accessToken}';
  }

  String? get currentBranchId => _branchId;

  Future<AppNotificationPage> list({
    int page = 1,
    int limit = defaultPageSize,
    bool? isRead,
    AppNotificationType? type,
    String sortDirection = 'desc',
  }) async {
    final Uri uri = _notificationsUri().replace(
      queryParameters: <String, String>{
        'page': '$page',
        'limit': '$limit',
        if (isRead != null) 'isRead': '$isRead',
        if (type != null) 'type': type.apiValue,
        'sortDirection': sortDirection,
      },
    );
    try {
      return AppNotificationPage.fromJson(_map(_unwrap(await _get(uri))));
    } on NotificationApiException {
      rethrow;
    } on FormatException {
      throw const NotificationApiException(
        'Notification Service returned an invalid response.',
      );
    }
  }

  Future<int> unreadCount() async {
    try {
      final Map<String, dynamic> body = _map(
        _unwrap(await _get(_notificationsUri().resolve('unread-count'))),
      );
      final Object? count = body['count'];
      if (count is! num) {
        throw const FormatException('Missing count.');
      }
      return count.toInt();
    } on NotificationApiException {
      rethrow;
    } on FormatException {
      throw const NotificationApiException(
        'Notification Service returned an invalid response.',
      );
    }
  }

  Future<AppNotification> markRead(String id) async {
    try {
      return AppNotification.fromJson(
        _map(
          _unwrap(
            await _request(
              'PATCH',
              _notificationsUri().resolve('${Uri.encodeComponent(id)}/read'),
            ),
          ),
        ),
      );
    } on NotificationApiException {
      rethrow;
    } on FormatException {
      throw const NotificationApiException(
        'Notification Service returned an invalid response.',
      );
    }
  }

  Future<int> markAllRead() async {
    try {
      final Map<String, dynamic> body = _map(
        _unwrap(
          await _request(
            'PATCH',
            _notificationsUri().resolve('read-all'),
          ),
        ),
      );
      final Object? modified = body['modifiedCount'];
      return modified is num ? modified.toInt() : 0;
    } on NotificationApiException {
      rethrow;
    } on FormatException {
      throw const NotificationApiException(
        'Notification Service returned an invalid response.',
      );
    }
  }

  Uri _notificationsUri() => _baseUri.resolve('notifications/');

  Future<Object?> _get(Uri uri) => _request('GET', uri);

  Future<Object?> _request(
    String method,
    Uri uri, {
    Map<String, Object?>? body,
  }) async {
    final session = await _tokenStorage.read();
    if (session == null) {
      throw const NotificationApiException('Please sign in again.');
    }
    if (_branchId == null) {
      throw const NotificationApiException(
        'Select an active branch to view notifications.',
      );
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
        throw NotificationApiException(
          _errorMessage(decoded, response.statusCode),
        );
      }
      return decoded;
    } on NotificationApiException {
      rethrow;
    } on TimeoutException {
      throw const NotificationApiException(
        'The request timed out. Please try again.',
      );
    } on SocketException {
      throw const NotificationApiException(
        'Unable to reach Notification Service.',
      );
    } on http.ClientException {
      throw const NotificationApiException(
        'Unable to reach Notification Service.',
      );
    } on FormatException {
      throw const NotificationApiException(
        'Notification Service returned an invalid response.',
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
    throw const NotificationApiException(
      'Notification Service returned an invalid response.',
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
      400 => 'The notification request is invalid.',
      401 => 'Please sign in again.',
      403 => 'You do not have access to these notifications.',
      404 => 'Notification not found.',
      _ => 'Unable to load notifications. Please try again.',
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
