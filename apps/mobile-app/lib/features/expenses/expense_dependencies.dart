import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/expenses/controllers/expense_controller.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_api_service.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_service.dart';

abstract final class ExpenseDependencies {
  static ExpenseController createController() => ExpenseController(
    service: ExpenseService(
      dataSource: ExpenseApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
    ),
  );
}
