import 'package:flutter/foundation.dart';

enum ExpensePaymentMethod { cash, upi, card, bankTransfer }

@immutable
class ExpensePaymentOption {
  const ExpensePaymentOption({required this.method, required this.label});

  final ExpensePaymentMethod method;
  final String label;
}

@immutable
class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.symbol,
  });

  final String id;
  final String name;
  final String symbol;
}

@immutable
class Expense {
  const Expense({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.expenseCategoryId,
    required this.categoryName,
    required this.amount,
    required this.paymentMethod,
    required this.vendor,
    required this.description,
    required this.expenseDate,
    required this.recordedBy,
    required this.createdAt,
    this.attachment,
  });

  final String id;
  final String tenantId;
  final String branchId;
  final String expenseCategoryId;
  final String categoryName;
  final double amount;
  final ExpensePaymentMethod paymentMethod;
  final String vendor;
  final String description;
  final String? attachment;
  final DateTime expenseDate;
  final String recordedBy;
  final DateTime createdAt;
}

@immutable
class ExpenseFilter {
  const ExpenseFilter({this.categoryId});

  final String? categoryId;

  bool matches(Expense expense) =>
      categoryId == null || expense.expenseCategoryId == categoryId;
}

@immutable
class CreateExpenseRequest {
  const CreateExpenseRequest({
    required this.categoryId,
    required this.amount,
    required this.paymentMethod,
    required this.vendor,
    required this.description,
    required this.expenseDate,
  });

  final String categoryId;
  final double amount;
  final ExpensePaymentMethod paymentMethod;
  final String vendor;
  final String description;
  final DateTime expenseDate;
}

@immutable
class UpdateExpenseRequest extends CreateExpenseRequest {
  const UpdateExpenseRequest({
    required super.categoryId,
    required super.amount,
    required super.paymentMethod,
    required super.vendor,
    required super.description,
    required super.expenseDate,
  });
}
