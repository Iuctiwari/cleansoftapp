import 'package:nexoraa_mobile/features/expenses/models/expense.dart';

abstract final class ExpenseDummyData {
  static const String tenantId = 'sample-tenant';
  static const String branchId = 'sample-main-branch';
  static const String recordedBy = 'Sample Owner';

  static const List<ExpenseCategory> categories = <ExpenseCategory>[
    ExpenseCategory(id: 'utilities', name: 'Utilities', symbol: '⚡'),
    ExpenseCategory(id: 'supplies', name: 'Supplies', symbol: '🧴'),
    ExpenseCategory(id: 'salaries', name: 'Salaries', symbol: '👥'),
    ExpenseCategory(id: 'rent', name: 'Rent', symbol: '🏪'),
    ExpenseCategory(id: 'other', name: 'Other', symbol: '🔧'),
    ExpenseCategory(id: 'water', name: 'Water', symbol: '💧'),
  ];

  static const List<ExpensePaymentOption> paymentMethods =
      <ExpensePaymentOption>[
        ExpensePaymentOption(method: ExpensePaymentMethod.cash, label: 'Cash'),
        ExpensePaymentOption(method: ExpensePaymentMethod.upi, label: 'UPI'),
        ExpensePaymentOption(method: ExpensePaymentMethod.card, label: 'Card'),
        ExpensePaymentOption(
          method: ExpensePaymentMethod.bankTransfer,
          label: 'Bank Transfer',
        ),
      ];

  static final List<Expense> expenses = <Expense>[
    _expense('electricity', 'utilities', 'Electricity Bill', 4500, 15),
    _expense('detergent', 'supplies', 'Detergent & Supplies', 2200, 14),
    _expense('staff', 'salaries', 'Staff Salaries', 45000, 10),
    _expense('shop-rent', 'rent', 'Shop Rent', 18000, 1),
    _expense('maintenance', 'other', 'Machine Maintenance', 3800, 28, 6),
    _expense('water', 'water', 'Water Bill', 1200, 25, 6),
  ];

  static Expense _expense(
    String id,
    String categoryId,
    String description,
    double amount,
    int day, [
    int month = 7,
  ]) {
    final ExpenseCategory category = categories.firstWhere(
      (ExpenseCategory item) => item.id == categoryId,
    );
    final DateTime date = DateTime(2026, month, day);
    return Expense(
      id: id,
      tenantId: tenantId,
      branchId: branchId,
      expenseCategoryId: categoryId,
      categoryName: category.name,
      amount: amount,
      paymentMethod: id == 'staff'
          ? ExpensePaymentMethod.bankTransfer
          : ExpensePaymentMethod.cash,
      vendor: 'Sample ${category.name} Vendor',
      description: description,
      expenseDate: date,
      recordedBy: recordedBy,
      createdAt: date,
    );
  }
}
