import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Whose phone it is: a shop user or a marketplace customer.
enum PushAccount { shop, consumer }

/// Tells the server which phone belongs to the signed-in person, so pushes
/// reach it. Best effort — a failure just means no pushes until the next try.
class PushApi {
  PushApi({
    required Uri Function() baseUri,
    required Future<String?> Function(PushAccount account) authorization,
    required String? Function() shopBranchId,
    http.Client? client,
  }) : _baseUri = baseUri,
       _authorization = authorization,
       _shopBranchId = shopBranchId,
       _client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 8);

  final Uri Function() _baseUri;
  final Future<String?> Function(PushAccount account) _authorization;
  final String? Function() _shopBranchId;
  final http.Client _client;

  /// Returns true when the server stored the phone.
  Future<bool> register(PushAccount account, String token) =>
      _post(account, '', <String, Object>{'token': token, 'platform': 'android'});

  Future<bool> unregister(PushAccount account, String token) =>
      _post(account, '/unregister', <String, Object>{'token': token});

  Future<bool> _post(PushAccount account, String suffix, Map<String, Object> body) async {
    final String? authorization = await _authorization(account);
    if (authorization == null) return false;
    final Uri base = _baseUri();
    final String prefix = base.path.replaceFirst(RegExp(r'/+$'), '');
    final String path = account == PushAccount.shop ? 'v1/push/devices' : 'v1/push/consumer/devices';
    final String? branchId = account == PushAccount.shop ? _shopBranchId() : null;
    try {
      final http.Response response = await _client
          .post(
            base.replace(path: '$prefix/$path$suffix'),
            headers: <String, String>{
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.authorizationHeader: authorization,
              if (branchId != null && branchId.isNotEmpty && branchId != 'unavailable') 'x-branch-id': branchId,
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } on Object {
      return false;
    }
  }
}
