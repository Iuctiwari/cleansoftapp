import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_dummy_data.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_models.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_widgets.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/more_screen.dart';

/// Owner dashboard UI served by the existing dashboard route.
///
/// The historical class name is retained so the existing authentication and
/// routing flow does not need to change.
class DashboardPlaceholderScreen extends StatefulWidget {
  const DashboardPlaceholderScreen({super.key});

  @override
  State<DashboardPlaceholderScreen> createState() =>
      _DashboardPlaceholderScreenState();
}

class _DashboardPlaceholderScreenState
    extends State<DashboardPlaceholderScreen> {
  int _currentNavigationIndex = 0;
  String _selectedBranchId = DashboardDummyData.defaultBranchId;

  DashboardData get _data => DashboardDummyData.branch(_selectedBranchId);

  void _selectBranch(String branchId) {
    setState(() => _selectedBranchId = branchId);
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
        child: showingDashboard
            ? CustomScrollView(
                key: const ValueKey<String>('dashboard'),
                physics: const ClampingScrollPhysics(),
                slivers: <Widget>[
                  DashboardTopAppBar(
                    ownerName: data.ownerName,
                    onNotificationsPressed: () =>
                        context.pushNamed(AppRouteNames.notifications),
                    onProfilePressed: () =>
                        _showUiOnlyMessage('Profile selected'),
                  ),
                  SliverToBoxAdapter(
                    child: DashboardHeader(
                      data: data,
                      branches: DashboardDummyData.allBranches,
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
              )
            : MoreScreen(
                key: const ValueKey<String>('more'),
                businessName: data.businessName,
                role: 'Owner',
                userProfile: MoreUserProfileData.placeholder,
              ),
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
          if (index == 0 || index == 3) {
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
              const DashboardSectionHeader(title: 'Revenue Overview'),
              const SizedBox(height: AppSpacing.lg),
              RevenueOverviewCard(points: data.revenuePoints),
              const SizedBox(height: AppSpacing.sectionGapLarge),
              DashboardSectionHeader(title: '${data.branchName} Summary'),
              const SizedBox(height: AppSpacing.lg),
              BranchSummaryCard(summary: data.branchSummary),
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
              const SizedBox(height: AppSpacing.md),
              DashboardSectionHeader(
                title: 'Recent Customers',
                actionLabel: 'See all',
                onAction: () => onUiAction('Recent customers selected'),
              ),
              const SizedBox(height: AppSpacing.md),
              ...data.customers.map(
                (DashboardCustomer customer) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: RecentCustomerCard(customer: customer),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const DashboardSectionHeader(title: 'Recent Activities'),
              const SizedBox(height: AppSpacing.lg),
              ...data.activities.map(
                (DashboardActivity activity) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: ActivityCard(activity: activity),
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
        final int columns = constraints.maxWidth >= AppSizes.tabletBreakpoint
            ? 4
            : 2;
        final double width =
            (constraints.maxWidth - AppSpacing.lg * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: actions
              .map(
                (DashboardQuickAction action) => SizedBox(
                  width: width,
                  child: QuickActionCard(
                    action: action,
                    onTap: () => onTap(action),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}
