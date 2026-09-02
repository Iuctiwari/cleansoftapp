import 'package:nexoraa_mobile/features/expenses/models/expense.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_data_source.dart';

class ExpenseService {
  const ExpenseService({required ExpenseDataSource dataSource})
    : _dataSource = dataSource;

  final ExpenseDataSource _dataSource;

  void selectBranch(String? branchId) => _dataSource.selectBranch(branchId);

  Future<List<Expense>> list({ExpenseFilter filter = const ExpenseFilter()}) =>
      _dataSource.getExpenses(filter: filter);
  Future<ExpenseStatistics> statistics() => _dataSource.getStatistics();
  Future<List<ExpenseCategory>> categories() =>
      _dataSource.getExpenseCategories();
  Future<List<ExpensePaymentOption>> paymentMethods() =>
      _dataSource.getPaymentMethods();
  Future<Expense> create(CreateExpenseRequest request) =>
      _dataSource.createExpense(request);
  Future<Expense> update(String id, UpdateExpenseRequest request) =>
      _dataSource.updateExpense(id, request);
}
