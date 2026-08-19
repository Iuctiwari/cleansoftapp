import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({
    required this.orderId,
    required this.controller,
    super.key,
  });

  final String orderId;
  final OrderController controller;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late Future<_OrderDetailsData> _details;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _details = _fetchDetails();

  Future<_OrderDetailsData> _fetchDetails() async {
    final List<Object> results = await Future.wait<Object>(<Future<Object>>[
      widget.controller.details(widget.orderId),
      widget.controller.history(widget.orderId),
    ]);
    return _OrderDetailsData(
      order: results[0] as Order,
      history: results[1] as List<OrderStatusHistory>,
    );
  }

  void _retry() => setState(_load);

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _call(Order order) async {
    final String? mobile = order.customer.mobile;
    if (mobile == null) return;
    await copyOrderCustomerMobile(mobile);
    _message('Customer number copied.');
  }

  Future<void> _whatsApp(Order order) async {
    await copyOrderShareText(order);
    _message('Order summary copied for WhatsApp sharing.');
  }

  Future<void> _markDelivered(Order order) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    try {
      await widget.controller.changeStatus(order.id, OrderStatus.delivered);
      if (!mounted) return;
      setState(_load);
      _message('Order marked as delivered.');
    } on OrderApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order Detail')),
    body: FutureBuilder<_OrderDetailsData>(
      future: _details,
      builder:
          (BuildContext context, AsyncSnapshot<_OrderDetailsData> snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AppLoadingView();
            }
            if (snapshot.hasError) {
              final Object error = snapshot.error!;
              return AppErrorView(
                message: error is OrderApiException
                    ? error.message
                    : 'Unable to load this order.',
                onRetry: _retry,
              );
            }
            final _OrderDetailsData data = snapshot.requireData;
            return _OrderDetailsContent(
              data: data,
              isUpdatingStatus: _isUpdatingStatus,
              onCall: () => unawaited(_call(data.order)),
              onWhatsApp: () => unawaited(_whatsApp(data.order)),
              onMarkDelivered: () => unawaited(_markDelivered(data.order)),
            );
          },
    ),
  );
}

class _OrderDetailsData {
  const _OrderDetailsData({required this.order, required this.history});

  final Order order;
  final List<OrderStatusHistory> history;
}

class _OrderDetailsContent extends StatelessWidget {
  const _OrderDetailsContent({
    required this.data,
    required this.isUpdatingStatus,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMarkDelivered,
  });

  final _OrderDetailsData data;
  final bool isUpdatingStatus;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onMarkDelivered;

