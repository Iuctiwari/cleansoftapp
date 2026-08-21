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
  String _searchQuery = '';
  bool _loading = false;
  String? _error;

  List<ExpenseCategory> get categories => List.unmodifiable(_categories);
  List<ExpensePaymentOption> get paymentMethods =>
      List.unmodifiable(_paymentMethods);
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _loading;
  String? get error => _error;

  List<Expense> get expenses => List.unmodifiable(
    _allExpenses.where(
      (Expense item) {
        final bool matchesCategory = _selectedCategoryId == null ||
            item.expenseCategoryId == _selectedCategoryId;
        if (!matchesCategory) return false;
        if (_searchQuery.trim().isEmpty) return true;
        final String q = _searchQuery.trim().toLowerCase();
        return item.description.toLowerCase().contains(q) ||
            item.vendor.toLowerCase().contains(q) ||
            item.categoryName.toLowerCase().contains(q);
      },
    ),
  );

  double get total => _allExpenses.fold<double>(
    0,
    (double sum, Expense item) => sum + item.amount,
  );

  int get categoryCount =>
      _allExpenses.map((Expense item) => item.expenseCategoryId).toSet().length;

  Future<void> selectBranch(String? branchId) async {
    _service.selectBranch(branchId);
    await load();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _service.list(),
        _service.categories(),
        _service.paymentMethods(),
      ]);
      _allExpenses = results[0] as List<Expense>;
      _categories = results[1] as List<ExpenseCategory>;
      _paymentMethods = results[2] as List<ExpensePaymentOption>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void selectCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> addExpense(CreateExpenseRequest request) async {
    _loading = true;
    notifyListeners();
    try {
      final Expense created = await _service.create(request);
      _allExpenses = <Expense>[created, ..._allExpenses];
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
