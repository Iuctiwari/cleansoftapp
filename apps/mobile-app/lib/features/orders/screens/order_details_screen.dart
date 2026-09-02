import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/screens/assign_worker_screen.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';
import 'package:nexoraa_mobile/features/receipt/screens/receipt_preview_screen.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

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

  AccessPolicy get _accessPolicy =>
      AccessPolicy.fromSession(AuthenticationDependencies.controller.session);

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _details = _fetchDetails();

  Future<_OrderDetailsData> _fetchDetails() async {
    final session = AuthenticationDependencies.controller.session;
    final tenantId = session?.tenantId ?? '';
    final List<Object> results = await Future.wait<Object>(<Future<Object>>[
      widget.controller.details(widget.orderId),
      widget.controller.history(widget.orderId),
      if (tenantId.isNotEmpty)
        StaffApiService(
          tokenStorage: AuthenticationDependencies.tokenStorage,
        ).getStaffMembers(tenantId).catchError((_) => <StaffMember>[])
      else
        Future.value(<StaffMember>[]),
    ]);
    return _OrderDetailsData(
      order: results[0] as Order,
      history: results[1] as List<OrderStatusHistory>,
      staffMembers: results[2] as List<StaffMember>,
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

  Future<void> _openReceipt(Order order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptPreviewScreen(
          orderId: order.id,
          branchId: order.branchId,
          orderNumber: order.orderNumber,
        ),
      ),
    );
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

  Future<void> _openAssignWorkerScreen(Order order) async {
    final bool? assigned = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            AssignWorkerScreen(order: order, controller: widget.controller),
      ),
    );
    if (assigned == true && mounted) {
      setState(_load);
    }
  }

  Future<void> _acceptAssignment(Order order) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    try {
      await widget.controller.acceptAssignment(order.id);
      if (!mounted) return;
      setState(_load);
      _message('Assignment accepted.');
    } on OrderApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _rejectAssignment(Order order) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    try {
      await widget.controller.rejectAssignment(order.id);
      if (!mounted) return;
      _message('Assignment rejected.');
      Navigator.of(context).pop();
    } on OrderApiException catch (error) {
      _message(error.message);
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _transitionStatus(
    Order order,
    OrderStatus newStatus, {
    String? note,
  }) async {
    if (_isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    try {
      await widget.controller.changeStatus(order.id, newStatus, note: note);
      if (!mounted) return;
      setState(_load);
      _message('Order moved to ${newStatus.label}.');
    } on OrderApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _inProgress(Order order) async {
    final String staffName = order.assignedTo ?? 'Staff';
    final String? assignmentNote = order.assignment?.note?.trim();
    final String note = (assignmentNote != null && assignmentNote.isNotEmpty)
        ? 'Started by $staffName: $assignmentNote'
        : 'Started by $staffName';
    await _transitionStatus(order, OrderStatus.inProgress, note: note);
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
              accessPolicy: _accessPolicy,
              onCall: () => unawaited(_call(data.order)),
              onWhatsApp: () => unawaited(_whatsApp(data.order)),
              onMarkDelivered: () => unawaited(_markDelivered(data.order)),
              onPrint: () => unawaited(_openReceipt(data.order)),
              onAssignWorker: () =>
                  unawaited(_openAssignWorkerScreen(data.order)),
              onAcceptAssignment: () =>
                  unawaited(_acceptAssignment(data.order)),
              onRejectAssignment: () =>
                  unawaited(_rejectAssignment(data.order)),
              onInProgress: () => unawaited(_inProgress(data.order)),
              onReady: () => unawaited(
                _transitionStatus(
                  data.order,
                  OrderStatus.ready,
                  note: 'All items pressed and packaged',
                ),
              ),
            );
          },
    ),
  );
}

class _OrderDetailsData {
  const _OrderDetailsData({
    required this.order,
    required this.history,
    this.staffMembers = const <StaffMember>[],
  });

  final Order order;
  final List<OrderStatusHistory> history;
  final List<StaffMember> staffMembers;

  String resolveStaffName(String? idOrName) {
    if (idOrName == null || idOrName.trim().isEmpty) return 'Worker';
    for (final StaffMember staff in staffMembers) {
      if (staff.id == idOrName || staff.loginId == idOrName) {
        return staff.displayName;
      }
    }
    return idOrName;
  }
}

