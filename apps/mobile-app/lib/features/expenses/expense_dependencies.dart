import 'package:nexoraa_mobile/features/expenses/controllers/expense_controller.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_dummy_data_source.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_service.dart';

abstract final class ExpenseDependencies {
  static ExpenseController createController() => ExpenseController(
    service: ExpenseService(dataSource: ExpenseDummyDataSource()),
  );
}
