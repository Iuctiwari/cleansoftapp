import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/reports/controllers/reports_controller.dart';
import 'package:nexoraa_mobile/features/reports/models/report_data.dart';
import 'package:nexoraa_mobile/features/reports/services/report_api_service.dart';
import 'package:nexoraa_mobile/features/reports/widgets/report_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    required this.branchId,
    required this.onBack,
    this.controller,
    super.key,
  });

  final String branchId;
  final ReportsController? controller;
  final VoidCallback onBack;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final ReportsController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        ReportsController(
          dataSource: ReportApiService(
            tokenStorage: AuthenticationDependencies.tokenStorage,
          ),
        );
    unawaited(_controller.selectBranch(widget.branchId, reload: false));
    unawaited(_controller.load());
  }

  @override
  void didUpdateWidget(covariant ReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branchId != widget.branchId) {
      unawaited(_controller.selectBranch(widget.branchId));
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: Column(
        children: <Widget>[
          ReportsTopBar(onBack: widget.onBack),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final ReportSummary? summary = _controller.summary;
                if (_controller.isLoading && summary == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_controller.errorMessage != null && summary == null) {
                  return AppErrorView(
                    message: _controller.errorMessage!,
                    onRetry: _controller.load,
                  );
                }
                if (summary == null || _controller.isEmpty) {
                  return const AppEmptyState(
                    icon: AppIcons.analytics,
                    title: 'No report data',
                    message: 'Report data will appear here when available.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: _controller.load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    children: <Widget>[
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.authenticationContentMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              ReportPeriodSelector(
                                selected: _controller.period,
                                onSelected: (ReportPeriod period) =>
                                    unawaited(_controller.load(period)),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.pageHorizontal,
                                  AppSpacing.xs,
                                  AppSpacing.pageHorizontal,
                                  AppSpacing.pageBottom,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    ReportKpiGrid(summary: summary),
                                    const SizedBox(height: AppSpacing.lg),
                                    if (summary.trend.isNotEmpty) ...<Widget>[
                                      ReportChartCard(
                                        title: _revenueTitle(
                                          _controller.period,
                                        ),
                                        child: RevenueLineChart(
                                          points: summary.trend,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      ReportChartCard(
                                        title: _ordersTitle(_controller.period),
                                        child: DailyOrdersChart(
                                          points: summary.trend,
                                        ),
                                      ),
                                    ],
                                    if (summary
                                        .serviceBreakdown
                                        .isNotEmpty) ...<Widget>[
                                      const SizedBox(height: AppSpacing.lg),
                                      ServiceBreakdownCard(
                                        services: summary.serviceBreakdown,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _revenueTitle(ReportPeriod period) => switch (period) {
  ReportPeriod.sevenDays => 'Revenue (Last 7 days)',
  ReportPeriod.thirtyDays => 'Revenue (Last 30 days)',
  ReportPeriod.threeMonths => 'Revenue (Last 3 months)',
  ReportPeriod.year => 'Revenue (Last year)',
};

String _ordersTitle(ReportPeriod period) => switch (period) {
  ReportPeriod.sevenDays || ReportPeriod.thirtyDays => 'Daily Orders',
  ReportPeriod.threeMonths => 'Weekly Orders',
  ReportPeriod.year => 'Monthly Orders',
};
