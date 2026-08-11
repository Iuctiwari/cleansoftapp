import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/tenant/models/registration_form.dart';
import 'package:nexoraa_mobile/features/tenant/models/tenant_onboarding_data.dart';
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

  test('registration form JSON round-trip preserves route state', () {
    final restored = RegistrationForm.fromJson(form.toJson());

    expect(restored.businessName, form.businessName);
    expect(restored.businessType, form.businessType);
    expect(restored.ownerName, form.ownerName);
    expect(restored.email, form.email);
    expect(restored.mobileNumber, form.mobileNumber);
    expect(restored.password, form.password);
    expect(restored.agreedToTerms, isTrue);
  });

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

  test('duplicate email uses the backend conflict code', () async {
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

    try {
      await service.registerTenant(form);
      fail('Expected duplicate email conflict');
    } on TenantApiException catch (error) {
      expect(error.statusCode, 409);
      expect(error.userMessage, 'Email is already registered');
    }
  });

  test('duplicate mobile uses the backend conflict code', () async {
    final service = TenantApiService(
      baseUrl: 'http://test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object>{
            'error': <String, Object>{
              'code': 'tenant.mobile_number_already_registered',
              'messageKey': 'errors.tenant.mobile_number_already_registered',
              'category': 'conflict',
              'fields': <Map<String, String>>[
                <String, String>{
                  'field': 'mobileNumber',
                  'code': 'tenant.mobile_number_already_registered',
                },
              ],
            },
          }),
          409,
        ),
      ),
    );

    try {
      await service.registerTenant(form);
      fail('Expected duplicate mobile conflict');
    } on TenantApiException catch (error) {
      expect(error.userMessage, 'Mobile number is already registered');
    }
  });

  test('400 displays the backend validation message', () async {
    final service = TenantApiService(
      baseUrl: 'http://test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object>{
            'statusCode': 400,
            'message': <String>['mobileNumber must be a valid phone number'],
            'error': 'Bad Request',
          }),
          400,
        ),
      ),
    );

    try {
      await service.registerTenant(form);
      fail('Expected validation failure');
    } on TenantApiException catch (error) {
      expect(error.userMessage, 'mobileNumber must be a valid phone number');
    }
  });

  test('409 displays the backend conflict message', () async {
    final service = TenantApiService(
      baseUrl: 'http://test',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object>{
            'error': <String, Object>{
              'code': 'tenant.conflict',
              'messageKey': 'errors.tenant.conflict',
              'category': 'conflict',
              'message':
                  'The supplied account conflicts with an existing account',
            },
          }),
          409,
        ),
      ),
    );

    try {
      await service.registerTenant(form);
      fail('Expected conflict');
    } on TenantApiException catch (error) {
      expect(
        error.userMessage,
        'The supplied account conflicts with an existing account',
      );
    }
  });

  test(
    'onboarding sends mobile-only and email-only invitations once',
    () async {
      final data = TenantOnboardingData(
        registrationForm: form,
        tenantId: 'tenant-123',
        branchName: 'Pune Main',
        streetAddress: 'MG Road',
        city: 'Pune',
        postalCode: '411038',
        phone: '9850237396',
        email: 'branch@example.com',
        selectedServices: <String>{'laundry'},
        staff: <StaffInvitationData>[
          StaffInvitationData(mobileNumber: '+919876543211'),
          StaffInvitationData(email: 'staff@example.com'),
        ],
      );
      var requests = 0;
      final client = MockClient((request) async {
        requests += 1;
        expect(request.method, 'PATCH');
        expect(
          request.url.toString(),
          'http://10.0.2.2:3003/api/v1/tenants/tenant-123',
        );
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['staff'], <Map<String, String>>[
          <String, String>{'mobileNumber': '+919876543211'},
          <String, String>{'email': 'staff@example.com'},
        ]);
        return http.Response(
          jsonEncode(<String, String>{
            'tenantId': 'tenant-123',
            'message': 'Onboarding completed successfully',
          }),
          200,
        );
      });

      await TenantApiService(
        client: client,
        baseUrl: 'http://10.0.2.2:3003',
      ).completeOnboarding(data);

      expect(requests, 1);
    },
  );

  test('connection failures alone use the unavailable message', () async {
    final client = MockClient((_) async {
      throw http.ClientException('connection refused');
    });
    final service = TenantApiService(client: client, baseUrl: 'http://test');

    try {
      await service.registerTenant(form);
      fail('Expected network failure');
    } on TenantApiNetworkException catch (error) {
      expect(error.message, 'Tenant Service unavailable');
    }
  });
}
