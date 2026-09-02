import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/reports/models/report_data.dart';
import 'package:nexoraa_mobile/features/reports/services/report_api_service.dart';

void main() {
  test(
    'maps all Phase 2 endpoints with bearer token, branch, and period',
    () async {
      final List<http.Request> requests = <http.Request>[];
      final ReportApiService service = ReportApiService(
        tokenStorage: _MemoryTokenStorage(_session),
        baseUrl: 'http://report.test/api',
        client: MockClient((http.Request request) async {
          requests.add(request);
          final String resource = request.url.pathSegments.last;
          return http.Response(jsonEncode(_response(resource)), 200);
        }),
      )..selectBranch('branch-a');
      const ReportQuery query = ReportQuery.period(ReportPeriod.thirtyDays);

      final List<Object> reports = await Future.wait<Object>(<Future<Object>>[
        service.loadSummary(query),
        service.loadOrders(query),
        service.loadPayments(query),
        service.loadExpenses(query),
      ]);

      expect(requests, hasLength(4));
      expect(
        requests.map((http.Request request) => request.url.path).toSet(),
        <String>{
          '/api/v1/reports/summary',
          '/api/v1/reports/orders',
          '/api/v1/reports/payments',
          '/api/v1/reports/expenses',
        },
      );
      for (final http.Request request in requests) {
        expect(request.url.queryParameters, <String, String>{'period': '30d'});
        expect(request.headers['authorization'], 'Bearer report-token');
        expect(request.headers['x-branch-id'], 'branch-a');
        expect(request.headers.containsKey('x-tenant-id'), isFalse);
      }
      expect((reports[0] as ReportSummary).totalRevenue, 10000);
      expect((reports[1] as OrderReport).metrics.completedOrders, 4);
      expect((reports[2] as PaymentReport).metrics.pendingAmountMinor, 4000);
      expect(
        (reports[3] as ExpenseReport)
            .metrics
            .categoryBreakdown
            .single
            .categoryName,
        'Utilities',
      );
    },
  );

  test(
    'sends custom UTC boundaries and rejects a missing branch before HTTP',
    () async {
      var requestCount = 0;
      final ReportApiService service = ReportApiService(
        tokenStorage: _MemoryTokenStorage(_session),
        baseUrl: 'http://report.test',
        client: MockClient((http.Request request) async {
          requestCount++;
          expect(request.url.queryParameters, <String, String>{
            'startDate': '2026-08-01T00:00:00.000Z',
            'endDate': '2026-08-08T23:59:59.000Z',
          });
          return http.Response(jsonEncode(_summary), 200);
        }),
      );
      final ReportQuery query = ReportQuery.custom(
        startDate: DateTime.utc(2026, 8),
        endDate: DateTime.utc(2026, 8, 8, 23, 59, 59),
      );

      await expectLater(
        service.loadSummary(query),
        throwsA(
          isA<ReportApiException>().having(
            (ReportApiException error) => error.message,
            'message',
            contains('active branch'),
          ),
        ),
      );
      expect(requestCount, 0);

      service.selectBranch('branch-b');
      await service.loadSummary(query);
      expect(requestCount, 1);
    },
  );

  test(
    'maps all tenant branches from one branch-performance request',
    () async {
      var requestCount = 0;
      final ReportApiService service = ReportApiService(
        tokenStorage: _MemoryTokenStorage(_session),
        baseUrl: 'http://report.test/api',
        client: MockClient((http.Request request) async {
          requestCount++;
          expect(request.url.path, '/api/v1/reports/branch-performance');
          expect(request.url.queryParameters, <String, String>{'period': '7d'});
          expect(request.headers['x-branch-id'], 'branch-a');
          return http.Response(
            jsonEncode(_response('branch-performance')),
            200,
          );
        }),
      )..selectBranch('branch-a');

      final BranchPerformanceReport report = await service
          .loadBranchPerformance(
            const ReportQuery.period(ReportPeriod.sevenDays),
          );

      expect(requestCount, 1);
      expect(report.branches, hasLength(2));
      expect(report.branches.first.branchName, 'Main Branch');
      expect(report.branches.first.metrics.revenue, 13200);
      expect(report.branches.first.metrics.revenueSharePercentage, 72);
      expect(report.branches.last.metrics.orders, 6);
    },
  );
}

