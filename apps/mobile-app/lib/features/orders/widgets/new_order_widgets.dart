import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/widgets/customer_widgets.dart';
import 'package:nexoraa_mobile/features/orders/models/order_catalog.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';

class NewOrderStepScaffold extends StatelessWidget {
  const NewOrderStepScaffold({
    required this.step,
    this.stepCount = 6,
    required this.body,
    required this.footer,
    required this.onClose,
    super.key,
  });

  final int step;
  final int stepCount;
  final Widget body;
  final Widget footer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.md,
              AppSpacing.pageHorizontal,
              AppSpacing.none,
            ),
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: AppSpacing.displayLarge,
                  child: Row(
                    children: <Widget>[
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surfaceMuted,
                          foregroundColor: AppColors.textMuted,
                        ),
                        onPressed: onClose,
                        icon: const Icon(AppIcons.arrowBack),
                        tooltip: 'Close new order',
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text('New Order', style: AppTextStyles.title),
                      ),
                      Text(
                        '${step + 1}/$stepCount',
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                NewOrderProgressIndicator(currentStep: step, stepCount: stepCount),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.lg,
          AppSpacing.pageHorizontal,
          AppSpacing.xl,
        ),
        child: footer,
      ),
    ),
  );
}

class NewOrderProgressIndicator extends StatelessWidget {
  const NewOrderProgressIndicator({required this.currentStep, this.stepCount = 6, super.key});

  final int currentStep;
  final int stepCount;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'New order step ${currentStep + 1} of $stepCount',
    value: '${currentStep + 1} of $stepCount',
    child: Row(
      children: List<Widget>.generate(
        stepCount,
        (int index) => Expanded(
          child: Container(
            height: AppSpacing.xxs,
            margin: EdgeInsets.only(right: index == stepCount - 1 ? 0 : AppSpacing.xs),
            decoration: BoxDecoration(
              color: index <= currentStep
                  ? AppColors.primary
                  : AppColors.border,
              borderRadius: AppRadius.circular,
            ),
          ),
        ),
      ),
    ),
  );
}

class NewOrderFooter extends StatelessWidget {
  const NewOrderFooter({
    required this.secondaryLabel,
    required this.primaryLabel,
    required this.onSecondary,
    required this.onPrimary,
    this.busy = false,
    super.key,
  });

  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onPrimary;
  final bool busy;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: SecondaryButton(
          label: secondaryLabel,
          onPressed: busy ? null : onSecondary,
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        flex: 2,
        child: PrimaryButton(
          label: busy ? 'Saving...' : primaryLabel,
          icon: busy ? null : AppIcons.chevronRight,
          onPressed: busy ? null : onPrimary,
        ),
      ),
    ],
  );
}

class NewOrderCustomerCard extends StatelessWidget {
  const NewOrderCustomerCard({
    required this.customer,
    required this.selected,
    required this.onTap,
    this.orderCount,
    super.key,
  });

  final Customer customer;
  final bool selected;
  final VoidCallback onTap;
  final int? orderCount;

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    borderColor: selected ? AppColors.primary : null,
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: Row(
      children: <Widget>[
        CircleAvatar(
          radius: AppSizes.avatarSmall / 2,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          child: Text(
            orderInitials(customer.name),
            style: AppTextStyles.captionBold.copyWith(color: AppColors.surface),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(customer.name, style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                <String>[
                  if (customer.mobile != null)
                    formatIndianPhone(customer.mobile!),
                  '${orderCount ?? customer.totalOrders} orders',
                ].join(' · '),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        if (selected) const Icon(AppIcons.success, color: AppColors.primary),
      ],
    ),
  );
}

class NewOrderItemCard extends StatelessWidget {
  const NewOrderItemCard({
    required this.category,
    required this.prices,
    required this.amount,
    required this.onDecrease,
    required this.onIncrease,
    required this.onEdit,
    super.key,
  });

  final OrderItemCategory category;
  final List<OrderCatalogPrice> prices;
  final double amount;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final List<OrderCatalogPrice> sortedPrices = <OrderCatalogPrice>[...prices]
      ..sort(
        (OrderCatalogPrice first, OrderCatalogPrice second) =>
            first.basePrice.compareTo(second.basePrice),
      );
    final OrderCatalogPrice? price = sortedPrices.firstOrNull;
    final String priceLabel = price == null
        ? 'Price unavailable · Per ${category.unitType.label}'
        : '${sortedPrices.length > 1 ? 'From ' : ''}'
              '${formatOrderMoney(price.basePrice)} / '
              '${price.pricingType.unitLabel}';
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lgPlus),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(category.name, style: AppTextStyles.bodyLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(priceLabel, style: AppTextStyles.caption),
              ],
            ),
          ),
          _QuantityButton(icon: AppIcons.remove, onPressed: onDecrease),
          InkWell(
            borderRadius: AppRadius.buttonRadius,
            onTap: onEdit,
            child: SizedBox(
              width: AppSpacing.display,
              height: AppSpacing.display,
              child: Center(
                child: Text(
                  _amount(amount, category.unitType),
                  style: AppTextStyles.bodyLarge,
                ),
              ),
            ),
          ),
          _QuantityButton(
            icon: AppIcons.add,
            onPressed: onIncrease,
            primary: true,
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    constraints: const BoxConstraints.tightFor(
      width: AppSizes.controlSmall,
      height: AppSizes.controlSmall,
    ),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      backgroundColor: primary ? AppColors.primary : AppColors.surfaceMuted,
      foregroundColor: primary ? AppColors.surface : AppColors.textMuted,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
    ),
    onPressed: onPressed,
    icon: Icon(icon, size: AppIconSizes.md),
  );
}

class NewOrderErrorBanner extends StatelessWidget {
  const NewOrderErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      color: AppColors.errorSurface,
      borderRadius: AppRadius.inputRadius,
      border: Border.fromBorderSide(BorderSide(color: AppColors.errorBorder)),
    ),
    child: Row(
      children: <Widget>[
        const Icon(AppIcons.alert, color: AppColors.error),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}

class NewOrderInfoBanner extends StatelessWidget {
  const NewOrderInfoBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: const BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: AppRadius.inputRadius,
      border: Border.fromBorderSide(BorderSide(color: AppColors.primaryBorder)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(AppIcons.payment, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

String newOrderAmount(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

String _amount(double value, CatalogUnitType type) {
  if (value == 0) return '0';
  final String formatted = newOrderAmount(value);
  return type == CatalogUnitType.kg ? '$formatted kg' : formatted;
}
