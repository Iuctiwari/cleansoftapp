import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_session_storage.dart';

ConsumerSession _session({DateTime? accessExpiry}) => ConsumerSession(
  accessToken: 'access-1',
  refreshToken: 'refresh-1',
  accessTokenExpiresAt: accessExpiry ?? DateTime.now().toUtc().add(const Duration(hours: 1)),
  refreshTokenExpiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
  consumerId: 'consumer-1',
  displayName: 'Riya',
  email: 'riya@example.com',
  mobileNumber: '9876543210',
);

ConsumerApiService _service(MockClient client, ConsumerSessionStorage storage) => ConsumerApiService(
  authBaseUri: () => Uri.parse('http://auth.test/api'),
  marketplaceBaseUri: () => Uri.parse('http://market.test/api'),
  storage: storage,
  client: client,
);

void main() {
  group('ConsumerApiService', () {
    test('signs in with the consumer context and stores the session', () async {
      late Map<String, dynamic> sent;
      final MemoryConsumerSessionStorage storage = MemoryConsumerSessionStorage();
      final ConsumerApiService api = _service(
        MockClient((http.Request request) async {
          expect(request.url.toString(), 'http://auth.test/api/v1/auth/login');
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode(<String, Object>{
              'data': <String, Object>{
                'accessToken': 'a',
                'refreshToken': 'r',
                'accessTokenExpiresAtUtc': '2030-01-01T00:00:00.000Z',
                'refreshTokenExpiresAtUtc': '2030-01-08T00:00:00.000Z',
                'user': <String, String>{
                  'userId': 'consumer-9',
                  'displayName': 'Riya',
                  'email': 'riya@example.com',
                  'mobileNumber': '9876543210',
                },
              },
            }),
            201,
          );
        }),
        storage,
      );

      final ConsumerSession session = await api.signIn(identifier: ' 9876543210 ', password: 'Pw@12345');

      expect(sent, <String, String>{'context': 'consumer', 'identifier': '9876543210', 'password': 'Pw@12345'});
      expect(session.consumerId, 'consumer-9');
      expect(storage.session?.accessToken, 'a');
    });

    test('reports auth-service error codes (e.g. email not verified)', () async {
      final ConsumerApiService api = _service(
        MockClient(
          (_) async => http.Response(
            jsonEncode(<String, Object>{
              'error': <String, Object>{'code': 'auth.email_not_verified', 'category': 'forbidden'},
            }),
            403,
          ),
        ),
        MemoryConsumerSessionStorage(),
      );

      expect(
        () => api.signIn(identifier: 'riya@example.com', password: 'x'),
        throwsA(isA<ConsumerApiException>().having((e) => e.code, 'code', 'auth.email_not_verified')),
      );
    });

    test('keeps marketplace-service sentences as the message', () async {
      final MemoryConsumerSessionStorage storage = MemoryConsumerSessionStorage()..session = _session();
      final ConsumerApiService api = _service(
        MockClient(
          (_) async => http.Response(
            jsonEncode(<String, String>{
              'code': 'HTTP_ERROR_400',
              'message': 'This shop serves up to 3 km away; your address is 6.9 km away',
            }),
            400,
          ),
        ),
        storage,
      );

      expect(
        () => api.createRequest(
          const ServiceRequestDraft(
            shopId: 's',
            category: ShopCategory.laundry,
            requestType: ServiceMode.pickupDrop,
            description: 'Pickup curtains',
            preferredDate: '2030-01-02',
            slotStart: '10:00',
            slotEnd: '12:00',
          ),
        ),
        throwsA(isA<ConsumerApiException>().having((e) => e.message, 'message', contains('3 km'))),
      );
    });

    test('sends the bearer token and search filters; reads the plain marketplace JSON', () async {
      final MemoryConsumerSessionStorage storage = MemoryConsumerSessionStorage()..session = _session();
      late Uri uri;
      late String? auth;
      final ConsumerApiService api = _service(
        MockClient((http.Request request) async {
          uri = request.url;
          auth = request.headers['authorization'];
          return http.Response(
            jsonEncode(<String, Object>{
              'items': <Object>[
                <String, Object>{
                  'shopId': 'b1',
                  'shopName': 'Sparkle',
                  'branchName': 'Head Office',
                  'categories': <String>['laundry', 'unknown_future_type'],
                  'distanceKm': 2.6,
                  'city': 'Mumbai',
                  'addressLine': 'Shop 4',
                  'phone': '9123456789',
                  'serviceModes': <String>['visit_shop', 'pickup_drop'],
                  'servesYourLocation': true,
                  'isOpenNow': true,
                  'latitude': 19.1,
                  'longitude': 72.8,
                },
              ],
              'page': 1,
              'limit': 20,
              'total': 1,
              'origin': <String, Object>{'latitude': 19.1, 'longitude': 72.8, 'addressId': 'a1'},
              'radiusKm': 5,
            }),
            200,
          );
        }),
        storage,
      );

      final ShopSearchPage page = await api.searchShops(
        const ShopSearchFilters(addressId: 'a1', category: ShopCategory.laundry, openNow: true, radiusKm: 5),
      );

      expect(auth, 'Bearer access-1');
      expect(uri.path, '/api/v1/marketplace/shops');
      expect(uri.queryParameters, <String, String>{
        'addressId': 'a1',
        'category': 'laundry',
        'openNow': 'true',
        'radiusKm': '5',
        'page': '1',
        'limit': '20',
      });
      expect(page.items.single.categories, <ShopCategory>[ShopCategory.laundry]);
      expect(page.items.single.serviceModes, <ServiceMode>[ServiceMode.visitShop, ServiceMode.pickupDrop]);
      expect(page.total, 1);
    });

    test('current-location search sends GPS instead of the saved address', () {
      const ShopSearchFilters filters = ShopSearchFilters(addressId: 'a1');
      final ShopSearchFilters gps = filters.copyWith(latitude: 19.2, longitude: 72.9, clearLocation: true);
      expect(gps.toQuery().containsKey('addressId'), isFalse);
      expect(gps.toQuery()['latitude'], '19.2');
    });

    test('a 401 clears the stored session so the app returns to sign-in', () async {
      final MemoryConsumerSessionStorage storage = MemoryConsumerSessionStorage()..session = _session();
      final ConsumerApiService api = _service(
        MockClient((_) async => http.Response('{"message":"Invalid or expired access token"}', 401)),
        storage,
      );

      await expectLater(
        api.listAddresses(),
        throwsA(isA<ConsumerApiException>().having((e) => e.isSessionExpired, 'expired', isTrue)),
      );
      expect(storage.session, isNull);
    });
  });

  group('SecureConsumerSessionStorage refresh', () {
    test('refreshes an expiring access token with the v1 refresh endpoint', () async {
      late Uri refreshUri;
      final MockClient client = MockClient((http.Request request) async {
        refreshUri = request.url;
        expect(jsonDecode(request.body), <String, String>{'refreshToken': 'refresh-1'});
        return http.Response(
          jsonEncode(<String, Object>{
            'data': <String, String>{
              'accessToken': 'access-2',
              'refreshToken': 'refresh-2',
              'accessTokenExpiresAtUtc': '2030-01-01T00:00:00.000Z',
              'refreshTokenExpiresAtUtc': '2030-01-08T00:00:00.000Z',
            },
          }),
          200,
        );
      });
      final _FakeSecureStorage storage = _FakeSecureStorage(
        client: client,
        initial: _session(accessExpiry: DateTime.now().toUtc().add(const Duration(seconds: 5))),
      );

      final ConsumerSession? session = await storage.read();

      expect(refreshUri.toString(), 'http://auth.test/api/v1/auth/refresh');
      expect(session?.accessToken, 'access-2');
      expect(session?.consumerId, 'consumer-1');
    });
  });
}

/// SecureConsumerSessionStorage backed by flutter_secure_storage's in-memory mock.
class _FakeSecureStorage implements ConsumerSessionStorage {
  _FakeSecureStorage({required http.Client client, required ConsumerSession initial})
    : _inner = SecureConsumerSessionStorage(
        authBaseUri: () => Uri.parse('http://auth.test/api'),
        client: client,
      ) {
    FlutterSecureStorage.setMockInitialValues(<String, String>{
      'consumer.session': jsonEncode(initial.toStorage()),
    });
  }

  final SecureConsumerSessionStorage _inner;

  @override
  Future<void> clear() => _inner.clear();

  @override
  Future<ConsumerSession?> read() => _inner.read();

  @override
  Future<void> write(ConsumerSession session) => _inner.write(session);
}
