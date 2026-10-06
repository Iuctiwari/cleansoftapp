import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_details_screen.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_list_screen.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/dashboard/controllers/dashboard_search_controller.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_models.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_widgets.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/more_screen.dart';
import 'package:nexoraa_mobile/features/expenses/models/expense.dart';
import 'package:nexoraa_mobile/features/expenses/screens/expense_list_screen.dart';
import 'package:nexoraa_mobile/features/expenses/services/expense_api_service.dart';
import 'package:nexoraa_mobile/features/notifications/controllers/notification_controller.dart';
import 'package:nexoraa_mobile/features/notifications/services/notification_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/online_requests_card.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';
import 'package:nexoraa_mobile/features/orders/controllers/new_order_controller.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/screens/new_order_screen.dart';
import 'package:nexoraa_mobile/features/orders/screens/order_details_screen.dart';
import 'package:nexoraa_mobile/features/orders/screens/orders_screen.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/order_catalog_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';
import 'package:nexoraa_mobile/features/payments/controllers/payments_controller.dart';
import 'package:nexoraa_mobile/features/payments/models/payment.dart';
import 'package:nexoraa_mobile/features/payments/screens/payments_screen.dart';
import 'package:nexoraa_mobile/features/reports/models/report_data.dart';
import 'package:nexoraa_mobile/features/reports/screens/reports_screen.dart';
import 'package:nexoraa_mobile/features/reports/services/report_api_service.dart';
import 'package:nexoraa_mobile/features/reports/services/report_data_source.dart';
import 'package:nexoraa_mobile/features/subscription/models/subscription_models.dart';
import 'package:nexoraa_mobile/features/subscription/services/subscription_api_service.dart';
import 'package:nexoraa_mobile/features/subscription/widgets/subscription_status_card.dart';
import 'package:nexoraa_mobile/features/tenant/services/tenant_api_service.dart';

/// Owner dashboard UI served by the existing dashboard route.
///
/// The historical class name is retained so the existing authentication and
/// routing flow does not need to change.
class DashboardPlaceholderScreen extends StatefulWidget {
  const DashboardPlaceholderScreen({
    this.tenantId,
    this.tenantApiService,
    this.expenseApiService,
    this.reportDataSource,
    super.key,
  });

  final String? tenantId;
  final TenantApiService? tenantApiService;
  final ExpenseApiService? expenseApiService;
  final ReportDataSource? reportDataSource;

  @override
  State<DashboardPlaceholderScreen> createState() =>
      _DashboardPlaceholderScreenState();
}

