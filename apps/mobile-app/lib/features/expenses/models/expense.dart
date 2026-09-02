import 'package:flutter/foundation.dart';

enum ExpensePaymentMethod { cash, upi, card, bankTransfer }

ExpensePaymentMethod parseExpensePaymentMethod(String? raw) {
  switch (raw?.toLowerCase().replaceAll('_', '').replaceAll(' ', '')) {
    case 'upi':
      return ExpensePaymentMethod.upi;
    case 'card':
      return ExpensePaymentMethod.card;
    case 'banktransfer':
      return ExpensePaymentMethod.bankTransfer;
    case 'cash':
    default:
      return ExpensePaymentMethod.cash;
  }
}

String expensePaymentMethodToJson(ExpensePaymentMethod method) {
  switch (method) {
    case ExpensePaymentMethod.cash:
      return 'Cash';
    case ExpensePaymentMethod.upi:
      return 'UPI';
    case ExpensePaymentMethod.card:
      return 'Card';
    case ExpensePaymentMethod.bankTransfer:
      return 'BankTransfer';
  }
}

String resolveCategorySymbol(String name) {
  final String lower = name.toLowerCase();
  if (lower.contains('rent')) return '🏢';
  if (lower.contains('electric') || lower.contains('power')) return '⚡';
  if (lower.contains('water') || lower.contains('plumb')) return '💧';
  if (lower.contains('detergent') ||
      lower.contains('soap') ||
      lower.contains('material') ||
      lower.contains('suppl')) {
    return '🧴';
  }
  if (lower.contains('packag') ||
      lower.contains('bag') ||
      lower.contains('hanger')) {
    return '📦';
  }
  if (lower.contains('salar') ||
      lower.contains('wage') ||
      lower.contains('staff')) {
    return '👥';
  }
  if (lower.contains('transport') ||
      lower.contains('fuel') ||
      lower.contains('deliver') ||
      lower.contains('logist')) {
    return '🚚';
  }
  if (lower.contains('maintain') ||
      lower.contains('machin') ||
      lower.contains('repair')) {
    return '🔧';
  }
  if (lower.contains('market') ||
      lower.contains('ad') ||
      lower.contains('promo')) {
    return '📢';
  }
  return '🏷️';
}

@immutable
class ExpensePaymentOption {
  const ExpensePaymentOption({required this.method, required this.label});

  final ExpensePaymentMethod method;
  final String label;

  static const List<ExpensePaymentOption> defaultOptions = <ExpensePaymentOption>[
    ExpensePaymentOption(method: ExpensePaymentMethod.cash, label: 'Cash'),
    ExpensePaymentOption(method: ExpensePaymentMethod.upi, label: 'UPI / QR'),
    ExpensePaymentOption(method: ExpensePaymentMethod.card, label: 'Debit / Credit Card'),
    ExpensePaymentOption(method: ExpensePaymentMethod.bankTransfer, label: 'Bank Transfer'),
  ];
}

@immutable
class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.symbol,
    this.description,
  });

  final String id;
  final String name;
  final String symbol;
  final String? description;

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    final String name = (json['categoryName'] ?? json['name'] ?? 'Other').toString();
    final String symbol = json['symbol']?.toString() ?? resolveCategorySymbol(name);
    return ExpenseCategory(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: name,
      symbol: symbol,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'categoryName': name,
    'description': description,
    'symbol': symbol,
  };
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

  factory Expense.fromJson(Map<String, dynamic> json) {
    final dynamic rawAmount = json['amount'];
    final double parsedAmount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

    final String catId = (json['expenseCategoryId'] ?? json['categoryId'] ?? '').toString();
    final String catName = (json['categoryName'] ?? '').toString();

    DateTime parseDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
      }
      return DateTime.now();
    }

    return Expense(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      tenantId: (json['tenantId'] ?? '').toString(),
      branchId: (json['branchId'] ?? '').toString(),
      expenseCategoryId: catId,
      categoryName: catName.isNotEmpty ? catName : 'General',
      amount: parsedAmount,
      paymentMethod: parseExpensePaymentMethod(json['paymentMethod']?.toString()),
      vendor: (json['vendor'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      attachment: json['attachment']?.toString(),
      expenseDate: parseDate(json['expenseDate']),
      recordedBy: (json['recordedBy'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'tenantId': tenantId,
    'branchId': branchId,
    'expenseCategoryId': expenseCategoryId,
    'categoryName': categoryName,
    'amount': amount,
    'paymentMethod': expensePaymentMethodToJson(paymentMethod),
    'vendor': vendor,
    'description': description,
    'attachment': attachment,
    'expenseDate': expenseDate.toUtc().toIso8601String(),
    'recordedBy': recordedBy,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
}

@immutable
class ExpenseFilter {
  const ExpenseFilter({this.categoryId, this.search});

  final String? categoryId;
  final String? search;

  bool matches(Expense expense) {
    if (categoryId != null && expense.expenseCategoryId != categoryId) {
      return false;
    }
    if (search != null && search!.trim().isNotEmpty) {
      final query = search!.trim().toLowerCase();
      return expense.description.toLowerCase().contains(query) ||
          expense.vendor.toLowerCase().contains(query);
    }
    return true;
  }
}

@immutable
class ExpenseStatistics {
  const ExpenseStatistics({
    required this.totalAmount,
    required this.count,
    required this.categoryCount,
  });

  final double totalAmount;
  final int count;
  final int categoryCount;

  factory ExpenseStatistics.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    int parseCount(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    return ExpenseStatistics(
      totalAmount: parseAmount(json['totalAmount']),
      count: parseCount(json['count']),
      categoryCount: parseCount(json['categoryCount']),
    );
  }
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

  Map<String, dynamic> toJson() => <String, dynamic>{
    'expenseCategoryId': categoryId,
    'amount': amount,
    'paymentMethod': expensePaymentMethodToJson(paymentMethod),
    'vendor': vendor.trim(),
    'description': description.trim(),
    'expenseDate': expenseDate.toUtc().toIso8601String(),
  };
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
