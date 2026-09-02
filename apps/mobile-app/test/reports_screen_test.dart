import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/more_screen.dart';
import 'package:nexoraa_mobile/features/reports/controllers/reports_controller.dart';
import 'package:nexoraa_mobile/features/reports/models/report_data.dart';
import 'package:nexoraa_mobile/features/reports/screens/reports_screen.dart';
import 'package:nexoraa_mobile/features/reports/services/report_data_source.dart';
import 'package:nexoraa_mobile/features/reports/widgets/report_widgets.dart';

void main() {
  testWidgets(
    'reports screen renders API data and reloads all reports for a period',
    (WidgetTester tester) async {
      final _FakeReportDataSource source = _FakeReportDataSource();
      final ReportsController controller = ReportsController(
        dataSource: source,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReportsScreen(
            branchId: 'branch-a',
            controller: controller,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(source.branchId, 'branch-a');
      expect(source.summaryQueries, hasLength(1));
      expect(source.orderQueries, hasLength(1));
      expect(source.paymentQueries, hasLength(1));
      expect(source.expenseQueries, hasLength(1));
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Rs. 1.25L'), findsOneWidget);
      expect(find.text('174'), findsOneWidget);
      expect(find.byType(RevenueLineChart), findsOneWidget);
      expect(find.byType(DailyOrdersChart), findsOneWidget);
      expect(find.text('Wash & Fold'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ReportsScreen(
            branchId: 'branch-b',
            controller: controller,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(source.branchId, 'branch-b');
      expect(source.summaryQueries, hasLength(2));

      await tester.tap(find.text('30 Days'));
      await tester.pumpAndSettle();

      expect(source.summaryQueries.last.period, ReportPeriod.thirtyDays);
      expect(source.orderQueries, hasLength(3));
      expect(source.paymentQueries, hasLength(3));
      expect(source.expenseQueries, hasLength(3));
      final Text selectedPeriod = tester.widget<Text>(find.text('30 Days'));
      expect(selectedPeriod.style?.color, AppColors.ink);

      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(source.summaryQueries, hasLength(4));
      expect(source.orderQueries, hasLength(4));
      expect(source.paymentQueries, hasLength(4));
      expect(source.expenseQueries, hasLength(4));
      controller.dispose();
    },
  );

  testWidgets('reports screen shows the existing empty and error states', (
    WidgetTester tester,
  ) async {
    final _FakeReportDataSource source = _FakeReportDataSource()..empty = true;
    final ReportsController controller = ReportsController(dataSource: source);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ReportsScreen(
          branchId: 'branch-a',
          controller: controller,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No report data'), findsOneWidget);

    source
      ..empty = false
      ..fail = true;
    await controller.load();
    await tester.pumpAndSettle();
    expect(find.text('Unable to load reports.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    source.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Total Revenue'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('reports menu item invokes reports navigation', (
    WidgetTester tester,
  ) async {
    bool opened = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MoreScreen(
            businessName: 'CleanSoft',
            onExpensesTap: () {},
            onReportsTap: () => opened = true,
            role: 'Owner',
            userProfile: MoreUserProfileData.placeholder,
          ),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Reports'));
    await tester.tap(find.text('Reports'));
    await tester.pump();

    expect(opened, isTrue);
  });
}

class _FakeReportDataSource implements ReportDataSource {
  String? branchId;
  bool empty = false;
  bool fail = false;
  final List<ReportQuery> expenseQueries = <ReportQuery>[];
  final List<ReportQuery> orderQueries = <ReportQuery>[];
  final List<ReportQuery> paymentQueries = <ReportQuery>[];
  final List<ReportQuery> summaryQueries = <ReportQuery>[];

  @override
  void selectBranch(String? branchId) => this.branchId = branchId;

  @override
  Future<BranchPerformanceReport> loadBranchPerformance(
    ReportQuery query,
  ) async =>
      const BranchPerformanceReport(branches: <BranchPerformanceRecord>[]);

  @override
  Future<ReportSummary> loadSummary(ReportQuery query) async {
    summaryQueries.add(query);
    if (fail) throw Exception('offline');
    if (empty) return _emptySummary;
    return _summary;
  }

  @override
  Future<OrderReport> loadOrders(ReportQuery query) async {
    orderQueries.add(query);
    if (fail) throw Exception('offline');
    return OrderReport(
      metrics: _orderMetrics(empty ? 0 : 174),
      total: empty ? 0 : 174,
    );
  }

  @override
  Future<PaymentReport> loadPayments(ReportQuery query) async {
    paymentQueries.add(query);
    if (fail) throw Exception('offline');
    final int count = empty ? 0 : 12;
    return PaymentReport(
      metrics: PaymentReportMetrics(
        collectedAmountMinor: empty ? 0 : 11800000,
        failedAmountMinor: 0,
        paymentCount: count,
        pendingAmountMinor: 0,
        statusBreakdown: empty
            ? <String, int>{}
            : <String, int>{'Successful': count},
        totalPaymentAmountMinor: empty ? 0 : 11800000,
        trend: const <ReportAmountTrendPoint>[],
      ),
      total: count,
    );
  }

  @override
  Future<ExpenseReport> loadExpenses(ReportQuery query) async {
    expenseQueries.add(query);
    if (fail) throw Exception('offline');
    return ExpenseReport(
      metrics: ExpenseReportMetrics(
        categoryBreakdown: const <ExpenseCategoryBreakdown>[],
        expenseCount: empty ? 0 : 2,
        totalExpenses: empty ? 0 : 2500,
        trend: const <ReportAmountTrendPoint>[],
      ),
      total: empty ? 0 : 2,
    );
  }
}

const ReportSummary _summary = ReportSummary(
  collected: 118000,
  collectionRate: 94.4,
  netProfit: 43200,
  orderChange: 24,
  serviceBreakdown: <ReportServiceBreakdown>[
    ReportServiceBreakdown(name: 'Wash & Fold', percentage: 42),
    ReportServiceBreakdown(name: 'Dry Cleaning', percentage: 58),
  ],
  totalOrders: 174,
  totalRevenue: 125000,
  revenueChange: 18.2,
  trend: <ReportTrendPoint>[
    ReportTrendPoint(label: 'Mon', orders: 18, revenue: 12000),
    ReportTrendPoint(label: 'Tue', orders: 22, revenue: 15400),
  ],
);

const ReportSummary _emptySummary = ReportSummary(
  collected: 0,
  collectionRate: 0,
  netProfit: 0,
  orderChange: 0,
  serviceBreakdown: <ReportServiceBreakdown>[],
  totalOrders: 0,
  totalRevenue: 0,
  revenueChange: 0,
  trend: <ReportTrendPoint>[],
);

OrderReportMetrics _orderMetrics(int count) => OrderReportMetrics(
  cancelledOrders: 0,
  completedOrders: count,
  pendingOrders: 0,
  statusBreakdown: count == 0
      ? <String, int>{}
      : <String, int>{'Delivered': count},
  totalOrderValue: count == 0 ? 0 : 125000,
  totalOrders: count,
  totalOutstandingAmount: 0,
  trend: const <ReportTrendPoint>[],
);
