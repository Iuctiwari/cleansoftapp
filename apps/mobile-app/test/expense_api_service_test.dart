import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/expenses/models/expense.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_api_service.dart';

void main() {
  test('creates expenses with auth token and selected branch only', () async {
    final tokenStorage = _MemoryTokenStorage(
      AuthenticationSession(
        accessToken: 'expense-token',
        refreshToken: 'refresh-token',
        accessTokenExpiresAt: DateTime.utc(2027),
        refreshTokenExpiresAt: DateTime.utc(2028),
        tenantId: 'tenant-1',
      ),
    );
    final service = ExpenseApiService(
      tokenStorage: tokenStorage,
      baseUrl: 'http://expense.test/api',
      client: MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://expense.test/expenses');
        expect(request.headers['authorization'], 'Bearer expense-token');
        expect(request.headers['x-branch-id'], 'branch-a');
        expect(request.headers.containsKey('x-tenant-id'), isFalse);

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['expenseCategoryId'], '64f0c18f7c4d2f0012ab34cd');
        expect(body['paymentMethod'], 'Cash');

        return http.Response(
          jsonEncode(<String, Object?>{
            'id': '64f0c18f7c4d2f0012ab34ef',
            'tenantId': 'tenant-1',
            'branchId': 'branch-a',
            'expenseCategoryId': body['expenseCategoryId'],
            'categoryName': 'Utilities',
            'amount': body['amount'],
            'paymentMethod': body['paymentMethod'],
            'vendor': body['vendor'],
            'description': body['description'],
            'expenseDate': body['expenseDate'],
            'recordedBy': 'user-1',
            'createdAt': '2026-08-21T00:00:00.000Z',
          }),
          201,
        );
      }),
    )..selectBranch('branch-a');

    final expense = await service.createExpense(
      CreateExpenseRequest(
        categoryId: '64f0c18f7c4d2f0012ab34cd',
        amount: 125,
        paymentMethod: ExpensePaymentMethod.cash,
        vendor: 'Power Co',
        description: 'Electricity bill',
        expenseDate: DateTime.utc(2026, 8, 21),
      ),
    );

    expect(expense.branchId, 'branch-a');
  });

  test('does not send expense requests without an active branch', () async {
    final service = ExpenseApiService(
      tokenStorage: _MemoryTokenStorage(
        AuthenticationSession(
          accessToken: 'expense-token',
          refreshToken: 'refresh-token',
          accessTokenExpiresAt: DateTime.utc(2027),
          refreshTokenExpiresAt: DateTime.utc(2028),
        ),
      ),
      baseUrl: 'http://expense.test',
      client: MockClient((_) async => fail('request should not be sent')),
    );

    await expectLater(
      service.createExpense(
        CreateExpenseRequest(
          categoryId: '64f0c18f7c4d2f0012ab34cd',
          amount: 125,
          paymentMethod: ExpensePaymentMethod.cash,
          vendor: 'Power Co',
          description: 'Electricity bill',
          expenseDate: DateTime.utc(2026, 8, 21),
        ),
      ),
      throwsA(isA<ExpenseApiException>()),
    );
  });
}

class _MemoryTokenStorage implements AuthTokenStorage {
  _MemoryTokenStorage(this.session);

  AuthenticationSession? session;

  @override
  Future<void> clear() async {
    session = null;
  }

  @override
  Future<AuthenticationSession?> read() async => session;

  @override
  Future<void> write(AuthenticationSession session) async {
    this.session = session;
  }
}
