import 'package:flutter/foundation.dart';

enum ReportPeriod {
  sevenDays('7 Days', '7d'),
  thirtyDays('30 Days', '30d'),
  threeMonths('3 Months', '3m'),
  year('Year', '1y');

  const ReportPeriod(this.label, this.apiValue);

  final String apiValue;
  final String label;
}

@immutable
class ReportQuery {
  const ReportQuery.period(this.period) : startDate = null, endDate = null;

  const ReportQuery.custom({required this.startDate, required this.endDate})
    : period = null;

  final DateTime? endDate;
  final ReportPeriod? period;
  final DateTime? startDate;

  Map<String, String> toQueryParameters() => <String, String>{
    if (period != null) 'period': period!.apiValue,
    if (startDate != null) 'startDate': startDate!.toUtc().toIso8601String(),
    if (endDate != null) 'endDate': endDate!.toUtc().toIso8601String(),
  };
}

@immutable
class ReportTrendPoint {
  const ReportTrendPoint({
    required this.label,
    required this.orders,
    required this.revenue,
  });

  factory ReportTrendPoint.fromJson(Map<String, dynamic> json) =>
      ReportTrendPoint(
        label: _string(json, 'label'),
        orders: _integer(json, 'orders'),
        revenue: _number(json, 'revenue'),
      );

  final String label;
  final int orders;
  final double revenue;
}

@immutable
class ReportAmountTrendPoint {
  const ReportAmountTrendPoint({
    required this.amount,
    required this.count,
    required this.date,
  });

  factory ReportAmountTrendPoint.fromJson(Map<String, dynamic> json) =>
      ReportAmountTrendPoint(
        amount: _number(json, 'amount'),
        count: _integer(json, 'count'),
        date: DateTime.parse(_string(json, 'date')),
      );

  final double amount;
  final int count;
  final DateTime date;
}

@immutable
class ReportServiceBreakdown {
  const ReportServiceBreakdown({required this.name, required this.percentage});

  factory ReportServiceBreakdown.fromJson(Map<String, dynamic> json) =>
      ReportServiceBreakdown(
        name: _string(json, 'name'),
        percentage: _integer(json, 'percentage'),
      );

  final String name;
  final int percentage;
}

@immutable
class ReportSummary {
  const ReportSummary({
    required this.collected,
    required this.collectionRate,
    required this.netProfit,
    required this.orderChange,
    required this.serviceBreakdown,
    required this.totalOrders,
    required this.totalRevenue,
    required this.revenueChange,
    required this.trend,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
    collected: _number(json, 'collected'),
    collectionRate: _number(json, 'collectionRate'),
    netProfit: _number(json, 'netProfit'),
    orderChange: _integer(json, 'orderChange'),
    serviceBreakdown: _maps(
      json,
      'serviceBreakdown',
    ).map(ReportServiceBreakdown.fromJson).toList(growable: false),
    totalOrders: _integer(json, 'totalOrders'),
    totalRevenue: _number(json, 'totalRevenue'),
    revenueChange: _number(json, 'revenueChange'),
    trend: _maps(
      json,
      'trend',
    ).map(ReportTrendPoint.fromJson).toList(growable: false),
  );

  final double collected;
  final double collectionRate;
  final double netProfit;
  final int orderChange;
  final List<ReportServiceBreakdown> serviceBreakdown;
  final int totalOrders;
  final double totalRevenue;
  final double revenueChange;
  final List<ReportTrendPoint> trend;

  bool get isEmpty =>
      totalOrders == 0 &&
      totalRevenue == 0 &&
      collected == 0 &&
      netProfit == 0 &&
      trend.isEmpty &&
      serviceBreakdown.isEmpty;
}

@immutable
class OrderReportMetrics {
  const OrderReportMetrics({
    required this.cancelledOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.statusBreakdown,
    required this.totalOrderValue,
    required this.totalOrders,
    required this.totalOutstandingAmount,
    required this.trend,
  });

