import 'package:nexoraa_mobile/features/reports/models/report_data.dart';

abstract interface class ReportDataSource {
  Future<BranchPerformanceReport> loadBranchPerformance(ReportQuery query);

  Future<ExpenseReport> loadExpenses(ReportQuery query);

  Future<OrderReport> loadOrders(ReportQuery query);

  Future<PaymentReport> loadPayments(ReportQuery query);

  Future<ReportSummary> loadSummary(ReportQuery query);

  void selectBranch(String? branchId);
}
