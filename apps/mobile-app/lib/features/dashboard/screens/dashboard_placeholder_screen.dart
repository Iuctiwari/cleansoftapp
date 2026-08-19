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
  int _currentNavigationIndex = 0;
  String _selectedBranchId = 'unavailable';
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
    final tenantId = widget.tenantId?.trim() ?? '';
    if (tenantId.isNotEmpty) _loadTenantDashboard(tenantId);
  }

  @override
  void dispose() {
    _customerController.dispose();
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
    } on Object {
      // The zero/unavailable dashboard remains visible when data cannot load.
    }
  }

  void _selectBranch(String branchId) {
    setState(() => _selectedBranchId = branchId);
    _customerController.selectBranch(branchId);
  }

  void _showUiOnlyMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final DashboardData data = _data;
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
                onProfilePressed: () =>
                    context.pushNamed(AppRouteNames.profile),
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
                    ),
                  ),
                ),
              ),
            ],
          ),
          2 => CustomerListScreen(
            key: const ValueKey<String>('customers'),
            controller: _customerController,
          ),
          _ => MoreScreen(
            key: const ValueKey<String>('more'),
            businessName: data.businessName,
            role: 'Owner',
            userProfile: MoreUserProfileData(
              name: data.ownerName,
              email: data.ownerEmail,
            ),
          ),
        },
      ),
      floatingActionButton: showingDashboard
          ? FloatingActionButton(
              onPressed: () => _showUiOnlyMessage('New order action selected'),
              tooltip: 'Create new order',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: const CircleBorder(),
              child: const Icon(AppIcons.add),
            )
          : null,
      bottomNavigationBar: DashboardBottomNavigation(
        currentIndex: _currentNavigationIndex,
        onTap: (int index) {
          if (index == 0 || index == 2 || index == 3) {
            setState(() => _currentNavigationIndex = index);
            return;
          }
          const List<String> labels = <String>[
            'Dashboard',
            'Orders',
            'Customers',
            'More',
          ];
          _showUiOnlyMessage('${labels[index]} is outside this dashboard task');
        },
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.onUiAction});

  final DashboardData data;
  final ValueChanged<String> onUiAction;

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
                    onUiAction('${action.label} action selected'),
              ),
              const SizedBox(height: AppSpacing.sectionGapLarge),
              DashboardSectionHeader(
                title: 'Recent Orders',
                actionLabel: 'See all',
                onAction: () => onUiAction('Recent orders selected'),
              ),
              const SizedBox(height: AppSpacing.md),
              ...data.orders.map(
                (DashboardOrder order) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: RecentOrderCard(order: order),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DashboardSectionHeader(
                title: 'Recent Bills',
                actionLabel: 'See all',
                onAction: () => onUiAction('Recent bills selected'),
              ),
              const SizedBox(height: AppSpacing.md),
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
            children: List<Widget>.generate(
              actions.length,
              (int index) {
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
              },
              growable: false,
            ),
          ),
        );
      },
    );
  }
}
