import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/reports/models/report_data.dart';

class ReportsTopBar extends StatelessWidget {
  const ReportsTopBar({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: AppSizes.topBar,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: const BoxDecoration(border: AppBorders.topBar),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: AppSizes.controlSmall,
                child: Material(
                  color: AppColors.surfaceMuted,
                  borderRadius: AppRadius.inputRadius,
                  child: InkWell(
                    borderRadius: AppRadius.inputRadius,
                    onTap: onBack,
                    child: const Icon(
                      AppIcons.arrowBack,
                      color: AppColors.textSecondary,
                      size: AppIconSizes.lg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Reports',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.ink,
                  fontSize: AppFontSizes.lg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReportPeriodSelector extends StatelessWidget {
  const ReportPeriodSelector({
    required this.onSelected,
    required this.selected,
    super.key,
  });

  final ValueChanged<ReportPeriod> onSelected;
  final ReportPeriod selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xs,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        itemCount: ReportPeriod.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final ReportPeriod period = ReportPeriod.values[index];
          final bool isSelected = period == selected;
          return Material(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: AppRadius.chipRadius,
            elevation: 0,
            shadowColor: isSelected
                ? AppColors.primaryOverlay25
                : AppColors.blackOverlay05,
            child: InkWell(
              borderRadius: AppRadius.chipRadius,
              onTap: () => onSelected(period),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.chipRadius,
                  boxShadow: isSelected ? AppShadows.selected : AppShadows.xs,
                ),
                child: Text(
                  period.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? AppColors.ink : AppColors.textMuted,
                    fontSize: AppFontSizes.sm,
                    fontWeight: isSelected
                        ? AppFontWeights.semibold
                        : AppFontWeights.medium,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ReportKpiGrid extends StatelessWidget {
  const ReportKpiGrid({required this.summary, super.key});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    final List<_ReportKpiData> metrics = <_ReportKpiData>[
      _ReportKpiData(
        background: AppColors.primarySurface,
        color: AppColors.primary,
        icon: AppIcons.trendingUp,
        label: 'Total Revenue',
        value: formatReportMoney(summary.totalRevenue),
        subtitle:
            '${_signedNumber(summary.revenueChange.toStringAsFixed(1), summary.revenueChange)}% vs previous period',
      ),
      _ReportKpiData(
        background: AppColors.successSurface,
        color: AppColors.successLight,
        icon: AppIcons.orders,
        label: 'Total Orders',
        value: '${summary.totalOrders}',
        subtitle:
            '${_signedNumber('${summary.orderChange}', summary.orderChange)} vs previous period',
      ),
      _ReportKpiData(
        background: AppColors.secondarySurface,
        color: AppColors.secondary,
        icon: AppIcons.payment,
        label: 'Collected',
        value: formatReportMoney(summary.collected),
        subtitle:
            '${summary.collectionRate.toStringAsFixed(1)}% collection rate',
      ),
      _ReportKpiData(
        background: AppColors.warningSurface,
        color: AppColors.warning,
        icon: AppIcons.money,
        label: 'Net Profit',
        value: formatReportMoney(summary.netProfit.abs()),
        subtitle: 'After expenses',
      ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = constraints.maxWidth < 280 ? 1 : 2;
        final double width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - AppSpacing.mdPlus) / 2;
        return Wrap(
          spacing: AppSpacing.mdPlus,
          runSpacing: AppSpacing.mdPlus,
          children: metrics
              .map(
                (_ReportKpiData metric) => SizedBox(
                  width: width,
                  height: 108,
                  child: _ReportKpiCard(data: metric),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class ReportChartCard extends StatelessWidget {
  const ReportChartCard({required this.child, required this.title, super.key});

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.ink,
              fontWeight: AppFontWeights.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class RevenueLineChart extends StatefulWidget {
  const RevenueLineChart({required this.points, super.key});

  final List<ReportTrendPoint> points;

  @override
  State<RevenueLineChart> createState() => _RevenueLineChartState();
}

class _RevenueLineChartState extends State<RevenueLineChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          const double left = 34;
          const double right = 4;
          const double top = 6;
          const double bottom = 25;
          final double chartWidth = constraints.maxWidth - left - right;
          final double chartHeight = constraints.maxHeight - top - bottom;
          final double axisMaximum = math.max(
            1,
            widget.points.fold<double>(
              0,
              (double maximum, ReportTrendPoint point) =>
                  math.max(maximum, point.revenue),
            ),
          );
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) {
              final double relative =
                  ((details.localPosition.dx - left) / chartWidth).clamp(0, 1);
              setState(() {
                _selectedIndex = widget.points.length == 1
                    ? 0
                    : (relative * (widget.points.length - 1)).round();
              });
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RevenueChartPainter(
                      points: widget.points,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                ),
                if (_selectedIndex case final int index)
                  Positioned(
                    left: math.min(
                      constraints.maxWidth - 122,
                      math.max(
                        38,
                        left +
                            (widget.points.length == 1
                                ? chartWidth / 2
                                : chartWidth *
                                      index /
                                      (widget.points.length - 1)) -
                            54,
                      ),
                    ),
                    top: math.max(
                      0,
                      top +
                          chartHeight *
                              (1 - widget.points[index].revenue / axisMaximum) -
                          48,
                    ),
                    child: _ChartTooltip(point: widget.points[index]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DailyOrdersChart extends StatelessWidget {
  const DailyOrdersChart({required this.points, super.key});

  final List<ReportTrendPoint> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      child: CustomPaint(painter: _OrdersChartPainter(points)),
    );
  }
}

class ServiceBreakdownCard extends StatelessWidget {
  const ServiceBreakdownCard({required this.services, super.key});

  final List<ReportServiceBreakdown> services;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.cardInsets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Service Breakdown',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.ink,
              fontWeight: AppFontWeights.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lgPlus),
          ...services.indexed.map(
            ((int, ReportServiceBreakdown) entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.$1 == services.length - 1
                    ? AppSpacing.none
                    : AppSpacing.lg,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          entry.$2.name,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textBody,
                            height: AppLineHeights.tight,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.$2.percentage}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.ink,
                          fontWeight: AppFontWeights.bold,
                          height: AppLineHeights.tight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: AppRadius.badgeRadius,
                    child: LinearProgressIndicator(
                      minHeight: AppSpacing.sm,
                      value: entry.$2.percentage / 100,
                      backgroundColor: AppColors.surfaceMuted,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportKpiData {
  const _ReportKpiData({
    required this.background,
    required this.color,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
  });

  final Color background;
  final Color color;
  final IconData icon;
  final String label;
  final String subtitle;
  final String value;
}

class _ReportKpiCard extends StatelessWidget {
  const _ReportKpiCard({required this.data});

  final _ReportKpiData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: data.background,
                  borderRadius: AppRadius.inputRadius,
                ),
                child: SizedBox.square(
                  dimension: AppSizes.controlSmall,
                  child: Icon(
                    data.icon,
                    color: data.color,
                    size: AppIconSizes.md,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.ink,
              fontSize: AppFontSizes.h4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.micro.copyWith(color: AppColors.textSubtle),
          ),
        ],
      ),
    );
  }
}

class _ChartTooltip extends StatelessWidget {
  const _ChartTooltip({required this.point});

  final ReportTrendPoint point;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.inputRadius,
        boxShadow: AppShadows.tooltip,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              point.label,
              style: AppTextStyles.captionBold.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Revenue : ${formatReportMoneyExact(point.revenue)}',
              style: AppTextStyles.micro.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

abstract class _BaseChartPainter extends CustomPainter {
  _BaseChartPainter();

  static const double left = 34;
  static const double right = 4;
  static const double top = 6;
  static const double bottom = 25;

  Rect chartRect(Size size) =>
      Rect.fromLTRB(left, top, size.width - right, size.height - bottom);

  void drawGrid(
    Canvas canvas,
    Size size, {
    required int divisions,
    required List<String> xLabels,
    required List<String> yLabels,
    bool centerXLabels = false,
  }) {
    final Rect rect = chartRect(size);
    final Paint grid = Paint()
      ..color = AppColors.borderSubtle
      ..strokeWidth = 1;
    for (int index = 0; index <= divisions; index++) {
      final double y = rect.bottom - rect.height * index / divisions;
      _drawDashedLine(
        canvas,
        Offset(rect.left, y),
        Offset(rect.right, y),
        grid,
      );
      _drawLabel(
        canvas,
        yLabels[index],
        Offset(rect.left - 6, y - 5),
        alignRight: true,
      );
    }
    for (int index = 0; index < xLabels.length; index++) {
      final double x = centerXLabels
          ? rect.left + rect.width * (index + 0.5) / xLabels.length
          : xLabels.length == 1
          ? rect.center.dx
          : rect.left + rect.width * index / (xLabels.length - 1);
      _drawDashedLine(
        canvas,
        Offset(x, rect.top),
        Offset(x, rect.bottom),
        grid,
      );
      _drawLabel(
        canvas,
        xLabels[index],
        Offset(x, rect.bottom + 7),
        centered: true,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dash = 3;
    const double gap = 3;
    final double distance = (end - start).distance;
    final Offset direction = (end - start) / distance;
    for (double offset = 0; offset < distance; offset += dash + gap) {
      canvas.drawLine(
        start + direction * offset,
        start + direction * math.min(offset + dash, distance),
        paint,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    bool alignRight = false,
    bool centered = false,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: AppTextStyles.micro.copyWith(
          color: AppColors.textSubtle,
          fontSize: AppFontSizes.xs,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final double dx = alignRight
        ? offset.dx - painter.width
        : centered
        ? offset.dx - painter.width / 2
        : offset.dx;
    painter.paint(canvas, Offset(dx, offset.dy));
  }
}

class _RevenueChartPainter extends _BaseChartPainter {
  _RevenueChartPainter({required this.points, required this.selectedIndex});

  final List<ReportTrendPoint> points;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = chartRect(size);
    final double axisMaximum = math.max(
      1,
      points.fold<double>(
        0,
        (double maximum, ReportTrendPoint point) =>
            math.max(maximum, point.revenue),
      ),
    );
    drawGrid(
      canvas,
      size,
      divisions: 4,
      xLabels: points.map((ReportTrendPoint point) => point.label).toList(),
      yLabels: List<String>.generate(
        5,
        (int index) => (axisMaximum * index / 4).round().toString(),
      ),
    );
    final List<Offset> offsets = points.indexed
        .map(
          ((int, ReportTrendPoint) entry) => Offset(
            points.length == 1
                ? rect.center.dx
                : rect.left + rect.width * entry.$1 / (points.length - 1),
            rect.bottom - rect.height * entry.$2.revenue / axisMaximum,
          ),
        )
        .toList(growable: false);
    final Path line = _smoothPath(offsets);
    final Path area = Path.from(line)
      ..lineTo(offsets.last.dx, rect.bottom)
      ..lineTo(offsets.first.dx, rect.bottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, rect.top),
          Offset(0, rect.bottom),
          <Color>[AppColors.primaryOverlay15, AppColors.primaryOverlay00],
        ),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (int index = 0; index < offsets.length; index++) {
      canvas.drawCircle(
        offsets[index],
        selectedIndex == index ? 5 : 3,
        Paint()..color = AppColors.primary,
      );
    }
  }

  Path _smoothPath(List<Offset> points) {
    final Path path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int index = 0; index < points.length - 1; index++) {
      final Offset current = points[index];
      final Offset next = points[index + 1];
      final double midpoint = (current.dx + next.dx) / 2;
      path.cubicTo(midpoint, current.dy, midpoint, next.dy, next.dx, next.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.selectedIndex != selectedIndex;
}

class _OrdersChartPainter extends _BaseChartPainter {
  _OrdersChartPainter(this.points);

  final List<ReportTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = chartRect(size);
    final int axisMaximum = math.max(
      1,
      points.fold<int>(
        0,
        (int maximum, ReportTrendPoint point) =>
            math.max(maximum, point.orders),
      ),
    );
    drawGrid(
      canvas,
      size,
      divisions: 4,
      xLabels: points.map((ReportTrendPoint point) => point.label).toList(),
      yLabels: List<String>.generate(
        5,
        (int index) => (axisMaximum * index / 4).round().toString(),
      ),
      centerXLabels: true,
    );
    final double slot = rect.width / points.length;
    final double barWidth = math.min(28, slot * 0.72);
    for (int index = 0; index < points.length; index++) {
      final double height = rect.height * points[index].orders / axisMaximum;
      final RRect bar = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          rect.left + slot * index + (slot - barWidth) / 2,
          rect.bottom - height,
          barWidth,
          height,
        ),
        topLeft: const Radius.circular(AppRadius.barChartTop),
        topRight: const Radius.circular(AppRadius.barChartTop),
      );
      canvas.drawRRect(bar, Paint()..color = AppColors.primaryLight);
    }
  }

  @override
  bool shouldRepaint(covariant _OrdersChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

String formatReportMoney(double amount) {
  if (amount >= 100000) {
    final String value = (amount / 100000).toStringAsFixed(2);
    return 'Rs. ${value.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}L';
  }
  if (amount >= 1000) {
    final String value = (amount / 1000).toStringAsFixed(1);
    return 'Rs. ${value.replaceFirst(RegExp(r'\.0$'), '')}k';
  }
  return 'Rs. ${amount.round()}';
}

String formatReportMoneyExact(double amount) {
  final String digits = amount.round().toString();
  final StringBuffer formatted = StringBuffer();
  for (int index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) formatted.write(',');
    formatted.write(digits[index]);
  }
  return 'Rs. $formatted';
}

String _signedNumber(String formatted, num value) =>
    value > 0 ? '+$formatted' : formatted;