final AuthenticationSession _session = AuthenticationSession(
  accessToken: 'report-token',
  refreshToken: 'refresh-token',
  accessTokenExpiresAt: DateTime.utc(2027),
  refreshTokenExpiresAt: DateTime.utc(2028),
  roleCode: 'tenant_owner',
  tenantId: 'tenant-from-session',
);

Map<String, Object?> _response(String resource) => switch (resource) {
  'branch-performance' => <String, Object?>{
    'branches': <Object?>[
      <String, Object?>{
        'branchCode': 'MAIN',
        'branchId': 'branch-a',
        'branchName': 'Main Branch',
        'metrics': <String, Object?>{
          'collected': 12000,
          'expenses': 3200,
          'netProfit': 10000,
          'orders': 18,
          'outstanding': 1200,
          'revenue': 13200,
          'revenueSharePercentage': 72,
        },
      },
      <String, Object?>{
        'branchId': 'branch-b',
        'branchName': 'Branch 2',
        'metrics': <String, Object?>{
          'collected': 4800,
          'expenses': 900,
          'netProfit': 4350,
          'orders': 6,
          'outstanding': 450,
          'revenue': 5250,
          'revenueSharePercentage': 28,
        },
      },
    ],
  },
  'summary' => _summary,
  'orders' => <String, Object?>{
    'items': <Object?>[],
    'limit': 20,
    'page': 1,
    'total': 10,
    'totalPages': 1,
    'metrics': <String, Object?>{
      'cancelledOrders': 3,
      'completedOrders': 4,
      'pendingOrders': 3,
      'statusBreakdown': <String, int>{
        'Delivered': 4,
        'InProgress': 3,
        'Cancelled': 3,
      },
      'totalOrderValue': 670,
      'totalOrders': 10,
      'totalOutstandingAmount': 110,
      'trend': <Object?>[],
    },
  },
  'payments' => <String, Object?>{
    'items': <Object?>[],
    'limit': 20,
    'page': 1,
    'total': 8,
    'totalPages': 1,
    'metrics': <String, Object?>{
      'collectedAmountMinor': 25000,
      'failedAmountMinor': 1000,
      'paymentCount': 8,
      'pendingAmountMinor': 4000,
      'statusBreakdown': <String, int>{
        'Successful': 5,
        'Pending': 2,
        'Failed': 1,
      },
      'totalPaymentAmountMinor': 30000,
      'trend': <Object?>[],
    },
  },
  'expenses' => <String, Object?>{
    'items': <Object?>[],
    'limit': 20,
    'page': 1,
    'total': 3,
    'totalPages': 1,
    'metrics': <String, Object?>{
      'categoryBreakdown': <Object?>[
        <String, Object?>{
          'amount': 1200,
          'categoryId': 'category-1',
          'categoryName': 'Utilities',
          'count': 3,
        },
      ],
      'expenseCount': 3,
      'totalExpenses': 1200,
      'trend': <Object?>[],
    },
  },
  _ => throw StateError('Unexpected report resource $resource'),
};

const Map<String, Object?> _summary = <String, Object?>{
  'collected': 9400,
  'collectionRate': 94,
  'netProfit': 7500,
  'orderChange': 2,
  'serviceBreakdown': <Object?>[
    <String, Object?>{'name': 'Wash & Fold', 'percentage': 75},
  ],
  'totalOrders': 12,
  'totalRevenue': 10000,
  'revenueChange': 25,
  'trend': <Object?>[
    <String, Object?>{'label': 'Mon', 'orders': 12, 'revenue': 10000},
  ],
};

class _MemoryTokenStorage implements AuthTokenStorage {
  _MemoryTokenStorage(this.session);

  AuthenticationSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<AuthenticationSession?> read() async => session;

  @override
  Future<void> write(AuthenticationSession session) async =>
      this.session = session;
}