  @override
  Widget build(BuildContext context) {
    final Order order = data.order;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double horizontalPadding =
            constraints.maxWidth >= AppSizes.tabletBreakpoint
            ? AppSpacing.section
            : AppSpacing.pageHorizontal;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.xl,
            horizontalPadding,
            AppSpacing.pageBottom,
          ),
          children: <Widget>[
            _OrderHeaderCard(
              order: order,
              onCall: order.customer.mobile == null ? null : onCall,
              onWhatsApp: onWhatsApp,
            ),
            const SizedBox(height: AppSpacing.lgPlus),
            _PaymentCard(order: order),
            const SizedBox(height: AppSpacing.lgPlus),
            _AssignmentCard(order: order),
            const SizedBox(height: AppSpacing.lgPlus),
            _TimelineCard(history: data.history, currentStatus: order.status),
            if (order.expectedDeliveryDate != null ||
                order.deliveryDate != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lgPlus),
              _DeliveryCard(order: order),
            ],
            const SizedBox(height: AppSpacing.lgPlus),
            _BottomActions(
              order: order,
              isUpdatingStatus: isUpdatingStatus,
              onWhatsApp: onWhatsApp,
              onMarkDelivered: onMarkDelivered,
            ),
          ],
        );
      },
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({
    required this.order,
    required this.onCall,
    required this.onWhatsApp,
  });

  final Order order;
  final VoidCallback? onCall;
  final VoidCallback onWhatsApp;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    compactOrderNumber(order.orderNumber),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    order.orderNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Placed ${formatOrderDate(context, order.createdAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            AppStatusBadge(
              label: order.status.label,
              tone: orderStatusTone(order.status),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lgPlus),
        const AppDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lgPlus),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: AppSizes.avatarLarge / 2,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                child: Text(
                  orderInitials(order.customer.name),
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      order.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                    if (order.customer.mobile != null)
                      Text(
                        formatIndianMobile(order.customer.mobile!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    if (order.customer.address != null)
                      Text(
                        order.customer.address!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _ContactButton(
                icon: AppIcons.phone,
                foreground: AppColors.primary,
                background: AppColors.primarySurface,
                onPressed: onCall,
                tooltip: 'Copy customer number',
              ),
              const SizedBox(width: AppSpacing.md),
              _ContactButton(
                icon: AppIcons.message,
                foreground: AppColors.success,
                background: AppColors.successSurface,
                onPressed: onWhatsApp,
                tooltip: 'Copy order summary for WhatsApp',
              ),
            ],
          ),
        ),
        const AppDivider(),
        const SizedBox(height: AppSpacing.lgPlus),
        const _SectionLabel('Order Summary'),
        const SizedBox(height: AppSpacing.md),
        _DetailLine('Services', _orderServicesSummary(order)),
        const SizedBox(height: AppSpacing.sm),
        ..._groupItems(
          order.items,
        ).map((_OrderItemGroup group) => _ItemGroupView(group: group)),
        const SizedBox(height: AppSpacing.md),
        _MoneyRow(label: 'Subtotal', value: order.subtotal),
        _MoneyRow(
          label: order.discountPercentage > 0
              ? 'Discount (${_compact(order.discountPercentage)}%)'
              : 'Discount',
          value: order.discount,
          negative: order.discount > 0,
        ),
        _MoneyRow(label: 'Tax', value: order.tax),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: AppDivider(),
        ),
        _MoneyRow(
          label: 'Grand Total',
          value: order.grandTotal,
          strong: true,
          valueColor: AppColors.primary,
        ),
      ],
    ),
  );
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: onPressed == null ? AppColors.surfaceMuted : background,
      borderRadius: AppRadius.inputRadius,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.inputRadius,
        child: SizedBox.square(
          dimension: AppSizes.controlMedium,
          child: Icon(
            icon,
            size: AppIconSizes.md,
            color: onPressed == null ? AppColors.textDisabled : foreground,
          ),
        ),
      ),
    ),
  );
}

class _OrderItemGroup {
  const _OrderItemGroup({required this.name, required this.items});

  final String name;
  final List<OrderItem> items;
}

List<_OrderItemGroup> _groupItems(List<OrderItem> items) {
  final Map<String, List<OrderItem>> grouped = <String, List<OrderItem>>{};
  for (final OrderItem item in items) {
    final String key = '${item.itemCategoryId}|${item.measurement}';
    grouped.putIfAbsent(key, () => <OrderItem>[]).add(item);
  }
  return grouped.values
      .map(
        (List<OrderItem> group) =>
            _OrderItemGroup(name: group.first.itemCategoryName, items: group),
      )
      .toList(growable: false);
}

class _ItemGroupView extends StatelessWidget {
  const _ItemGroupView({required this.group});

  final _OrderItemGroup group;

  @override
  Widget build(BuildContext context) {
    final OrderItem first = group.items.first;
    final String services = group.items
        .map((OrderItem item) => item.serviceName)
        .toSet()
        .join(', ');
    final double groupTotal = group.items.fold<double>(
      0,
      (double sum, OrderItem item) => sum + item.lineTotal,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.mdPlus),
      decoration: const BoxDecoration(border: AppBorders.listItemBottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  services,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: AppFontWeights.semibold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  first.measurement.isEmpty
                      ? group.name
                      : '${group.name} × ${first.measurement}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            formatOrderMoney(groupTotal),
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: AppFontWeights.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.label,
    required this.value,
    this.negative = false,
    this.strong = false,
    this.valueColor,
  });