  factory OrderReportMetrics.fromJson(Map<String, dynamic> json) =>
      OrderReportMetrics(
        cancelledOrders: _integer(json, 'cancelledOrders'),
        completedOrders: _integer(json, 'completedOrders'),
        pendingOrders: _integer(json, 'pendingOrders'),
        statusBreakdown: _integerMap(json, 'statusBreakdown'),
        totalOrderValue: _number(json, 'totalOrderValue'),
        totalOrders: _integer(json, 'totalOrders'),
        totalOutstandingAmount: _number(json, 'totalOutstandingAmount'),
        trend: _maps(json, 'trend')
            .map(
              (Map<String, dynamic> point) => ReportTrendPoint(
                label: _string(point, 'date'),
                orders: _integer(point, 'orders'),
                revenue: _number(point, 'revenue'),
              ),
            )
            .toList(growable: false),
      );

  final int cancelledOrders;
  final int completedOrders;
  final int pendingOrders;
  final Map<String, int> statusBreakdown;
  final double totalOrderValue;
  final int totalOrders;
  final double totalOutstandingAmount;
  final List<ReportTrendPoint> trend;
}

@immutable
class PaymentReportMetrics {
  const PaymentReportMetrics({
    required this.collectedAmountMinor,
    required this.failedAmountMinor,
    required this.paymentCount,
    required this.pendingAmountMinor,
    required this.statusBreakdown,
    required this.totalPaymentAmountMinor,
    required this.trend,
  });

  factory PaymentReportMetrics.fromJson(Map<String, dynamic> json) =>
      PaymentReportMetrics(
        collectedAmountMinor: _integer(json, 'collectedAmountMinor'),
        failedAmountMinor: _integer(json, 'failedAmountMinor'),
        paymentCount: _integer(json, 'paymentCount'),
        pendingAmountMinor: _integer(json, 'pendingAmountMinor'),
        statusBreakdown: _integerMap(json, 'statusBreakdown'),
        totalPaymentAmountMinor: _integer(json, 'totalPaymentAmountMinor'),
        trend: _maps(
          json,
          'trend',
        ).map(ReportAmountTrendPoint.fromJson).toList(growable: false),
      );

  final int collectedAmountMinor;
  final int failedAmountMinor;
  final int paymentCount;
  final int pendingAmountMinor;
  final Map<String, int> statusBreakdown;
  final int totalPaymentAmountMinor;
  final List<ReportAmountTrendPoint> trend;
}

@immutable
class ExpenseCategoryBreakdown {
  const ExpenseCategoryBreakdown({
    required this.amount,
    required this.categoryId,
    required this.count,
    this.categoryName,
  });

  factory ExpenseCategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      ExpenseCategoryBreakdown(
        amount: _number(json, 'amount'),
        categoryId: _string(json, 'categoryId'),
        categoryName: json['categoryName'] as String?,
        count: _integer(json, 'count'),
      );

  final double amount;
  final String categoryId;
  final String? categoryName;
  final int count;
}

@immutable
class ExpenseReportMetrics {
  const ExpenseReportMetrics({
    required this.categoryBreakdown,
    required this.expenseCount,
    required this.totalExpenses,
    required this.trend,
  });

  factory ExpenseReportMetrics.fromJson(Map<String, dynamic> json) =>
      ExpenseReportMetrics(
        categoryBreakdown: _maps(
          json,
          'categoryBreakdown',
        ).map(ExpenseCategoryBreakdown.fromJson).toList(growable: false),
        expenseCount: _integer(json, 'expenseCount'),
        totalExpenses: _number(json, 'totalExpenses'),
        trend: _maps(
          json,
          'trend',
        ).map(ReportAmountTrendPoint.fromJson).toList(growable: false),
      );

  final List<ExpenseCategoryBreakdown> categoryBreakdown;
  final int expenseCount;
  final double totalExpenses;
  final List<ReportAmountTrendPoint> trend;
}

@immutable
class OrderReport {
  const OrderReport({required this.metrics, required this.total});

