import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';

String formatIndianMobile(String value) {
  final String compact = value.replaceAll(RegExp(r'[^0-9+]'), '');
  final String digits = compact.replaceAll('+', '');
  if (digits.length == 10) return '+91 $digits';
  if (digits.length == 11 && digits.startsWith('0')) {
    return '+91 ${digits.substring(1)}';
  }
  if (digits.length == 12 && digits.startsWith('91')) {
    return '+91 ${digits.substring(2)}';
  }
  return value.trim();
}

Future<void> copyOrderCustomerMobile(String mobile) => Clipboard.setData(
  ClipboardData(text: formatIndianMobile(mobile)),
);

/// Compacts a real backend order number (e.g. `ORD-KTD-000001`) into a short
/// `ORD-<sequence>` form (e.g. `ORD-1042`) by trimming the leading zeros off
/// its trailing numeric sequence. Falls back to the raw order number when no
/// numeric sequence can be found. Shared by the Order Details screen and the
/// new-order Receipt step so both display the identical compact form.
String compactOrderNumber(String orderNumber) {
  final RegExpMatch? match = RegExp(r'(\d+)(?!.*\d)').firstMatch(orderNumber);
  final int? sequence = match == null ? null : int.tryParse(match.group(1)!);
  return sequence == null ? orderNumber : 'ORD-$sequence';
}

Future<void> copyOrderShareText(Order order) => Clipboard.setData(
  ClipboardData(
    text:
        'Order ${order.orderNumber}\n'
        'Status: ${order.status.label}\n'
        'Total: ${formatOrderMoney(order.grandTotal)}\n'
        'Outstanding: ${formatOrderMoney(order.outstandingAmount)}',
  ),
);

class OrderFilterBar extends StatelessWidget {
  const OrderFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final OrderListFilter selected;
  final ValueChanged<OrderListFilter> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHorizontal),
    child: Row(
      children: OrderListFilter.values
          .map(
            (OrderListFilter filter) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: ChoiceChip(
                showCheckmark: false,
                selected: filter == selected,
                onSelected: (_) => onSelected(filter),
                label: Text(filter.label),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: filter == selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: AppFontWeights.medium,
                ),
                selectedColor: AppColors.primaryMuted,
                backgroundColor: AppColors.surface,
                side: filter == selected
                    ? AppBorders.chipActiveSide
                    : AppBorders.chipDefaultSide,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          )
          .toList(growable: false),
    ),
  );
}

class OrderListCard extends StatelessWidget {
  const OrderListCard({required this.order, required this.onTap, super.key});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(AppSpacing.lgPlus),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CircleAvatar(
          radius: AppSizes.avatarSmall / 2,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          child: Text(
            orderInitials(order.customer.name),
            style: AppTextStyles.captionBold.copyWith(
              color: AppColors.surface,
              fontWeight: AppFontWeights.bold,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      order.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    formatOrderMoney(order.grandTotal),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: AppFontWeights.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${order.orderNumber} · ${orderItemsSummary(order)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.mdPlus),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      formatOrderDate(context, order.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textSubtle,
                        letterSpacing: AppLetterSpacing.normal,
                      ),
                    ),
                  ),
                  AppStatusBadge(
                    label: order.status.label,
                    tone: orderStatusTone(order.status),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

AppBadgeTone orderStatusTone(OrderStatus status) => switch (status) {
  OrderStatus.ready => AppBadgeTone.success,
  OrderStatus.inProgress || OrderStatus.outForDelivery => AppBadgeTone.info,
  OrderStatus.received || OrderStatus.draft => AppBadgeTone.warning,
  OrderStatus.delivered => AppBadgeTone.neutral,
  OrderStatus.cancelled => AppBadgeTone.error,
};

String orderInitials(String name) {
  final List<String> parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  return parts.take(2).map((String part) => part[0].toUpperCase()).join();
}

String orderItemsSummary(Order order) {
  if (order.items.isEmpty) return 'No item details';
  if (order.items.length == 1) {
    final OrderItem item = order.items.single;
    final String measurement = item.measurement;
    return measurement.isEmpty
        ? '${item.itemCategoryName} · ${item.serviceName}'
        : '${item.itemCategoryName} · ${item.serviceName} $measurement';
  }
  final String categories = order.items
      .take(2)
      .map((OrderItem item) => item.itemCategoryName)
      .join(', ');
  return '${order.items.length} items · $categories';
}

String formatOrderMoney(double value) {
  final String amount = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
  final List<String> parts = amount.split('.');
  String leading = parts.first;
  final String lastThree = leading.length > 3
      ? leading.substring(leading.length - 3)
      : leading;
  leading = leading.length > 3 ? leading.substring(0, leading.length - 3) : '';
  final List<String> groups = <String>[];
  while (leading.length > 2) {
    groups.insert(0, leading.substring(leading.length - 2));
    leading = leading.substring(0, leading.length - 2);
  }
  if (leading.isNotEmpty) groups.insert(0, leading);
  final String integer = <String>[...groups, lastThree].join(',');
  final String decimal = parts.length == 2 ? '.${parts.last}' : '';
  return 'Rs. $integer$decimal';
}

String formatOrderDate(BuildContext context, DateTime source) {
  final DateTime value = source.toLocal();
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(value.year, value.month, value.day);
  final String time = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(value));
  if (day == today) return 'Today, $time';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday, $time';
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}, $time';
}