  final String label;
  final double value;
  final bool negative;
  final bool strong;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: strong ? AppTextStyles.bodyLarge : AppTextStyles.bodySmall,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Text(
          '${negative ? '- ' : ''}${formatOrderMoney(value)}',
          style: (strong ? AppTextStyles.bodyLarge : AppTextStyles.bodySmall)
              .copyWith(
                color:
                    valueColor ??
                    (negative ? AppColors.error : AppColors.textMuted),
                fontWeight: strong
                    ? AppFontWeights.extraBold
                    : AppFontWeights.medium,
              ),
        ),
      ],
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(child: _SectionLabel('Payment')),
            AppStatusBadge(
              label: order.paymentStatus.label,
              tone: _paymentTone(order.paymentStatus),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailLine('Grand Total', formatOrderMoney(order.grandTotal)),
        _DetailLine('Total Paid', formatOrderMoney(order.paidAmount)),
        _DetailLine(
          'Remaining Amount',
          formatOrderMoney(order.outstandingAmount),
          valueColor: order.outstandingAmount > 0
              ? AppColors.error
              : AppColors.success,
          strong: true,
        ),
      ],
    ),
  );
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final OrderAssignment? assignment = order.assignment;
    final String? assignedTo = assignment?.assignedTo ?? order.assignedTo;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel('Worker Assignment'),
          const SizedBox(height: AppSpacing.lg),
          if (assignedTo == null)
            Text('No worker assigned', style: AppTextStyles.bodySmall)
          else ...<Widget>[
            Row(
              children: <Widget>[
                const CircleAvatar(
                  radius: AppSizes.avatar / 2,
                  backgroundColor: AppColors.secondary,
                  foregroundColor: AppColors.surface,
                  child: Icon(AppIcons.userAssigned, size: AppIconSizes.md),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Text(
                    assignedTo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (assignment != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              _DetailLine('Status', assignment.status),
            ],
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Tooltip(
                  message:
                      'Worker selection is not available in the current app.',
                  child: SecondaryButton(
                    label: 'Reassign',
                    icon: AppIcons.refresh,
                    onPressed: null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Tooltip(
                  message:
                      'Worker selection is not available in the current app.',
                  child: PrimaryButton(
                    label: 'Assign Worker',
                    icon: AppIcons.addUser,
                    onPressed: null,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.history, required this.currentStatus});

  final List<OrderStatusHistory> history;
  final OrderStatus currentStatus;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionLabel('Order Timeline'),
        const SizedBox(height: AppSpacing.xl),
        if (history.isEmpty)
          Text(
            'No status history is available for this order.',
            style: AppTextStyles.bodySmall,
          )
        else
          ...List<Widget>.generate(history.length, (int index) {
            final OrderStatusHistory entry = history[index];
            return _TimelineEntry(
              entry: entry,
              isLast: index == history.length - 1,
              isCurrent: entry.newStatus == currentStatus,
            );
          }),
      ],
    ),
  );
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.entry,
    required this.isLast,
    required this.isCurrent,
  });

  final OrderStatusHistory entry;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final _TimelineVisual visual = _timelineVisual(entry.newStatus);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: AppSpacing.display,
            child: Column(
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: visual.background,
                    borderRadius: AppRadius.inputRadius,
                    border: Border.fromBorderSide(
                      AppBorders.chipActiveCustom(visual.color),
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: AppSizes.controlSmall,
                    child: Icon(
                      visual.icon,
                      color: visual.color,
                      size: AppIconSizes.md,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: AppBorderWidths.medium,
                      margin: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      color: visual.color,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: AppSpacing.xs,
                bottom: isLast ? AppSpacing.none : AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          entry.newStatus.label,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: AppFontWeights.bold,
                          ),
                        ),
                      ),
                      if (isCurrent) ...<Widget>[
                        const SizedBox(width: AppSpacing.md),
                        const AppStatusBadge(
                          label: 'Current',
                          tone: AppBadgeTone.success,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    formatOrderDate(context, entry.timestamp),
                    style: AppTextStyles.caption,
                  ),
                  Text(
                    'Changed by ${entry.changedBy}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                  if (entry.note != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.mdPlus,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: AppRadius.inputRadius,
                        border: Border(
                          left: AppBorders.timelineAccent(visual.color),
                        ),
                      ),
                      child: Text(entry.note!, style: AppTextStyles.caption),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionLabel('Delivery'),
        const SizedBox(height: AppSpacing.lg),
        if (order.expectedDeliveryDate != null)
          _DetailLine(
            'Expected delivery',
            formatOrderDate(context, order.expectedDeliveryDate!),
          ),
        if (order.deliveryDate != null)
          _DetailLine(
            'Delivered',
            formatOrderDate(context, order.deliveryDate!),
          ),
        _DetailLine('Status', order.status.label),
      ],
    ),
  );
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.order,
    required this.isUpdatingStatus,
    required this.onWhatsApp,
    required this.onMarkDelivered,
  });

  final Order order;
  final bool isUpdatingStatus;
  final VoidCallback onWhatsApp;
  final VoidCallback onMarkDelivered;

  @override
  Widget build(BuildContext context) {
    final bool canDeliver =
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.outForDelivery;
    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Tooltip(
            message: 'Printing is not configured in the current app.',
            child: _CompactActionButton(
              label: 'Print',
              icon: AppIcons.print,
              onPressed: null,
              primary: false,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 3,
          child: _CompactActionButton(
            label: 'WhatsApp',
            icon: AppIcons.share,
            onPressed: onWhatsApp,
            primary: false,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 4,
          child: _CompactActionButton(
            label: isUpdatingStatus ? 'Updating...' : 'Mark Delivered',
            onPressed: canDeliver && !isUpdatingStatus ? onMarkDelivered : null,
            primary: true,
          ),
        ),
      ],
    );
  }
}

