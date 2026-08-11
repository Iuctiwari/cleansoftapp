import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/tenant/models/registration_form.dart';
import 'package:nexoraa_mobile/features/tenant/services/tenant_api_service.dart';

void main() {
  final form = RegistrationForm(
    businessName: 'FreshCare Laundry',
    businessType: 'laundry',
    ownerName: 'Priya Sharma',
    email: 'priya.sharma@example.com',
    mobileNumber: '+919876543210',
    password: 'Fresh@2026Pass',
    agreedToTerms: true,
  );

  test(
    'registration posts the existing contract and parses a 201 response',
    () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          'http://10.0.2.2:3003/api/v1/tenants/register',
        );
        expect(request.method, 'POST');
        expect(request.headers['content-type'], 'application/json');
        expect(jsonDecode(request.body), form.toJson());

        return http.Response(
          jsonEncode({
            'tenantId': 'tenant-123',
            'slug': 'freshcare-laundry',
            'ownerUserId': 'owner-123',
            'businessName': 'FreshCare Laundry',
            'message': 'Account created successfully',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = TenantApiService(
        client: client,
        baseUrl: 'http://10.0.2.2:3003',
      );
      final result = await service.registerTenant(form);

      expect(result.tenantId, 'tenant-123');
      expect(result.ownerUserId, 'owner-123');
      expect(result.slug, 'freshcare-laundry');
      expect(result.businessName, 'FreshCare Laundry');
    },
  );

  test('structured HTTP errors remain API errors', () async {
    final client = MockClient((_) async {
      return http.Response(
        jsonEncode({
          'error': {
            'code': 'tenant.email_already_registered',
            'messageKey': 'errors.tenant.email_already_registered',
            'category': 'conflict',
            'fields': [
              {'field': 'email', 'code': 'tenant.email_already_registered'},
            ],
          },
        }),
        409,
      );
    });

    final service = TenantApiService(client: client, baseUrl: 'http://test');

    await expectLater(
      service.registerTenant(form),
      throwsA(
        isA<TenantApiException>()
            .having((error) => error.statusCode, 'statusCode', 409)
            .having(
              (error) => error.code,
              'code',
              'tenant.email_already_registered',
            ),
      ),
    );
  });

  test('connection failures remain network errors', () async {
    final client = MockClient((_) async {
      throw http.ClientException('connection refused');
    });
    final service = TenantApiService(client: client, baseUrl: 'http://test');

    await expectLater(
      service.registerTenant(form),
      throwsA(isA<TenantApiNetworkException>()),
    );
  });
}