class _OrderDetailsContent extends StatelessWidget {
  const _OrderDetailsContent({
    required this.data,
    required this.isUpdatingStatus,
    required this.accessPolicy,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMarkDelivered,
    required this.onPrint,
    required this.onAssignWorker,
    required this.onAcceptAssignment,
    required this.onRejectAssignment,
    required this.onInProgress,
    required this.onReady,
  });

  final _OrderDetailsData data;
  final bool isUpdatingStatus;
  final AccessPolicy accessPolicy;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onMarkDelivered;
  final VoidCallback onPrint;
  final VoidCallback onAssignWorker;
  final VoidCallback onAcceptAssignment;
  final VoidCallback onRejectAssignment;
  final VoidCallback onInProgress;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final Order order = data.order;
    final bool isStaff = accessPolicy.isStaff;
    final String? assignedWorkerName =
        order.assignedTo != null || order.assignment?.assignedTo != null
        ? data.resolveStaffName(
            order.assignment?.assignedTo ?? order.assignedTo,
          )
        : null;
    final bool isPendingStaffAcceptance =
        isStaff &&
        order.assignedTo != null &&
        order.status != OrderStatus.accepted &&
        order.status != OrderStatus.rejected &&
        order.assignment?.status != 'Accepted' &&
        order.assignment?.status != 'Rejected';

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
            if (isStaff) ...<Widget>[
              if (isPendingStaffAcceptance)
                _StaffAssignmentActionsCard(
                  order: order,
                  isUpdatingStatus: isUpdatingStatus,
                  onAccept: onAcceptAssignment,
                  onReject: onRejectAssignment,
                )
              else if (order.assignedTo != null)
                _StaffAcceptedAssignmentCard(order: order),
            ] else ...<Widget>[
              _AssignmentCard(
                order: order,
                canManage: accessPolicy.allows(AppCapability.ordersAssign),
                onAssignOrReassign: onAssignWorker,
                assignedWorkerName: assignedWorkerName,
              ),
            ],
            const SizedBox(height: AppSpacing.lgPlus),
            _TimelineCard(
              history: data.history,
              order: order,
              currentStatus: order.status,
              assignedWorkerName: assignedWorkerName,
              isStaff: isStaff,
            ),
            if (order.expectedDeliveryDate != null ||
                order.deliveryDate != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lgPlus),
              _DeliveryCard(order: order),
            ],
            const SizedBox(height: AppSpacing.lgPlus),
            _BottomActions(
              order: order,
              isUpdatingStatus: isUpdatingStatus,
              accessPolicy: accessPolicy,
              onWhatsApp: onWhatsApp,
              onMarkDelivered: onMarkDelivered,
              onPrint: onPrint,
              onInProgress: onInProgress,
              onReady: onReady,
            ),
          ],
        );
      },
    );
  }
}

class _StaffAssignmentActionsCard extends StatelessWidget {
  const _StaffAssignmentActionsCard({
    required this.order,
    required this.isUpdatingStatus,
    required this.onAccept,
    required this.onReject,
  });