class _CompactActionButton extends StatelessWidget {
  const _CompactActionButton({
    required this.label,
    required this.onPressed,
    required this.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = primary
        ? ElevatedButton.styleFrom(
            padding: AppSpacing.buttonSmallInsets,
            textStyle: AppTextStyles.buttonSmall,
          )
        : OutlinedButton.styleFrom(
            padding: AppSpacing.buttonSmallInsets,
            textStyle: AppTextStyles.buttonSmall,
          );
    final Widget button = primary
        ? ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: AppIconSizes.sm),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          );
    return SizedBox(height: AppSizes.buttonLargeHeight, child: button);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: AppTextStyles.labelUppercase.copyWith(color: AppColors.textMuted),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(
    this.label,
    this.value, {
    this.valueColor,
    this.strong = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: (strong ? AppTextStyles.bodyLarge : AppTextStyles.bodyMedium)
                .copyWith(color: valueColor),
          ),
        ),
      ],
    ),
  );
}

class _TimelineVisual {
  const _TimelineVisual({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}

_TimelineVisual _timelineVisual(OrderStatus status) => switch (status) {
  OrderStatus.draft || OrderStatus.received => const _TimelineVisual(
    icon: AppIcons.orders,
    color: AppColors.primary,
    background: AppColors.primarySurface,
  ),
  OrderStatus.inProgress => const _TimelineVisual(
    icon: AppIcons.clock,
    color: AppColors.warning,
    background: AppColors.warningSurface,
  ),
  OrderStatus.ready => const _TimelineVisual(
    icon: AppIcons.package,
    color: AppColors.success,
    background: AppColors.successSurface,
  ),
  OrderStatus.outForDelivery || OrderStatus.delivered => const _TimelineVisual(
    icon: AppIcons.delivery,
    color: AppColors.success,
    background: AppColors.successSurface,
  ),
  OrderStatus.cancelled => const _TimelineVisual(
    icon: AppIcons.close,
    color: AppColors.error,
    background: AppColors.errorSurface,
  ),
};

AppBadgeTone _paymentTone(OrderPaymentStatus status) => switch (status) {
  OrderPaymentStatus.paid => AppBadgeTone.success,
  OrderPaymentStatus.partiallyPaid ||
  OrderPaymentStatus.pending => AppBadgeTone.warning,
  OrderPaymentStatus.refunded ||
  OrderPaymentStatus.partiallyRefunded => AppBadgeTone.info,
  OrderPaymentStatus.unpaid => AppBadgeTone.error,
};

String _compact(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

String _orderServicesSummary(Order order) {
  if (order.items.isEmpty) return 'No services selected';
  return order.items
      .map((OrderItem item) => item.serviceName)
      .toSet()
      .join(', ');
}
