import 'package:nexoraa_mobile/features/expenses/data/expense_dummy_data.dart';
import 'package:nexoraa_mobile/features/expenses/models/expense.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_data_source.dart';

class ExpenseDummyDataSource implements ExpenseDataSource {
  final List<Expense> _expenses = List<Expense>.of(ExpenseDummyData.expenses);

  @override
  Future<List<ExpenseCategory>> getExpenseCategories() async =>
      List<ExpenseCategory>.unmodifiable(ExpenseDummyData.categories);

  @override
  Future<List<ExpensePaymentOption>> getPaymentMethods() async =>
      List<ExpensePaymentOption>.unmodifiable(ExpenseDummyData.paymentMethods);

  @override
  Future<List<Expense>> getExpenses({
    ExpenseFilter filter = const ExpenseFilter(),
  }) async => _expenses.where(filter.matches).toList(growable: false);

  @override
  Future<Expense> createExpense(CreateExpenseRequest request) async {
    final ExpenseCategory category = ExpenseDummyData.categories.firstWhere(
      (ExpenseCategory item) => item.id == request.categoryId,
    );
    final DateTime now = DateTime.now();
    final Expense expense = Expense(
      id: 'sample-${now.microsecondsSinceEpoch}',
      tenantId: ExpenseDummyData.tenantId,
      branchId: ExpenseDummyData.branchId,
      expenseCategoryId: category.id,
      categoryName: category.name,
      amount: request.amount,
      paymentMethod: request.paymentMethod,
      vendor: request.vendor,
      description: request.description,
      expenseDate: request.expenseDate,
      recordedBy: ExpenseDummyData.recordedBy,
      createdAt: now,
    );
    _expenses.insert(0, expense);
    return expense;
  }

  @override
  Future<Expense> updateExpense(String id, UpdateExpenseRequest request) async {
    final int index = _expenses.indexWhere((Expense item) => item.id == id);
    if (index < 0) throw StateError('Expense not found');
    final ExpenseCategory category = ExpenseDummyData.categories.firstWhere(
      (ExpenseCategory item) => item.id == request.categoryId,
    );
    final Expense previous = _expenses[index];
    final Expense updated = Expense(
      id: previous.id,
      tenantId: previous.tenantId,
      branchId: previous.branchId,
      expenseCategoryId: category.id,
      categoryName: category.name,
      amount: request.amount,
      paymentMethod: request.paymentMethod,
      vendor: request.vendor,
      description: request.description,
      attachment: previous.attachment,
      expenseDate: request.expenseDate,
      recordedBy: previous.recordedBy,
      createdAt: previous.createdAt,
    );
    _expenses[index] = updated;
    return updated;
  }
}
