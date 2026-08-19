import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/widgets/new_order_widgets.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';
import 'package:nexoraa_mobile/features/payments/models/payment.dart';

enum PaymentsTab { history, outstanding }

IconData _todayTrendIcon(double? percentChange) =>
    percentChange != null && percentChange < 0
        ? AppIcons.trendingDown
        : AppIcons.trendingUp;

String _todayTrendLabel(double? percentChange) {
  if (percentChange == null) return 'No payments collected yesterday';
  if (percentChange == 0) return 'Same as yesterday';
  final String rounded = percentChange.abs().toStringAsFixed(1);
  return percentChange > 0
      ? '$rounded% higher than yesterday'
      : '$rounded% lower than yesterday';
}

class PaymentsSummaryCards extends StatelessWidget {
  const PaymentsSummaryCards({
    required this.todayCollected,
    required this.todayVsYesterdayPercentChange,
    required this.outstandingTotal,
    required this.outstandingCustomerCount,
    super.key,
  });

  final double todayCollected;

  /// Real percentage change of today's collected total versus yesterday's,
  /// or null when yesterday had no collected payments to compare against.
  final double? todayVsYesterdayPercentChange;
  final double outstandingTotal;
  final int outstandingCustomerCount;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: const BoxDecoration(
            gradient: AppGradients.successCard,
            borderRadius: AppRadius.cardRadius,
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'TODAY COLLECTED',
                style: AppTextStyles.labelUppercase.copyWith(
                  color: AppColors.whiteOverlay70,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatOrderMoney(todayCollected),
                style: AppTextStyles.headingLarge.copyWith(
                  color: AppColors.surface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Icon(
                    _todayTrendIcon(todayVsYesterdayPercentChange),
                    size: AppIconSizes.sm,
                    color: AppColors.whiteOverlay80,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _todayTrendLabel(todayVsYesterdayPercentChange),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.whiteOverlay80,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.mdPlus),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.fromBorderSide(AppBorders.errorSide),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'OUTSTANDING',
                style: AppTextStyles.labelUppercase.copyWith(
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                formatOrderMoney(outstandingTotal),
                style: AppTextStyles.headingLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  const Icon(
                    AppIcons.alert,
                    size: AppIconSizes.sm,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      outstandingCustomerCount == 1
                          ? '1 customer'
                          : '$outstandingCustomerCount customers',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class PaymentsTabBar extends StatelessWidget {
  const PaymentsTabBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final PaymentsTab selected;
  final ValueChanged<PaymentsTab> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    children: PaymentsTab.values
        .map(
          (PaymentsTab tab) => Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: ChoiceChip(
              showCheckmark: false,
              selected: tab == selected,
              onSelected: (_) => onSelected(tab),
              label: Text(
                tab == PaymentsTab.history ? 'History' : 'Outstanding',
              ),
              labelStyle: AppTextStyles.bodySmall.copyWith(
                color: tab == selected
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
                fontWeight: AppFontWeights.semibold,
              ),
              selectedColor: AppColors.primaryMuted,
              backgroundColor: AppColors.surface,
              side: tab == selected
                  ? AppBorders.chipActiveSide
                  : AppBorders.chipDefaultSide,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        )
        .toList(growable: false),
  );
}

class PaymentHistoryCard extends StatelessWidget {
  const PaymentHistoryCard({required this.payment, super.key});

  final PaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    final bool received = payment.status == PaymentTransactionStatus.successful;
    final AppSemanticColor colors = received
        ? const AppSemanticColor(
            text: AppColors.success,
            background: AppColors.successSurface,
          )
        : const AppSemanticColor(
            text: AppColors.error,
            background: AppColors.errorSurface,
          );
    return AppCard(
      child: Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: AppRadius.inputRadius,
            ),
            child: SizedBox.square(
              dimension: AppSizes.controlMediumLarge,
              child: Icon(
                AppIcons.payment,
                color: colors.text,
                size: AppIconSizes.lg,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        payment.customerName ?? 'Customer unavailable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '${received ? '+' : ''}${formatOrderMoney(payment.amount)}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colors.text,
                        fontWeight: AppFontWeights.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        payment.method.apiValue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      formatOrderDate(context, payment.createdAt),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSubtle,
                      ),
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
}

class OutstandingOrderCard extends StatelessWidget {
  const OutstandingOrderCard({
    required this.order,
    required this.onCollect,
    this.isCollecting = false,
    super.key,
  });

  final Order order;
  final VoidCallback? onCollect;

  /// Whether a collect request is in flight for this specific order. Only
  /// this card's button reflects the pending state; other outstanding
  /// orders' Collect buttons stay interactive.
  final bool isCollecting;

  @override
  Widget build(BuildContext context) => AppCard(
    borderColor: AppColors.errorBorder,
    child: Row(
      children: <Widget>[
        CircleAvatar(
          radius: AppSizes.controlMediumLarge / 2,
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.surface,
          child: Text(
            orderInitials(order.customer.name),
            style: AppTextStyles.captionBold.copyWith(color: AppColors.surface),
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
                style: AppTextStyles.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Due: ${formatOrderMoney(order.outstandingAmount)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                  fontWeight: AppFontWeights.semibold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${order.orderNumber} · ${formatOrderDate(context, order.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
        if (onCollect != null || isCollecting) ...<Widget>[
          const SizedBox(width: AppSpacing.md),
          ElevatedButton(
            onPressed: onCollect,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.mdPlus,
              ),
              textStyle: AppTextStyles.buttonSmall,
            ),
            child: isCollecting
                ? const SizedBox(
                    width: AppIconSizes.sm,
                    height: AppIconSizes.sm,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : const Text('Collect'),
          ),
        ],
      ],
    ),
  );
}

Future<({double amount, PaymentMethod method})?> showCollectPaymentDialog(
  BuildContext context, {
  required Order order,
}) {
  final TextEditingController amountController = TextEditingController(
    text: newOrderAmount(order.outstandingAmount),
  );
  PaymentMethod? method;
  return showDialog<({double amount, PaymentMethod method})>(
    context: context,
    builder: (BuildContext dialogContext) => StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) => AlertDialog(
        title: Text('Collect from ${order.customer.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AppTextField(
              controller: amountController,
              label: 'Amount',
              hintText: 'Enter amount to collect',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Payment method', style: AppTextStyles.inputLabel),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: PaymentMethod.values
                  .map(
                    (PaymentMethod value) => ChoiceChip(
                      label: Text(value.apiValue),
                      selected: method == value,
                      onSelected: (_) => setState(() => method = value),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final double? amount = double.tryParse(
                amountController.text.trim(),
              );
              final PaymentMethod? selectedMethod = method;
              if (amount == null ||
                  amount <= 0 ||
                  amount > order.outstandingAmount ||
                  selectedMethod == null) {
                return;
              }
              Navigator.of(
                dialogContext,
              ).pop((amount: amount, method: selectedMethod));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    ),
  ).whenComplete(amountController.dispose);
}
