import 'package:nexoraa_mobile/features/expenses/models/expense.dart';

abstract interface class ExpenseDataSource {
  void selectBranch(String? branchId);
  Future<List<Expense>> getExpenses({ExpenseFilter filter});
  Future<ExpenseStatistics> getStatistics();
  Future<List<ExpenseCategory>> getExpenseCategories();
  Future<List<ExpensePaymentOption>> getPaymentMethods();
  Future<Expense> createExpense(CreateExpenseRequest request);
  Future<Expense> updateExpense(String id, UpdateExpenseRequest request);
}