  final Order order;
  final bool isUpdatingStatus;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const <Widget>[
            _SectionLabel('New Assignment'),
            AppStatusBadge(
              label: 'Action Required',
              tone: AppBadgeTone.warning,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'You have been assigned to process this order. Please accept to begin work or reject if unavailable.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: AppSizes.buttonLargeHeight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  onPressed: isUpdatingStatus ? null : onReject,
                  child: Text(
                    'Reject Assignment',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: SizedBox(
                height: AppSizes.buttonLargeHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  onPressed: isUpdatingStatus ? null : onAccept,
                  child: Text(
                    'Accept Assignment',
                    style: AppTextStyles.buttonMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StaffAcceptedAssignmentCard extends StatelessWidget {
  const _StaffAcceptedAssignmentCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final OrderAssignment? assignment = order.assignment;
    final String assignedTo =
        assignment?.assignedTo ?? order.assignedTo ?? 'You';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel('Assignment'),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF6C38CC),
                foregroundColor: Colors.white,
                child: Text(
                  _getInitials(assignedTo),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      assignedTo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Staff · Assigned',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Text(
                            'Accepted',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: order.status == OrderStatus.inProgress
                                ? const Color(0xFFFFF7ED)
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.status == OrderStatus.inProgress
                                ? 'Processing'
                                : order.status.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: order.status == OrderStatus.inProgress
                                  ? const Color(0xFFEA580C)
                                  : const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
  const _AssignmentCard({
    required this.order,
    required this.canManage,
    required this.onAssignOrReassign,
    this.assignedWorkerName,
  });

  final Order order;
  final bool canManage;
  final VoidCallback onAssignOrReassign;
  final String? assignedWorkerName;

  @override
  Widget build(BuildContext context) {
    final OrderAssignment? assignment = order.assignment;
    final String? assignedTo = assignment?.assignedTo ?? order.assignedTo;
    final String displayName = assignedWorkerName ?? assignedTo ?? 'Worker';
    final bool isRejected =
        assignment?.status == 'Rejected' ||
        order.status == OrderStatus.rejected;
    final bool isAccepted =
        assignment?.status == 'Accepted' ||
        order.status == OrderStatus.accepted;
    final String assignmentStatus = isRejected
        ? 'Rejected'
        : isAccepted
        ? 'Accepted'
        : (assignedTo != null ? 'Assignment Pending' : 'Unassigned');
    final Color statusBg = isRejected
        ? const Color(0xFFFEF2F2)
        : isAccepted
        ? const Color(0xFFF1F5F9)
        : const Color(0xFFF5F3FF);
    final Color statusFg = isRejected
        ? const Color(0xFFEF4444)
        : isAccepted
        ? const Color(0xFF0F172A)
        : const Color(0xFF7C3AED);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel('Assignment'),
          const SizedBox(height: AppSpacing.lg),
          if (assignedTo == null) ...<Widget>[
            Text('No worker assigned', style: AppTextStyles.bodySmall),
            if (canManage) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonLargeHeight,
                child: ElevatedButton.icon(
                  icon: const Icon(AppIcons.addUser, size: AppIconSizes.sm),
                  label: const Text('Assign Worker'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  onPressed: onAssignOrReassign,
                ),
              ),
            ],
          ] else ...<Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6C38CC),
                  foregroundColor: Colors.white,
                  child: Text(
                    _getInitials(displayName),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manager · Main Branch',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSubtle,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              assignmentStatus,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusFg,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: order.status == OrderStatus.inProgress
                                  ? const Color(0xFFFFF7ED)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.status == OrderStatus.inProgress
                                  ? 'Processing'
                                  : order.status.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: order.status == OrderStatus.inProgress
                                    ? const Color(0xFFEA580C)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (canManage) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: AppSizes.buttonLargeHeight,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          AppIcons.refresh,
                          size: AppIconSizes.sm,
                          color: Colors.black87,
                        ),
                        label: const Text(
                          'Reassign',
                          style: TextStyle(color: Colors.black87),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        onPressed: onAssignOrReassign,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SizedBox(
                      height: AppSizes.buttonLargeHeight,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          AppIcons.addUser,
                          size: AppIconSizes.sm,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Assign Worker',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        onPressed: onAssignOrReassign,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.history,
    required this.order,
    required this.currentStatus,
    this.assignedWorkerName,
    this.isStaff = false,
  });

  final List<OrderStatusHistory> history;
  final Order order;
  final OrderStatus currentStatus;
  final String? assignedWorkerName;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final List<OrderStatusHistory> displayHistory = isStaff
        ? history
              .where(
                (OrderStatusHistory entry) =>
                    entry.newStatus != OrderStatus.assigned,
              )
              .toList(growable: false)
        : history;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionLabel('Order Timeline'),
          const SizedBox(height: AppSpacing.xl),
          if (displayHistory.isEmpty)
            Text(
              'No status history is available for this order.',
              style: AppTextStyles.bodySmall,
            )
          else
            ...List<Widget>.generate(displayHistory.length, (int index) {
              final OrderStatusHistory entry = displayHistory[index];
              return _TimelineEntry(
                entry: entry,
                isLast: index == displayHistory.length - 1,
                isCurrent: entry.newStatus == currentStatus,
                assignedWorkerName: assignedWorkerName,
                isStaff: isStaff,
              );
            }),
        ],
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.entry,
    required this.isLast,
    required this.isCurrent,
    this.assignedWorkerName,
    this.isStaff = false,
  });

  final OrderStatusHistory entry;
  final bool isLast;
  final bool isCurrent;
  final String? assignedWorkerName;
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final _TimelineVisual visual = _timelineVisual(entry.newStatus);
    final String subtitle = _subtitleText(
      entry,
      assignedWorkerName,
      isStaff: isStaff,
    );
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
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSubtle,
                    ),
                  ),
                  if (entry.note != null &&
                      entry.note!.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.mdPlus,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color:
                            entry.newStatus == OrderStatus.assigned ||
                                entry.newStatus == OrderStatus.accepted
                            ? const Color(0xFFF5F3FF)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                            color:
                                entry.newStatus == OrderStatus.assigned ||
                                    entry.newStatus == OrderStatus.accepted
                                ? const Color(0xFF7C3AED)
                                : visual.color,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        entry.note!.trim(),
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              entry.newStatus == OrderStatus.assigned ||
                                  entry.newStatus == OrderStatus.accepted
                              ? const Color(0xFF6B21A8)
                              : const Color(0xFF475569),
                        ),
                      ),
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

  String _subtitleText(
    OrderStatusHistory entry,
    String? workerName, {
    bool isStaff = false,
  }) {
    final String resolvedWorker =
        (workerName != null && workerName.trim().isNotEmpty)
        ? workerName
        : 'Worker';
    if (entry.newStatus == OrderStatus.assigned) {
      return 'Assigned to $resolvedWorker';
    }
    if (entry.newStatus == OrderStatus.accepted) {
      return isStaff
          ? 'Assignment accepted'
          : 'Assignment accepted by $resolvedWorker';
    }
    if (entry.newStatus == OrderStatus.rejected) {
      return isStaff ? 'Assignment rejected' : 'Rejected by $resolvedWorker';
    }
    if (entry.newStatus == OrderStatus.received ||
        entry.newStatus == OrderStatus.draft) {
      return 'Created by ${entry.changedBy}';
    }
    return 'Changed by ${entry.changedBy}';
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
    required this.accessPolicy,
    required this.onWhatsApp,
    required this.onMarkDelivered,
    required this.onPrint,
    required this.onInProgress,
    required this.onReady,
  });

  final Order order;
  final bool isUpdatingStatus;
  final AccessPolicy accessPolicy;
  final VoidCallback onWhatsApp;
  final VoidCallback onMarkDelivered;
  final VoidCallback onPrint;
  final VoidCallback onInProgress;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    if (accessPolicy.isStaff) {
      if (order.status == OrderStatus.accepted) {
        return SizedBox(
          width: double.infinity,
          height: AppSizes.buttonLargeHeight,
          child: ElevatedButton.icon(
            icon: const Icon(AppIcons.clock, size: AppIconSizes.md),
            label: Text(
              isUpdatingStatus ? 'Updating...' : 'In Progress',
              style: AppTextStyles.buttonMedium,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.buttonRadius,
              ),
            ),
            onPressed: isUpdatingStatus ? null : onInProgress,
          ),
        );
      } else if (order.status == OrderStatus.inProgress) {
        return SizedBox(
          width: double.infinity,
          height: AppSizes.buttonLargeHeight,
          child: ElevatedButton.icon(
            icon: const Icon(AppIcons.package, size: AppIconSizes.md),
            label: Text(
              isUpdatingStatus ? 'Updating...' : 'Ready',
              style: AppTextStyles.buttonMedium,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.buttonRadius,
              ),
            ),
            onPressed: isUpdatingStatus ? null : onReady,
          ),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    final bool isDeliveredOrCancelled =
        order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled;
    final bool isReady = order.status == OrderStatus.ready;

    if (isDeliveredOrCancelled) {
      return Row(
        children: <Widget>[
          Expanded(
            child: _CompactActionButton(
              label: 'Print',
              icon: AppIcons.print,
              onPressed: onPrint,
              primary: false,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _CompactActionButton(
              label: 'WhatsApp',
              icon: AppIcons.share,
              onPressed: onWhatsApp,
              primary: false,
            ),
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          flex: 2,
          child: _CompactActionButton(
            label: 'Print',
            icon: AppIcons.print,
            onPressed: onPrint,
            primary: false,
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
            onPressed: isReady && !isUpdatingStatus ? onMarkDelivered : null,
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
  OrderStatus.assigned => const _TimelineVisual(
    icon: Icons.person_add_alt_1,
    color: Color(0xFF7C3AED),
    background: Color(0xFFF5F3FF),
  ),
  OrderStatus.accepted => const _TimelineVisual(
    icon: Icons.how_to_reg,
    color: Color(0xFF0F172A),
    background: Color(0xFFF1F5F9),
  ),
  OrderStatus.rejected => const _TimelineVisual(
    icon: Icons.cancel_outlined,
    color: Color(0xFFEF4444),
    background: Color(0xFFFEF2F2),
  ),
  OrderStatus.inProgress => const _TimelineVisual(
    icon: AppIcons.clock,
    color: Color(0xFFEA580C),
    background: Color(0xFFFFF7ED),
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

String _getInitials(String name) {
  final List<String> parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts[0].isEmpty) return 'W';
  if (parts.length == 1) {
    final s = parts[0];
    return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
  }
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