  factory OrderReport.fromJson(Map<String, dynamic> json) => OrderReport(
    metrics: OrderReportMetrics.fromJson(_map(json, 'metrics')),
    total: _integer(json, 'total'),
  );

  final OrderReportMetrics metrics;
  final int total;
}

@immutable
class PaymentReport {
  const PaymentReport({required this.metrics, required this.total});

  factory PaymentReport.fromJson(Map<String, dynamic> json) => PaymentReport(
    metrics: PaymentReportMetrics.fromJson(_map(json, 'metrics')),
    total: _integer(json, 'total'),
  );

  final PaymentReportMetrics metrics;
  final int total;
}

@immutable
class ExpenseReport {
  const ExpenseReport({required this.metrics, required this.total});

  factory ExpenseReport.fromJson(Map<String, dynamic> json) => ExpenseReport(
    metrics: ExpenseReportMetrics.fromJson(_map(json, 'metrics')),
    total: _integer(json, 'total'),
  );

  final ExpenseReportMetrics metrics;
  final int total;
}

@immutable
class BranchPerformanceMetrics {
  const BranchPerformanceMetrics({
    required this.collected,
    required this.expenses,
    required this.netProfit,
    required this.orders,
    required this.outstanding,
    required this.revenue,
    required this.revenueSharePercentage,
  });

  factory BranchPerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      BranchPerformanceMetrics(
        collected: _number(json, 'collected'),
        expenses: _number(json, 'expenses'),
        netProfit: _number(json, 'netProfit'),
        orders: _integer(json, 'orders'),
        outstanding: _number(json, 'outstanding'),
        revenue: _number(json, 'revenue'),
        revenueSharePercentage: _number(json, 'revenueSharePercentage'),
      );

  final double collected;
  final double expenses;
  final double netProfit;
  final int orders;
  final double outstanding;
  final double revenue;
  final double revenueSharePercentage;
}

@immutable
class BranchPerformanceRecord {
  const BranchPerformanceRecord({
    required this.branchId,
    required this.branchName,
    required this.metrics,
    this.branchCode,
  });

  factory BranchPerformanceRecord.fromJson(Map<String, dynamic> json) =>
      BranchPerformanceRecord(
        branchCode: json['branchCode'] as String?,
        branchId: _string(json, 'branchId'),
        branchName: _string(json, 'branchName'),
        metrics: BranchPerformanceMetrics.fromJson(_map(json, 'metrics')),
      );

  final String? branchCode;
  final String branchId;
  final String branchName;
  final BranchPerformanceMetrics metrics;
}

@immutable
class BranchPerformanceReport {
  const BranchPerformanceReport({required this.branches});

  factory BranchPerformanceReport.fromJson(Map<String, dynamic> json) =>
      BranchPerformanceReport(
        branches: _maps(
          json,
          'branches',
        ).map(BranchPerformanceRecord.fromJson).toList(growable: false),
      );

  final List<BranchPerformanceRecord> branches;
}

double _number(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is num) return value.toDouble();
  throw FormatException('Expected numeric $key');
}

int _integer(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is num) return value.toInt();
  throw FormatException('Expected integer $key');
}

String _string(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is String) return value;
  throw FormatException('Expected string $key');
}

Map<String, dynamic> _map(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is Map<String, dynamic>) return value;
  throw FormatException('Expected object $key');
}

Iterable<Map<String, dynamic>> _maps(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is List<dynamic>) return value.whereType<Map<String, dynamic>>();
  throw FormatException('Expected list $key');
}

Map<String, int> _integerMap(Map<String, dynamic> json, String key) {
  final Map<String, dynamic> values = _map(json, key);
  return values.map((String name, dynamic value) {
    if (value is num) return MapEntry<String, int>(name, value.toInt());
    throw FormatException('Expected integer $key.$name');
  });
}