class _DashboardPlaceholderScreenState
    extends State<DashboardPlaceholderScreen> {
  late final CustomerController _customerController;
  late final OrderController _orderController;
  late final PaymentApiService _paymentApiService;
  late final ExpenseApiService _expenseApiService;
  late final PaymentsController _paymentsController;
  late final DashboardSearchController _searchController;
  late final NotificationController _notificationController;
  late final ReportDataSource _reportDataSource;
  final SubscriptionApiService _subscriptionApiService = SubscriptionApiService();
  TenantSubscriptionStatus? _subscriptionStatus;
  bool _subscriptionLoading = true;
  int _currentNavigationIndex = 0;
  String _selectedBranchId = 'unavailable';
  List<Order> _recentOrders = const <Order>[];
  List<PaymentRecord> _recentBills = const <PaymentRecord>[];
  int _todayOrdersCount = 0;
  int _yesterdayOrdersCount = 0;
  int _readyOrdersCount = 0;
  int _deliveriesCount = 0;
  ReportSummary? _dashboardReportSummary;
  double _totalExpenses = 0;
  int _expenseCount = 0;
  bool _expensesLoading = false;
  String? _expenseError;
  List<DashboardBranchPerformance> _branchPerformance =
      const <DashboardBranchPerformance>[];
  bool _branchPerformanceLoading = false;
  String? _branchPerformanceError;
  List<DashboardData> _branches = <DashboardData>[
    DashboardData.empty(
      branchId: 'unavailable',
      branchName: 'Unavailable',
      ownerName: 'Unavailable',
      ownerEmail: 'Unavailable',
      businessName: 'Unavailable',
    ),
  ];

  DashboardData get _data => _branches.firstWhere(
    (data) => data.branchId == _selectedBranchId,
    orElse: () => _branches.first,
  );

  @override
  void initState() {
    super.initState();
    _customerController = CustomerController(
      service: CustomerApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
    );
    _orderController = OrderController(
      service: OrderApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
    )..addListener(_onOrderControllerChanged);
    _paymentApiService = PaymentApiService(
      tokenStorage: AuthenticationDependencies.tokenStorage,
    );
    _expenseApiService =
        widget.expenseApiService ??
        ExpenseApiService(
          tokenStorage: AuthenticationDependencies.tokenStorage,
        );
    _paymentsController = PaymentsController(
      paymentService: _paymentApiService,
      orderController: _orderController,
    );
    _searchController = DashboardSearchController(
      orderService: OrderApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
      customerService: CustomerApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
      paymentService: PaymentApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
    );
    _notificationController = NotificationController(
      service: NotificationApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
    )..addListener(_refreshNotificationBadge);
    _reportDataSource =
        widget.reportDataSource ??
        ReportApiService(tokenStorage: AuthenticationDependencies.tokenStorage);
    final tenantId = widget.tenantId?.trim() ?? '';
    if (tenantId.isNotEmpty) _loadTenantDashboard(tenantId);
    unawaited(_loadSubscriptionStatus());
  }

  /// A subscription lookup failure must never break the dashboard — the card
  /// just shows nothing/"Loading…" and the tenant can still tap into the
  /// full Subscription screen to retry, same fail-open contract as every
  /// other dashboard widget backed by a real API call.
  Future<void> _loadSubscriptionStatus() async {
    try {
      final TenantSubscriptionStatus status = await _subscriptionApiService.getStatus();
      if (!mounted) return;
      setState(() {
        _subscriptionStatus = status;
        _subscriptionLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _subscriptionLoading = false);
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    _orderController
      ..removeListener(_onOrderControllerChanged)
      ..dispose();
    _paymentsController.dispose();
    _searchController.dispose();
    _notificationController
      ..removeListener(_refreshNotificationBadge)
      ..dispose();
    super.dispose();
  }

  void _onOrderControllerChanged() {
    if (mounted && _selectedBranchId != 'unavailable') {
      unawaited(_loadDashboardMetrics());
    }
  }

  void _refreshNotificationBadge() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTenantDashboard(String tenantId) async {
    final service = widget.tenantApiService ?? TenantApiService();
    try {
      final profile = await service.getTenantProfile(tenantId);
      final tenantBranches = await service.listBranches(tenantId);
      if (!mounted) return;

      final branches = tenantBranches.isEmpty
          ? <DashboardData>[
              DashboardData.empty(
                branchId: 'unavailable',
                branchName: 'Unavailable',
                ownerName: profile.ownerName,
                ownerEmail: profile.ownerEmail,
                businessName: profile.businessName,
              ),
            ]
          : tenantBranches
                .map(
                  (branch) => DashboardData.empty(
                    branchId: branch.branchId,
                    branchName: branch.branchName,
                    ownerName: profile.ownerName,
                    ownerEmail: profile.ownerEmail,
                    businessName: profile.businessName,
                  ),
                )
                .toList(growable: false);

      setState(() {
        _branches = branches;
        _selectedBranchId = branches.first.branchId;
        _totalExpenses = 0;
        _expenseCount = 0;
        _expensesLoading = branches.first.branchId != 'unavailable';
        _expenseError = null;
        _branchPerformance = const <DashboardBranchPerformance>[];
        _branchPerformanceLoading = branches.first.branchId != 'unavailable';
        _branchPerformanceError = null;
      });
      await _customerController.selectBranch(branches.first.branchId);
      await _orderController.selectBranch(branches.first.branchId);
      _paymentApiService.selectBranch(branches.first.branchId);
      _expenseApiService.selectBranch(branches.first.branchId);
      _reportDataSource.selectBranch(branches.first.branchId);
      _searchController.selectBranch(branches.first.branchId);
      _notificationController.selectBranch(branches.first.branchId);
      unawaited(_notificationController.connectRealtime());
      unawaited(_notificationController.refreshUnreadCount());
      await Future.wait<void>(<Future<void>>[
        _loadRecentOrders(),
        _loadDashboardMetrics(),
      ]);
    } on Object {
      // The zero/unavailable dashboard remains visible when data cannot load.
    }
  }

  void _selectBranch(String branchId) {
    setState(() {
      _selectedBranchId = branchId;
      _recentOrders = const <Order>[];
      _recentBills = const <PaymentRecord>[];
      _todayOrdersCount = 0;
      _yesterdayOrdersCount = 0;
      _readyOrdersCount = 0;
      _deliveriesCount = 0;
      _dashboardReportSummary = null;
      _totalExpenses = 0;
      _expenseCount = 0;
      _expensesLoading = branchId != 'unavailable';
      _expenseError = null;
    });
    _customerController.selectBranch(branchId);
    _orderController.selectBranch(branchId);
    _paymentApiService.selectBranch(branchId);
    _expenseApiService.selectBranch(branchId);
    _reportDataSource.selectBranch(branchId);
    _searchController.selectBranch(branchId);
    _notificationController.selectBranch(branchId);
    unawaited(_notificationController.connectRealtime());
    unawaited(_notificationController.refreshUnreadCount());
    unawaited(
      Future.wait<void>(<Future<void>>[
        _loadRecentOrders(),
        _loadDashboardMetrics(),
      ]),
    );
  }

  Future<void> _loadRecentOrders() async {
    if (_selectedBranchId == 'unavailable') return;
    try {
      final List<Order> orders = await _orderController.recent(limit: 3);
      if (!mounted) return;
      setState(() => _recentOrders = orders);
    } on OrderApiException {
      if (!mounted) return;
      setState(() => _recentOrders = const <Order>[]);
    }
  }

  /// Loads today's revenue/outstanding/order metrics and the 3 most recent
  /// payments (for "Recent Bills"), reusing [PaymentsController] and
  /// [OrderController] — the same controllers/APIs already backing the
  /// Payments and Orders screens.
  Future<void> _loadDashboardMetrics() async {
    if (_selectedBranchId == 'unavailable') return;
    await Future.wait<void>(<Future<void>>[
      _paymentsController.load(),
      _loadExpenseMetrics(),
      _loadBranchPerformance(),
      _loadReportSummary(),
    ]);
    try {
      final OrderStatistics statistics = await _orderController.statistics();
      if (!mounted) return;
      setState(() {
        _todayOrdersCount = statistics.todayOrders;
        _yesterdayOrdersCount = statistics.yesterdayOrders;
        _readyOrdersCount = statistics.count(OrderStatus.ready);
        _deliveriesCount = statistics.count(OrderStatus.outForDelivery);
      });
    } on OrderApiException {
      // Leave the last-known/zero order counts in place.
    }
    if (!mounted) return;
    setState(() {
      _recentBills = _paymentsController.history
          .take(3)
          .toList(growable: false);
    });
  }

  Future<void> _loadReportSummary() async {
    if (_selectedBranchId == 'unavailable') return;
    final String requestedBranchId = _selectedBranchId;
    try {
      final ReportSummary summary = await _reportDataSource.loadSummary(
        const ReportQuery.period(ReportPeriod.sevenDays),
      );
      if (!mounted || requestedBranchId != _selectedBranchId) return;
      setState(() => _dashboardReportSummary = summary);
    } on Object {
      if (!mounted || requestedBranchId != _selectedBranchId) return;
      setState(() => _dashboardReportSummary = null);
    }
  }

  Future<void> _loadExpenseMetrics() async {
    if (_selectedBranchId == 'unavailable') return;
    final String requestedBranchId = _selectedBranchId;
    if (mounted) {
      setState(() {
        _expensesLoading = true;
        _expenseError = null;
      });
    }
    try {
      final ExpenseStatistics statistics = await _expenseApiService
          .getStatistics();
      if (!mounted || requestedBranchId != _selectedBranchId) return;
      setState(() {
        _totalExpenses = statistics.totalAmount;
        _expenseCount = statistics.count;
        _expensesLoading = false;
      });
    } on Object catch (error) {
      if (!mounted || requestedBranchId != _selectedBranchId) return;
      setState(() {
        _expensesLoading = false;
        _expenseError = error is ExpenseApiException
            ? error.message
            : 'Unable to load expenses.';
      });
    }
  }

  Future<void> _loadBranchPerformance() async {
    if (_selectedBranchId == 'unavailable') return;
    if (mounted) {
      setState(() {
        _branchPerformanceLoading = true;
        _branchPerformanceError = null;
      });
    }
    try {
      final BranchPerformanceReport report = await _reportDataSource
          .loadBranchPerformance(
            const ReportQuery.period(ReportPeriod.sevenDays),
          );
      if (!mounted) return;
      final List<DashboardBranchPerformance> performances = report.branches
          .map(
            (BranchPerformanceRecord branch) => DashboardBranchPerformance(
              branchCode: branch.branchCode,
              branchId: branch.branchId,
              name: branch.branchName,
              ordersLabel: '${branch.metrics.orders} orders',
              progress: (branch.metrics.revenueSharePercentage / 100).clamp(
                0,
                1,
              ),
              revenueLabel: formatOrderMoney(branch.metrics.revenue),
            ),
          )
          .toList(growable: false);
      final List<DashboardBranchPerformance> orderedPerformances =
          alignBranchPerformanceToBranchOrder(
            branchIds: _branches.map((DashboardData branch) => branch.branchId),
            performances: performances,
          );
      setState(() {
        _branchPerformance = orderedPerformances;
        _branchPerformanceLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _branchPerformanceLoading = false;
        _branchPerformanceError = 'Unable to load branch performance.';
      });
    }
  }

  void _showUiOnlyMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openNewOrder() async {
    final DashboardData data = _data;
    if (data.branchId == 'unavailable') {
      _showUiOnlyMessage('Select an active branch before creating an order.');
      return;
    }
    final NewOrderController controller = NewOrderController(
      catalogService: OrderCatalogApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
      orderController: _orderController,
      paymentService: PaymentApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
      branchId: data.branchId,
    );
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NewOrderScreen(
          controller: controller,
          orderController: _orderController,
          customerController: _customerController,
          businessName: data.businessName,
          branchName: data.branchName,
        ),
      ),
    );
    controller.dispose();
    if (created == true) await _orderController.load();
  }

  /// Opens the existing Payments screen, reusing the same scoped-controller
  /// navigation pattern already used by [MoreScreen] and Customer Profile's
  /// "View Payment History" — not a new route or duplicate screen.
  Future<void> _openPayments() async {
    final DashboardData data = _data;
    if (data.branchId == 'unavailable') {
      _showUiOnlyMessage('Select an active branch before viewing payments.');
      return;
    }
    final PaymentApiService paymentService = PaymentApiService(
      tokenStorage: AuthenticationDependencies.tokenStorage,
    )..selectBranch(data.branchId);
    final PaymentsController controller = PaymentsController(
      paymentService: paymentService,
      orderController: _orderController,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentsScreen(controller: controller),
      ),
    );
    controller.dispose();
    // A payment may have been collected while on the Payments screen —
    // refresh so revenue/outstanding/bills reflect it immediately.
    unawaited(_loadDashboardMetrics());
  }

  void _openOrdersTab() => setState(() => _currentNavigationIndex = 1);

  Future<void> _openSearchOrder(Order order) async {
    _searchController.clear();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            OrderDetailsScreen(orderId: order.id, controller: _orderController),
      ),
    );
    unawaited(_loadRecentOrders());
    unawaited(_loadDashboardMetrics());
  }

  Future<void> _openSearchCustomer(Customer customer) async {
    _searchController.clear();
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CustomerDetailsScreen(
          customerId: customer.id,
          controller: _customerController,
          accessPolicy: const AccessPolicy(roleCode: 'Owner'),
        ),
      ),
    );
    if (changed == true) {
      await _customerController.load();
      unawaited(_loadDashboardMetrics());
    }
  }

  Future<void> _openSearchPayment(PaymentRecord _) async {
    _searchController.clear();
    await _openPayments();
  }

  /// Overlays real backend-derived values (revenue, KPIs, business summary,
  /// recent orders/bills) onto the selected branch's [DashboardData],
  /// reusing [_paymentsController]/[_orderController]/[_customerController]
  /// — the same controllers already backing the Payments, Orders, and
  /// Customers screens. Metrics with no backend source (Delayed Orders,
  /// Branch Summary) are left at their existing
  /// zero/"Unavailable" state.
  DashboardData _buildDashboardData(BuildContext context) {
    final DashboardData base = _data;
    final List<DashboardOrder> orders = _recentOrders
        .map((Order order) => _toDashboardOrder(context, order))
        .toList(growable: false);
    if (base.branchId == 'unavailable') {
      return base.copyWith(
        branchPerformance: _branchPerformance,
        orders: orders,
      );
    }
    final List<DashboardBill> bills = _recentBills
        .map((PaymentRecord payment) => _toDashboardBill(context, payment))
        .toList(growable: false);
    final double? percentChange =
        _paymentsController.todayVsYesterdayPercentChange;
    final String revenueChange = percentChange == null
        ? '0%'
        : '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%';
    final String revenueComparison = percentChange == null
        ? 'No payments collected yesterday'
        : 'vs yesterday';
    final List<DashboardMetric> kpis = <DashboardMetric>[
      DashboardMetric(
        type: DashboardMetricType.orders,
        label: "Today's Orders",
        value: '$_todayOrdersCount',
        supportingText: _orderDeltaLabel(
          _todayOrdersCount,
          _yesterdayOrdersCount,
        ),
      ),
      DashboardMetric(
        type: DashboardMetricType.payments,
        label: 'Payments',
        value: formatOrderMoney(_paymentsController.todayCollected),
        supportingText: _paymentsController.todayCollectedCount == 1
            ? '1 collected'
            : '${_paymentsController.todayCollectedCount} collected',
      ),
      DashboardMetric(
        type: DashboardMetricType.expenses,
        label: 'Expenses',
        value: _expensesLoading || _expenseError != null
            ? '—'
            : formatOrderMoney(_totalExpenses),
        supportingText: _expensesLoading
            ? 'Loading...'
            : _expenseError != null
            ? 'Unable to load'
            : _expenseCount == 0
            ? 'No expenses recorded'
            : _expenseCount == 1
            ? '1 expense'
            : '$_expenseCount expenses',
      ),
      DashboardMetric(
        type: DashboardMetricType.outstanding,
        label: 'Outstanding',
        value: formatOrderMoney(_paymentsController.outstandingTotal),
        supportingText: _paymentsController.outstandingCustomerCount == 1
            ? '1 customer'
            : '${_paymentsController.outstandingCustomerCount} customers',
      ),
      DashboardMetric(
        type: DashboardMetricType.ready,
        label: 'Ready Orders',
        value: '$_readyOrdersCount',
        supportingText: 'Awaiting pickup',
      ),
      const DashboardMetric(
        type: DashboardMetricType.delayed,
        label: 'Delayed Orders',
        value: '—',
        supportingText: 'Not tracked',
      ),
    ];
    final List<DashboardMetric> summaryMetrics = <DashboardMetric>[
      DashboardMetric(
        type: DashboardMetricType.bills,
        label: 'Bills',
        value: '${_paymentsController.totalBillsCount}',
        supportingText: _paymentsController.paidBillsCount == 1
            ? '1 paid'
            : '${_paymentsController.paidBillsCount} paid',
      ),
      DashboardMetric(
        type: DashboardMetricType.customers,
        label: 'Customers',
        value: '${_customerController.total}',
        supportingText: _customerController.active == 1
            ? '1 active'
            : '${_customerController.active} active',
      ),
      DashboardMetric(
        type: DashboardMetricType.deliveries,
        label: 'Deliveries',
        value: '$_deliveriesCount',
        supportingText: _deliveriesCount == 1
            ? '1 out for delivery'
            : '$_deliveriesCount out for delivery',
      ),
    ];
    return base.copyWith(
      revenue: formatOrderMoney(_paymentsController.todayCollected),
      revenueChange: revenueChange,
      revenueComparison: revenueComparison,
      kpis: kpis,
      summaryMetrics: summaryMetrics,
      orders: orders,
      bills: bills,
      branchPerformance: _branchPerformance,
      revenuePoints:
          _dashboardReportSummary?.trend
              .map(
                (point) => DashboardRevenuePoint(
                  label: point.label,
                  value: point.revenue,
                ),
              )
              .toList(growable: false) ??
          const <DashboardRevenuePoint>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DashboardData data = _buildDashboardData(context);
    final bool showingDashboard = _currentNavigationIndex == 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: AppDurations.fast,
        child: switch (_currentNavigationIndex) {
          0 => CustomScrollView(
            key: const ValueKey<String>('dashboard'),
            physics: const ClampingScrollPhysics(),
            slivers: <Widget>[
              DashboardTopAppBar(
                ownerName: data.ownerName,
                unreadNotificationsCount: _notificationController.unreadCount,
                onNotificationsPressed: () => context.pushNamed(
                  AppRouteNames.notifications,
                  extra: _notificationController,
                ),
                onProfilePressed: () =>
                    context.pushNamed(AppRouteNames.profile),
              ),
              SliverToBoxAdapter(
                child: DashboardHeader(
                  data: data,
                  branches: _branches,
                  onBranchChanged: _selectBranch,
                  searchController: _searchController,
                  onOrderTap: (Order order) =>
                      unawaited(_openSearchOrder(order)),
                  onCustomerTap: (Customer customer) =>
                      unawaited(_openSearchCustomer(customer)),
                  onPaymentTap: (PaymentRecord payment) =>
                      unawaited(_openSearchPayment(payment)),
                ),
              ),
              SliverToBoxAdapter(
                child: OnlineRequestsCard(
                  key: ValueKey<String>('online-${data.branchId}'),
                  branch: ShopBranchArgs(
                    branchId: data.branchId,
                    branchName: data.branchName,
                    businessName: data.businessName,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: AppDurations.medium,
                  switchInCurve: AppCurves.easeOut,
                  child: KeyedSubtree(
                    key: ValueKey<String>(data.branchId),
                    child: _DashboardContent(
                      data: data,
                      onUiAction: _showUiOnlyMessage,
                      onNewOrder: _openNewOrder,
                      onOpenPayments: _openPayments,
                      onOpenReports: () =>
                          setState(() => _currentNavigationIndex = 5),
                      branchPerformanceError: _branchPerformanceError,
                      branchPerformanceLoading: _branchPerformanceLoading,
                      onRetryBranchPerformance: _loadBranchPerformance,
                      onSeeOrders: _openOrdersTab,
                      subscriptionStatus: _subscriptionStatus,
                      subscriptionLoading: _subscriptionLoading,
                      onOpenSubscription: () => unawaited(
                        context
                            .pushNamed(AppRouteNames.subscription)
                            .then((_) => _loadSubscriptionStatus()),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          1 => OrdersScreen(
            key: const ValueKey<String>('orders'),
            controller: _orderController,
            onNewOrder: _openNewOrder,
          ),
          2 => CustomerListScreen(
            key: const ValueKey<String>('customers'),
            controller: _customerController,
            accessPolicy: const AccessPolicy(roleCode: 'Owner'),
          ),
          4 => ExpenseListScreen(
            key: const ValueKey<String>('expenses'),
            branchId: data.branchId,
            onExpensesChanged: () => unawaited(_loadExpenseMetrics()),
            onBack: () => setState(() => _currentNavigationIndex = 3),
          ),
          5 => ReportsScreen(
            key: const ValueKey<String>('reports'),
            branchId: data.branchId,
            onBack: () => setState(() => _currentNavigationIndex = 3),
          ),
          _ => MoreScreen(
            key: const ValueKey<String>('more'),
            businessName: data.businessName,
            onExpensesTap: () => setState(() => _currentNavigationIndex = 4),
            onReportsTap: () => setState(() => _currentNavigationIndex = 5),
            role: 'Owner',
            userProfile: MoreUserProfileData(
              name: data.ownerName,
              email: data.ownerEmail,
            ),
            branchId: data.branchId,
            orderController: _orderController,
            accessPolicy: const AccessPolicy(roleCode: 'Owner'),
          ),
        },
      ),
      floatingActionButton: showingDashboard
          ? FloatingActionButton(
              onPressed: _openNewOrder,
              tooltip: 'Create new order',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: const CircleBorder(),
              child: const Icon(AppIcons.add),
            )
          : null,
      bottomNavigationBar: DashboardBottomNavigation(
        currentIndex:
            _currentNavigationIndex == 4 || _currentNavigationIndex == 5
            ? 3
            : _currentNavigationIndex,
        onTap: (int index) {
          final bool returningToDashboard =
              index == 0 && _currentNavigationIndex != 0;
          setState(() => _currentNavigationIndex = index);
          if (returningToDashboard) {
            // Re-fetch so revenue/outstanding reflect any payment collected
            // while the user was on another tab (e.g. Payments, Customers).
            unawaited(
              Future.wait<void>(<Future<void>>[
                _loadRecentOrders(),
                _loadDashboardMetrics(),
              ]),
            );
          }
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.branchPerformanceError,
    required this.branchPerformanceLoading,
    required this.data,
    required this.onUiAction,
    required this.onNewOrder,
    required this.onOpenPayments,
    required this.onOpenReports,
    required this.onRetryBranchPerformance,
    required this.onSeeOrders,
    required this.subscriptionStatus,
    required this.subscriptionLoading,
    required this.onOpenSubscription,
  });

  final DashboardData data;
  final String? branchPerformanceError;
  final bool branchPerformanceLoading;
  final ValueChanged<String> onUiAction;
  final VoidCallback onNewOrder;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenReports;
  final Future<void> Function() onRetryBranchPerformance;
  final VoidCallback onSeeOrders;
  final TenantSubscriptionStatus? subscriptionStatus;
  final bool subscriptionLoading;
  final VoidCallback onOpenSubscription;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizes.authenticationContentMaxWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.xxl,
            AppSpacing.pageHorizontal,
            AppSpacing.header,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              RevenueCard(data: data),
              const SizedBox(height: AppSpacing.lg),
              SubscriptionStatusCard(
                status: subscriptionStatus,
                loading: subscriptionLoading,
                onTap: onOpenSubscription,
              ),
              const SizedBox(height: AppSpacing.lg),
              _KpiGrid(metrics: data.kpis),
              const SizedBox(height: AppSpacing.sectionGapLarge),
              const DashboardSectionHeader(title: 'Business Summary'),
              const SizedBox(height: AppSpacing.lg),
              BusinessSummaryCard(metrics: data.summaryMetrics),
              const SizedBox(height: AppSpacing.sectionGapLarge),
              DashboardSectionHeader(
                title: 'Branch Performance',
                actionLabel: 'Reports',
                onAction: onOpenReports,
              ),
              const SizedBox(height: AppSpacing.md),
              _BranchPerformanceBody(
                error: branchPerformanceError,
                isLoading: branchPerformanceLoading,
                onRetry: onRetryBranchPerformance,
                performances: data.branchPerformance,
              ),
              const SizedBox(height: AppSpacing.md),
              const DashboardSectionHeader(title: 'Quick Actions'),
              const SizedBox(height: AppSpacing.lg),
              _QuickActionsGrid(
                actions: data.quickActions,
                onTap: (DashboardQuickAction action) => switch (action.type) {
                  DashboardQuickActionType.newOrder => onNewOrder(),
                  DashboardQuickActionType.payment => onOpenPayments(),
                  DashboardQuickActionType.report => onOpenReports(),
                  _ => onUiAction('${action.label} action selected'),
                },
              ),
              const SizedBox(height: AppSpacing.sectionGapLarge),
              DashboardSectionHeader(
                title: 'Recent Orders',
                actionLabel: 'See all',
                onAction: onSeeOrders,
              ),
              const SizedBox(height: AppSpacing.md),
              if (data.orders.isEmpty)
                const AppEmptyState(
                  icon: AppIcons.orders,
                  title: 'No orders yet',
                  message: 'Recent orders for this branch will appear here.',
                )
              else
                ...data.orders.map(
                  (DashboardOrder order) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: RecentOrderCard(order: order),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              const SizedBox(height: AppSpacing.md),
              DashboardSectionHeader(
                title: 'Recent Activity',
                actionLabel: 'See all',
                onAction: () => onUiAction('Recent activity selected'),
              ),
              const SizedBox(height: AppSpacing.md),
              if (data.bills.isEmpty)
                const AppEmptyState(
                  icon: AppIcons.receipt,
                  title: 'No bills yet',
                  message: 'Recent bills for this branch will appear here.',
                )
              else
                ...data.bills.map(
                  (DashboardBill bill) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: RecentBillCard(bill: bill),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.metrics});

  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useSingleColumn =
            constraints.maxWidth < AppSizes.chartMedium * 2;
        final double width = useSingleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.lg) / 2;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: metrics
              .map(
                (DashboardMetric metric) => SizedBox(
                  width: width,
                  child: KpiCard(metric: metric),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _BranchPerformanceBody extends StatelessWidget {
  const _BranchPerformanceBody({
    required this.error,
    required this.isLoading,
    required this.onRetry,
    required this.performances,
  });

  final String? error;
  final bool isLoading;
  final Future<void> Function() onRetry;
  final List<DashboardBranchPerformance> performances;

  @override
  Widget build(BuildContext context) {
    if (isLoading && performances.isEmpty) {
      return const DashboardSurfaceCard(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null && performances.isEmpty) {
      return DashboardSurfaceCard(
        child: Column(
          children: <Widget>[
            Text(error!, style: AppTextStyles.bodySmall),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () => unawaited(onRetry()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (performances.isEmpty) {
      return const DashboardSurfaceCard(child: Text('No branches available.'));
    }
    return Column(
      children: performances.indexed
          .map(
            ((int, DashboardBranchPerformance) entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.$1 == performances.length - 1
                    ? AppSpacing.none
                    : AppSpacing.lg,
              ),
              child: BranchPerformanceCard(
                key: ValueKey<String>(entry.$2.branchId),
                performance: entry.$2,
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.actions, required this.onTap});

  final List<DashboardQuickAction> actions;
  final ValueChanged<DashboardQuickAction> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (actions.isEmpty) return const SizedBox.shrink();
        const double minimumCardWidth = 78;
        final double totalSpacing = AppSpacing.lg * (actions.length - 1);
        final bool fitsWithoutScrolling =
            constraints.maxWidth >=
            minimumCardWidth * actions.length + totalSpacing;
        final double cardWidth = fitsWithoutScrolling
            ? (constraints.maxWidth - totalSpacing) / actions.length
            : (constraints.maxWidth - AppSpacing.lg) / 2;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List<Widget>.generate(actions.length, (int index) {
              final DashboardQuickAction action = actions[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == actions.length - 1
                      ? AppSpacing.none
                      : AppSpacing.lg,
                ),
                child: SizedBox(
                  width: cardWidth,
                  child: QuickActionCard(
                    action: action,
                    onTap: () => onTap(action),
                  ),
                ),
              );
            }, growable: false),
          ),
        );
      },
    );
  }
}

/// Maps a real backend [Order] onto the existing [DashboardOrder] display
/// shape so [RecentOrderCard] can render it without any UI changes.
DashboardOrder _toDashboardOrder(BuildContext context, Order order) =>
    DashboardOrder(
      customerName: order.customer.name,
      orderNumber: compactOrderNumber(order.orderNumber),
      description: orderItemsSummary(order),
      amount: formatOrderMoney(order.grandTotal),
      timeLabel: formatOrderDate(context, order.createdAt),
      status: _dashboardStatus(order.status),
    );

DashboardStatus _dashboardStatus(OrderStatus status) => switch (status) {
  OrderStatus.draft ||
  OrderStatus.received ||
  OrderStatus.assigned ||
  OrderStatus.accepted => DashboardStatus.pending,
  OrderStatus.inProgress => DashboardStatus.processing,
  OrderStatus.ready || OrderStatus.outForDelivery => DashboardStatus.ready,
  OrderStatus.delivered => DashboardStatus.completed,
  OrderStatus.rejected ||
  OrderStatus.cancelled => DashboardStatus.cancelled,
};

/// Maps a real backend [PaymentRecord] onto the existing [DashboardBill]
/// display shape so [RecentBillCard] can render it without any UI changes.
DashboardBill _toDashboardBill(BuildContext context, PaymentRecord payment) =>
    DashboardBill(
      customerName: payment.customerName ?? 'Customer unavailable',
      billNumber: payment.orderNumber ?? payment.paymentNumber,
      amount: formatOrderMoney(payment.amount),
      dueLabel: formatOrderDate(context, payment.createdAt),
      status: switch (payment.status) {
        PaymentTransactionStatus.successful => DashboardStatus.completed,
        PaymentTransactionStatus.failed => DashboardStatus.cancelled,
        PaymentTransactionStatus.pending => DashboardStatus.pending,
      },
    );

/// Real "+N from yesterday" / "-N from yesterday" delta label for a
/// today-vs-yesterday count comparison, avoiding a fabricated percentage.
String _orderDeltaLabel(int today, int yesterday) {
  final int delta = today - yesterday;
  if (delta == 0) return 'Same as yesterday';
  return delta > 0 ? '+$delta from yesterday' : '$delta from yesterday';
}
