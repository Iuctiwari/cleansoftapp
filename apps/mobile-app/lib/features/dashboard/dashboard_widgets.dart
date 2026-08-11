import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_models.dart';

class DashboardTopAppBar extends StatelessWidget {
  const DashboardTopAppBar({
    required this.onNotificationsPressed,
    required this.ownerName,
    this.onBackPressed,
    this.onProfilePressed,
    super.key,
  });

  final VoidCallback? onBackPressed;
  final VoidCallback onNotificationsPressed;
  final VoidCallback? onProfilePressed;
  final String ownerName;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      toolbarHeight: AppSizes.topBar,
      backgroundColor: AppColors.primaryDark,
      foregroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
      leading: onBackPressed == null
          ? null
          : IconButton(
              onPressed: onBackPressed,
              icon: const Icon(AppIcons.arrowBack),
              tooltip: 'Back',
            ),
      title: Text(
        'Dashboard',
        style: AppTextStyles.title.copyWith(color: AppColors.surface),
      ),
      actions: <Widget>[
        DashboardHeaderAction(
          onPressed: onNotificationsPressed,
          tooltip: 'Notifications',
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              const Icon(AppIcons.notifications, size: AppIconSizes.lg),
              Positioned(
                right: -AppSpacing.xxs,
                top: -AppSpacing.xxs,
                child: Container(
                  width: AppSpacing.md,
                  height: AppSpacing.md,
                  decoration: const BoxDecoration(
                    color: AppColors.errorLight,
                    shape: BoxShape.circle,
                    border: AppBorders.toggle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          child: DashboardHeaderAction(
            onPressed: onProfilePressed,
            tooltip: 'Owner profile for $ownerName',
            child: Text(
              ownerName.substring(0, 1).toUpperCase(),
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.surface,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardHeaderAction extends StatelessWidget {
  const DashboardHeaderAction({
    required this.child,
    required this.tooltip,
    this.onPressed,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: AppRadius.inputRadius,
            onTap: onPressed,
            child: Ink(
              width: AppSizes.controlMediumLarge,
              height: AppSizes.controlMediumLarge,
              decoration: const BoxDecoration(
                color: AppColors.whiteOverlay15,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.whiteOverlay30),
                ),
                borderRadius: AppRadius.inputRadius,
                boxShadow: AppShadows.subtle,
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.data,
    required this.branches,
    required this.onBranchChanged,
    super.key,
  });

  final List<DashboardData> branches;
  final DashboardData data;
  final ValueChanged<String> onBranchChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.primaryHeader),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: -AppSpacing.display,
            top: -AppSpacing.display,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.whiteOverlay08,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: AppSizes.loginHeaderDecoration),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.lg,
              AppSpacing.xxl,
              AppSpacing.xxlPlus,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Good morning 👋',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.whiteOverlay70,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            data.ownerName,
                            style: AppTextStyles.headingExtraLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Owner · ${data.businessName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.headerSubtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                const DashboardSearchBar(),
                const SizedBox(height: AppSpacing.lg),
                BranchDropdown(
                  branches: branches,
                  selectedBranchId: data.branchId,
                  onChanged: onBranchChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OwnerProfile extends StatelessWidget {
  const OwnerProfile({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Owner profile for $name',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: SizedBox.square(
          dimension: AppSizes.avatarExtraLarge,
          child: Center(
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: AppTextStyles.subtitle.copyWith(color: AppColors.surface),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardSearchBar extends StatelessWidget {
  const DashboardSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: 'Search dashboard',
      child: Container(
        height: AppSizes.buttonLargeHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.whiteOverlay15,
          borderRadius: AppRadius.inputRadius,
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.whiteOverlay30),
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              AppIcons.search,
              color: AppColors.whiteOverlay70,
              size: AppIconSizes.lg,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              'Search orders, customers...',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.whiteOverlay70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BranchDropdown extends StatefulWidget {
  const BranchDropdown({
    required this.branches,
    required this.selectedBranchId,
    required this.onChanged,
    super.key,
  });

  final List<DashboardData> branches;
  final ValueChanged<String> onChanged;
  final String selectedBranchId;

  @override
  State<BranchDropdown> createState() => _BranchDropdownState();
}

class _BranchDropdownState extends State<BranchDropdown> {
  bool _isOpen = false;

  DashboardData get _selectedBranch => widget.branches.firstWhere(
    (DashboardData branch) => branch.branchId == widget.selectedBranchId,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double menuWidth = constraints.maxWidth;
        return MenuAnchor(
          alignmentOffset: const Offset(AppSpacing.none, AppSpacing.sm),
          crossAxisUnconstrained: false,
          onClose: () => setState(() => _isOpen = false),
          onOpen: () => setState(() => _isOpen = true),
          style: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll<Color>(
              AppColors.surface,
            ),
            elevation: const WidgetStatePropertyAll<double>(AppSpacing.sm),
            maximumSize: WidgetStatePropertyAll<Size>(
              Size(menuWidth, double.infinity),
            ),
            minimumSize: WidgetStatePropertyAll<Size>(Size(menuWidth, 0)),
            padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
              EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
            shadowColor: const WidgetStatePropertyAll<Color>(
              AppColors.blackOverlay10,
            ),
            shape: const WidgetStatePropertyAll<OutlinedBorder>(
              RoundedRectangleBorder(
                borderRadius: AppRadius.inputRadius,
                side: AppBorders.primarySide,
              ),
            ),
          ),
          menuChildren: widget.branches
              .map((DashboardData branch) {
                final bool selected =
                    branch.branchId == widget.selectedBranchId;
                return MenuItemButton(
                  onPressed: () {
                    if (!selected) widget.onChanged(branch.branchId);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                      Set<WidgetState> states,
                    ) {
                      if (selected) return AppColors.primarySurface;
                      if (states.contains(WidgetState.pressed)) {
                        return AppColors.surfaceMuted;
                      }
                      if (states.contains(WidgetState.hovered)) {
                        return AppColors.primarySurfaceAlt;
                      }
                      return AppColors.transparent;
                    }),
                    foregroundColor: const WidgetStatePropertyAll<Color>(
                      AppColors.textPrimary,
                    ),
                    fixedSize: WidgetStatePropertyAll<Size>(
                      Size(menuWidth, AppSizes.buttonLargeHeight),
                    ),
                    minimumSize: const WidgetStatePropertyAll<Size>(
                      Size.fromHeight(AppSizes.buttonLargeHeight),
                    ),
                    padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
                      EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.md,
                      ),
                    ),
                    shape: const WidgetStatePropertyAll<OutlinedBorder>(
                      RoundedRectangleBorder(
                        borderRadius: AppRadius.inputRadius,
                      ),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        AppIcons.branch,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textMuted,
                        size: AppIconSizes.lg,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Text(
                          branch.branchName,
                          overflow: TextOverflow.ellipsis,
                          style: selected
                              ? AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: AppFontWeights.semibold,
                                )
                              : AppTextStyles.bodyMedium,
                        ),
                      ),
                      if (selected) ...<Widget>[
                        const SizedBox(width: AppSpacing.md),
                        const Icon(
                          AppIcons.brandCheck,
                          color: AppColors.primary,
                          size: AppIconSizes.lg,
                        ),
                      ],
                    ],
                  ),
                );
              })
              .toList(growable: false),
          builder:
              (BuildContext context, MenuController controller, Widget? child) {
                return AnimatedContainer(
                  duration: AppDurations.fast,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: _isOpen
                        ? AppBorders.inputFocused
                        : AppBorders.primaryCard,
                    borderRadius: AppRadius.inputRadius,
                    boxShadow: _isOpen ? AppShadows.selected : AppShadows.small,
                  ),
                  child: Material(
                    color: AppColors.transparent,
                    borderRadius: AppRadius.inputRadius,
                    child: InkWell(
                      borderRadius: AppRadius.inputRadius,
                      onTap: () {
                        controller.isOpen
                            ? controller.close()
                            : controller.open();
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: AppSizes.buttonLargeHeight,
                        ),
                        child: Padding(
                          padding: AppSpacing.inputInsets,
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                AppIcons.branch,
                                color: AppColors.primary,
                                size: AppIconSizes.lg,
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: AppDurations.fast,
                                  child: Text(
                                    _selectedBranch.branchName,
                                    key: ValueKey<String>(
                                      widget.selectedBranchId,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              AnimatedRotation(
                                turns: _isOpen ? 0.5 : 0,
                                duration: AppDurations.fast,
                                child: const Icon(
                                  AppIcons.chevronDown,
                                  color: AppColors.primary,
                                  size: AppIconSizes.lg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
        );
      },
    );
  }
}

class RevenueCard extends StatelessWidget {
  const RevenueCard({required this.data, super.key});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final bool isPositive = !data.revenueChange.startsWith('-');
    return Container(
      padding: AppSpacing.cardInsets,
      decoration: const BoxDecoration(
        gradient: AppGradients.darkCard,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.medium,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  "TODAY'S REVENUE",
                  style: AppTextStyles.labelUppercase,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(data.revenue, style: AppTextStyles.displayMedium),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: isPositive
                            ? AppColors.successOverlay15
                            : AppColors.errorSurface,
                        borderRadius: AppRadius.badgeRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.mdPlus,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          '${isPositive ? '↗' : '↘'} ${data.revenueChange}',
                          style: AppTextStyles.badge.copyWith(
                            color: isPositive
                                ? AppColors.successLight
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      data.revenueComparison,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.primaryOverlay45,
              borderRadius: BorderRadius.all(
                Radius.circular(AppRadius.iconContainerLarge),
              ),
            ),
            child: const SizedBox.square(
              dimension: AppSizes.heroIcon,
              child: Icon(
                AppIcons.wallet,
                color: AppColors.primaryLight,
                size: AppIconSizes.xl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({required this.metric, super.key});

  final DashboardMetric metric;

  @override
  Widget build(BuildContext context) {
    final _MetricVisual visual = _metricVisual(metric.type);
    return DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _IconBox(
                icon: visual.icon,
                color: visual.color,
                background: visual.background,
              ),
              const SizedBox(width: AppSpacing.mdPlus),
              Expanded(
                child: Text(
                  metric.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(metric.value, style: AppTextStyles.headingLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(metric.supportingText, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class DashboardSurfaceCard extends StatelessWidget {
  const DashboardSurfaceCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? AppSpacing.cardInsets,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: AppBorders.cardDefault,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String? actionLabel;
  final VoidCallback? onAction;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: AppTextStyles.headingSmall)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class BusinessSummaryCard extends StatelessWidget {
  const BusinessSummaryCard({required this.metrics, super.key});

  final List<DashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      child: Row(
        children: metrics.indexed
            .map(((int, DashboardMetric) entry) {
              final DashboardMetric metric = entry.$2;
              final _MetricVisual visual = _metricVisual(metric.type);
              return Expanded(
                child: Container(
                  padding: EdgeInsets.only(
                    left: entry.$1 == 0 ? AppSpacing.none : AppSpacing.lg,
                    right: entry.$1 == metrics.length - 1
                        ? AppSpacing.none
                        : AppSpacing.lg,
                  ),
                  decoration: entry.$1 == metrics.length - 1
                      ? null
                      : const BoxDecoration(
                          border: Border(right: AppBorders.sectionDividerSide),
                        ),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        visual.icon,
                        color: visual.color,
                        size: AppIconSizes.lg,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(metric.value, style: AppTextStyles.subtitle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        metric.label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.captionBold,
                      ),
                      Text(
                        metric.supportingText,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.micro,
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class BranchSummaryCard extends StatelessWidget {
  const BranchSummaryCard({required this.summary, super.key});

  final DashboardBranchSummary summary;

  @override
  Widget build(BuildContext context) {
    final List<(String, String)> items = <(String, String)>[
      ('Manager', summary.manager),
      ('Team', summary.teamSize),
      ('Open orders', summary.openOrders),
      ('Today', summary.completedToday),
    ];
    return DashboardSurfaceCard(
      child: Wrap(
        spacing: AppSpacing.xxl,
        runSpacing: AppSpacing.xl,
        children: items
            .map(
              ((String, String) item) => SizedBox(
                width: AppSizes.chartMedium,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.$1, style: AppTextStyles.caption),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class RevenueOverviewCard extends StatelessWidget {
  const RevenueOverviewCard({required this.points, super.key});

  final List<DashboardRevenuePoint> points;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      child: SizedBox(
        height: AppSizes.chartMedium,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: points
              .map(
                (DashboardRevenuePoint point) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: point.value,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: AppGradients.primaryBar,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(AppRadius.barChartTop),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(point.label, style: AppTextStyles.micro),
                      ],
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class BranchPerformanceCard extends StatelessWidget {
  const BranchPerformanceCard({required this.performance, super.key});

  final DashboardBranchPerformance performance;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(performance.name, style: AppTextStyles.subtitle),
              ),
              const Icon(
                AppIcons.branch,
                color: AppColors.textSubtle,
                size: AppIconSizes.lg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${performance.ordersLabel} · ${performance.revenueLabel}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: AppRadius.circular,
            child: LinearProgressIndicator(
              value: performance.progress,
              minHeight: AppSpacing.sm,
              color: AppColors.primaryLight,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '${(performance.progress * 100).round()}% of selected branch revenue',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({required this.action, required this.onTap, super.key});

  final DashboardQuickAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _ActionVisual visual = _actionVisual(action.type);
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardRadius,
      child: DashboardSurfaceCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          children: <Widget>[
            _IconBox(
              icon: visual.icon,
              color: visual.color,
              background: visual.background,
              large: true,
            ),
            const SizedBox(height: AppSpacing.mdPlus),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.buttonSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class RecentOrderCard extends StatelessWidget {
  const RecentOrderCard({required this.order, super.key});

  final DashboardOrder order;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColor status = _statusColor(order.status);
    return DashboardSurfaceCard(
      child: Row(
        children: <Widget>[
          _Avatar(initials: order.initials),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(order.customerName, style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${order.orderNumber} · ${order.description}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(order.timeLabel, style: AppTextStyles.caption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(order.amount, style: AppTextStyles.subtitle),
              const SizedBox(height: AppSpacing.md),
              _StatusBadge(label: _statusLabel(order.status), colors: status),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentBillCard extends StatelessWidget {
  const RecentBillCard({required this.bill, super.key});

  final DashboardBill bill;

  @override
  Widget build(BuildContext context) {
    final AppSemanticColor status = _statusColor(bill.status);
    return DashboardSurfaceCard(
      child: Row(
        children: <Widget>[
          const _IconBox(
            icon: AppIcons.receipt,
            color: AppColors.secondary,
            background: AppColors.secondarySurface,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(bill.customerName, style: AppTextStyles.bodyLarge),
                Text(
                  '${bill.billNumber} · ${bill.dueLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(bill.amount, style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.md),
              _StatusBadge(label: _statusLabel(bill.status), colors: status),
            ],
          ),
        ],
      ),
    );
  }
}

class RecentCustomerCard extends StatelessWidget {
  const RecentCustomerCard({required this.customer, super.key});

  final DashboardCustomer customer;

  @override
  Widget build(BuildContext context) {
    return DashboardSurfaceCard(
      child: Row(
        children: <Widget>[
          _Avatar(initials: customer.initials),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(customer.name, style: AppTextStyles.bodyLarge),
                Text(customer.phone, style: AppTextStyles.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(customer.totalSpent, style: AppTextStyles.bodyLarge),
              Text(customer.ordersLabel, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({required this.activity, super.key});

  final DashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    final _ActivityVisual visual = _activityVisual(activity.type);
    return DashboardSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _IconBox(
            icon: visual.icon,
            color: visual.color,
            background: visual.background,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(activity.title, style: AppTextStyles.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(activity.description, style: AppTextStyles.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(activity.timeLabel, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardBottomNavigation extends StatelessWidget {
  const DashboardBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: AppBorders.bottomNavigation,
        boxShadow: AppShadows.subtle,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppSizes.bottomNavigation,
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTap,
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(AppIcons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.orders),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(AppIcons.users),
                label: 'Customers',
              ),
              BottomNavigationBarItem(icon: Icon(AppIcons.more), label: 'More'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.avatar(AppSizes.avatarHeadline),
      ),
      child: SizedBox.square(
        dimension: AppSizes.avatarHeadline,
        child: Center(
          child: Text(
            initials,
            style: AppTextStyles.subtitle.copyWith(color: AppColors.surface),
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    required this.color,
    required this.background,
    this.large = false,
  });

  final Color background;
  final Color color;
  final IconData icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.inputRadius,
      ),
      child: SizedBox.square(
        dimension: large ? AppSizes.touchTarget : AppSizes.controlMediumLarge,
        child: Icon(
          icon,
          color: color,
          size: large ? AppIconSizes.xl : AppIconSizes.lg,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.colors});
  final AppSemanticColor colors;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: AppRadius.badgeRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.mdPlus,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: AppTextStyles.badge.copyWith(color: colors.text),
        ),
      ),
    );
  }
}

class _MetricVisual {
  const _MetricVisual(this.icon, this.color, this.background);
  final Color background;
  final Color color;
  final IconData icon;
}

_MetricVisual _metricVisual(DashboardMetricType type) => switch (type) {
  DashboardMetricType.orders => const _MetricVisual(
    AppIcons.orders,
    AppColors.primary,
    AppColors.primarySurface,
  ),
  DashboardMetricType.payments => const _MetricVisual(
    AppIcons.payment,
    AppColors.successLight,
    AppColors.successSurface,
  ),
  DashboardMetricType.expenses => const _MetricVisual(
    AppIcons.arrowUpRight,
    AppColors.warning,
    AppColors.warningSurface,
  ),
  DashboardMetricType.outstanding => const _MetricVisual(
    AppIcons.alert,
    AppColors.errorLight,
    AppColors.errorSurface,
  ),
  DashboardMetricType.ready => const _MetricVisual(
    AppIcons.package,
    AppColors.successLight,
    AppColors.successSurface,
  ),
  DashboardMetricType.delayed => const _MetricVisual(
    AppIcons.clock,
    AppColors.errorLight,
    AppColors.errorSurface,
  ),
  DashboardMetricType.bills => const _MetricVisual(
    AppIcons.receipt,
    AppColors.secondary,
    AppColors.secondarySurface,
  ),
  DashboardMetricType.customers => const _MetricVisual(
    AppIcons.users,
    AppColors.info,
    AppColors.infoSurface,
  ),
  DashboardMetricType.deliveries => const _MetricVisual(
    AppIcons.delivery,
    AppColors.indigo,
    AppColors.indigoSurface,
  ),
};

class _ActionVisual extends _MetricVisual {
  const _ActionVisual(super.icon, super.color, super.background);
}

_ActionVisual _actionVisual(DashboardQuickActionType type) => switch (type) {
  DashboardQuickActionType.newOrder => const _ActionVisual(
    AppIcons.add,
    AppColors.primary,
    AppColors.primarySurface,
  ),
  DashboardQuickActionType.payment => const _ActionVisual(
    AppIcons.arrowUpRight,
    AppColors.successLight,
    AppColors.successSurface,
  ),
  DashboardQuickActionType.report => const _ActionVisual(
    AppIcons.analytics,
    AppColors.secondary,
    AppColors.secondarySurface,
  ),
  DashboardQuickActionType.assign => const _ActionVisual(
    AppIcons.refresh,
    AppColors.warning,
    AppColors.warningSurface,
  ),
};

class _ActivityVisual extends _MetricVisual {
  const _ActivityVisual(super.icon, super.color, super.background);
}

_ActivityVisual _activityVisual(DashboardActivityType type) => switch (type) {
  DashboardActivityType.order => const _ActivityVisual(
    AppIcons.orders,
    AppColors.primary,
    AppColors.primarySurface,
  ),
  DashboardActivityType.payment => const _ActivityVisual(
    AppIcons.payment,
    AppColors.success,
    AppColors.successSurface,
  ),
  DashboardActivityType.customer => const _ActivityVisual(
    AppIcons.addUser,
    AppColors.secondary,
    AppColors.secondarySurface,
  ),
  DashboardActivityType.delivery => const _ActivityVisual(
    AppIcons.delivery,
    AppColors.info,
    AppColors.infoSurface,
  ),
  DashboardActivityType.bill => const _ActivityVisual(
    AppIcons.receipt,
    AppColors.warning,
    AppColors.warningSurface,
  ),
};

String _statusLabel(DashboardStatus status) => switch (status) {
  DashboardStatus.ready => 'Ready',
  DashboardStatus.processing => 'Processing',
  DashboardStatus.pending => 'Pending',
  DashboardStatus.completed => 'Done',
  DashboardStatus.overdue => 'Overdue',
};

AppSemanticColor _statusColor(DashboardStatus status) => switch (status) {
  DashboardStatus.ready => SemanticColors.statusReady,
  DashboardStatus.processing => SemanticColors.statusProcessing,
  DashboardStatus.pending => SemanticColors.statusPending,
  DashboardStatus.completed => SemanticColors.statusCompleted,
  DashboardStatus.overdue => SemanticColors.statusError,
};
