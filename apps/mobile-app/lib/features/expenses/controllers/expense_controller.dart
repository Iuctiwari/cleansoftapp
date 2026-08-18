import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/expenses/models/expense.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_service.dart';

class ExpenseController extends ChangeNotifier {
  ExpenseController({required ExpenseService service}) : _service = service;

  final ExpenseService _service;
  List<Expense> _allExpenses = <Expense>[];
  List<ExpenseCategory> _categories = <ExpenseCategory>[];
  List<ExpensePaymentOption> _paymentMethods = <ExpensePaymentOption>[];
  String? _selectedCategoryId;
  bool _loading = false;

  List<ExpenseCategory> get categories => List.unmodifiable(_categories);
  List<ExpensePaymentOption> get paymentMethods =>
      List.unmodifiable(_paymentMethods);
  String? get selectedCategoryId => _selectedCategoryId;
  bool get isLoading => _loading;
  List<Expense> get expenses => List.unmodifiable(
    _allExpenses.where(
      (Expense item) =>
          _selectedCategoryId == null ||
          item.expenseCategoryId == _selectedCategoryId,
    ),
  );
  double get total => _allExpenses.fold<double>(
    0,
    (double sum, Expense item) => sum + item.amount,
  );
  int get categoryCount =>
      _allExpenses.map((Expense item) => item.expenseCategoryId).toSet().length;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    final List<Object> results = await Future.wait<Object>(<Future<Object>>[
      _service.list(),
      _service.categories(),
      _service.paymentMethods(),
    ]);
    _allExpenses = results[0] as List<Expense>;
    _categories = results[1] as List<ExpenseCategory>;
    _paymentMethods = results[2] as List<ExpensePaymentOption>;
    _loading = false;
    notifyListeners();
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> addExpense(CreateExpenseRequest request) async {
    final Expense created = await _service.create(request);
    _allExpenses = <Expense>[created, ..._allExpenses];
    notifyListeners();
  }
}
