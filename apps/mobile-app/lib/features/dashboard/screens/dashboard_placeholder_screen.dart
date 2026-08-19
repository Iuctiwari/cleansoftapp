import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_list_screen.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_models.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_widgets.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/more_screen.dart';
import 'package:nexoraa_mobile/features/expenses/screens/expense_list_screen.dart';
import 'package:nexoraa_mobile/features/orders/controllers/new_order_controller.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/screens/new_order_screen.dart';
import 'package:nexoraa_mobile/features/orders/screens/orders_screen.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/order_catalog_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';
import 'package:nexoraa_mobile/features/tenant/services/tenant_api_service.dart';

/// Owner dashboard UI served by the existing dashboard route.
///
/// The historical class name is retained so the existing authentication and
/// routing flow does not need to change.
class DashboardPlaceholderScreen extends StatefulWidget {
  const DashboardPlaceholderScreen({
    this.tenantId,
    this.tenantApiService,
    super.key,
  });

  final String? tenantId;
  final TenantApiService? tenantApiService;

  @override
  State<DashboardPlaceholderScreen> createState() =>
      _DashboardPlaceholderScreenState();
}

class _DashboardPlaceholderScreenState
    extends State<DashboardPlaceholderScreen> {
  late final CustomerController _customerController;
  late final OrderController _orderController;
  int _currentNavigationIndex = 0;
  String _selectedBranchId = 'unavailable';
  List<Order> _recentOrders = const <Order>[];
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
    );
    final tenantId = widget.tenantId?.trim() ?? '';
    if (tenantId.isNotEmpty) _loadTenantDashboard(tenantId);
  }

  @override
  void dispose() {
    _customerController.dispose();
    _orderController.dispose();
    super.dispose();
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
      });
      await _customerController.selectBranch(branches.first.branchId);
      await _orderController.selectBranch(branches.first.branchId);
      await _loadRecentOrders();
    } on Object {
      // The zero/unavailable dashboard remains visible when data cannot load.
    }
  }

  void _selectBranch(String branchId) {
    setState(() {
      _selectedBranchId = branchId;
      _recentOrders = const <Order>[];
    });
    _customerController.selectBranch(branchId);
    _orderController.selectBranch(branchId);
    unawaited(_loadRecentOrders());
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

  void _openOrdersTab() => setState(() => _currentNavigationIndex = 1);

  @override
  Widget build(BuildContext context) {
    final DashboardData data = _data.copyWith(
      orders: _recentOrders
          .map((Order order) => _toDashboardOrder(context, order))
          .toList(growable: false),
    );
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
                onNotificationsPressed: () =>
                    context.pushNamed(AppRouteNames.notifications),
                onProfilePressed: () => _showUiOnlyMessage('Profile selected'),
              ),
              SliverToBoxAdapter(
                child: DashboardHeader(
                  data: data,
                  branches: _branches,
                  onBranchChanged: _selectBranch,
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
                      onSeeOrders: _openOrdersTab,
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
          ),
          4 => ExpenseListScreen(
            key: const ValueKey<String>('expenses'),
            onBack: () => setState(() => _currentNavigationIndex = 3),
          ),
          _ => MoreScreen(
            key: const ValueKey<String>('more'),
            businessName: data.businessName,
            onExpensesTap: () => setState(() => _currentNavigationIndex = 4),
            role: 'Owner',
            userProfile: MoreUserProfileData(
              name: data.ownerName,
              email: data.ownerEmail,
            ),
            branchId: data.branchId,
            orderController: _orderController,
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
        currentIndex: _currentNavigationIndex == 4
            ? 3
            : _currentNavigationIndex,
        onTap: (int index) {
          setState(() => _currentNavigationIndex = index);
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.onUiAction,
    required this.onNewOrder,
    required this.onSeeOrders,
  });

  final DashboardData data;
  final ValueChanged<String> onUiAction;
  final VoidCallback onNewOrder;
  final VoidCallback onSeeOrders;

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
              _KpiGrid(metrics: data.kpis),
              const SizedBox(height: AppSpacing.sectionGapLarge),
              const DashboardSectionHeader(title: 'Business Summary'),
              const SizedBox(height: AppSpacing.lg),
              BusinessSummaryCard(metrics: data.summaryMetrics),
              const SizedBox(height: AppSpacing.sectionGapLarge),
              DashboardSectionHeader(
                title: 'Branch Performance',
                actionLabel: 'Reports',
                onAction: () => onUiAction('Reports action selected'),
              ),
              const SizedBox(height: AppSpacing.md),
              ...data.branchPerformance.map(
                (DashboardBranchPerformance performance) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: BranchPerformanceCard(performance: performance),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const DashboardSectionHeader(title: 'Quick Actions'),
              const SizedBox(height: AppSpacing.lg),
              _QuickActionsGrid(
                actions: data.quickActions,
                onTap: (DashboardQuickAction action) =>
                    action.type == DashboardQuickActionType.newOrder
                    ? onNewOrder()
                    : onUiAction('${action.label} action selected'),
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
  OrderStatus.draft || OrderStatus.received => DashboardStatus.pending,
  OrderStatus.inProgress => DashboardStatus.processing,
  OrderStatus.ready || OrderStatus.outForDelivery => DashboardStatus.ready,
  OrderStatus.delivered => DashboardStatus.completed,
  OrderStatus.cancelled => DashboardStatus.cancelled,
};
