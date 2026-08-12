import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';

class CustomerSurfaceCard extends StatelessWidget {
  const CustomerSurfaceCard({required this.child, this.padding, super.key});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? AppSpacing.cardInsets,
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: AppBorders.cardElevated,
      borderRadius: AppRadius.cardRadius,
      boxShadow: AppShadows.small,
    ),
    child: child,
  );
}

class CustomerSummaryCard extends StatelessWidget {
  const CustomerSummaryCard({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
    super.key,
  });
  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
    decoration: BoxDecoration(
      color: background,
      borderRadius: AppRadius.cardRadius,
    ),
    child: Column(
      children: <Widget>[
        Text(value, style: AppTextStyles.headingMedium.copyWith(color: color)),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTextStyles.caption.copyWith(color: color)),
      ],
    ),
  );
}

class CustomerListCard extends StatelessWidget {
  const CustomerListCard({
    required this.customer,
    required this.onTap,
    super.key,
  });
  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CustomerSurfaceCard(
    padding: const EdgeInsets.all(AppSpacing.lg),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.surface,
            child: Center(
              child: Text(
                _initials(customer.name),
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.surface,
                  fontWeight: AppFontWeights.semibold,
                  height: 1,
                ),
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
                        customer.name,
                        style: AppTextStyles.subtitle,
                      ),
                    ),
                    if (customer.outstandingBalance > 0)
                      _Badge(
                        label:
                            'Due ${formatMoney(customer.outstandingBalance)}',
                        color: AppColors.error,
                        background: AppColors.errorSurface,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: <Widget>[
                    const Icon(
                      AppIcons.phone,
                      size: AppIconSizes.sm,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        customer.mobile == null
                            ? 'Not provided'
                            : formatIndianPhone(customer.mobile!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          _customerTypeIcon(customer.customerType),
                          size: AppIconSizes.sm,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          customer.customerType.apiValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.captionBold,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          AppIcons.orders,
                          size: AppIconSizes.sm,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Total Orders',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${customer.totalOrders}',
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class CustomerEmptyState extends StatelessWidget {
  const CustomerEmptyState({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.displayLarge),
    child: Center(
      child: Column(
        children: <Widget>[
          const Icon(AppIcons.users, size: 44, color: AppColors.textSubtle),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            action!,
          ],
        ],
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.background,
  });
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: AppRadius.badgeRadius,
    ),
    child: Text(label, style: AppTextStyles.label.copyWith(color: color)),
  );
}

String customerInitials(String name) => _initials(name);

String _initials(String name) {
  final List<String> parts = name.trim().split(RegExp(r'\s+'));
  return parts.take(2).map((String part) => part[0].toUpperCase()).join();
}

String formatMoney(double value) =>
    'Rs. ${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';

String formatIndianPhone(String value) {
  final String digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return value;
  final String nationalNumber = digits.length > 10
      ? digits.substring(digits.length - 10)
      : digits;
  return '+91 $nationalNumber';
}

IconData _customerTypeIcon(CustomerType type) => switch (type) {
  CustomerType.regular => AppIcons.userVerified,
  CustomerType.walkIn => AppIcons.user,
  CustomerType.corporate => AppIcons.branch,
  CustomerType.vip => AppIcons.success,
};

String formatDate(DateTime value) {
  const List<String> months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
