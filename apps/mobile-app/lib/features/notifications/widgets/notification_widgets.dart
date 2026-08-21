import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/notifications/models/notification.dart';

/// Icon/color pairing per notification type, all drawn from existing design
/// tokens (no hardcoded colors or icon assets).
class _NotificationVisual {
  const _NotificationVisual({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;
}

_NotificationVisual _visualFor(AppNotificationType type) => switch (type) {
  AppNotificationType.workerAssigned => const _NotificationVisual(
    icon: AppIcons.userAssigned,
    background: AppColors.iconBgPurple,
    color: AppColors.secondary,
  ),
  AppNotificationType.assignmentAccepted => const _NotificationVisual(
    icon: AppIcons.success,
    background: AppColors.iconBgCyan,
    color: AppColors.info,
  ),
  AppNotificationType.orderCreated => const _NotificationVisual(
    icon: AppIcons.orders,
    background: AppColors.iconBgBlue,
    color: AppColors.primary,
  ),
  AppNotificationType.orderInProgress => const _NotificationVisual(
    icon: AppIcons.clock,
    background: AppColors.iconBgYellow,
    color: AppColors.warningDark,
  ),
  AppNotificationType.orderInDelivery => const _NotificationVisual(
    icon: AppIcons.delivery,
    background: AppColors.iconBgCyan,
    color: AppColors.info,
  ),
  AppNotificationType.deliveryCompleted => const _NotificationVisual(
    icon: AppIcons.success,
    background: AppColors.iconBgGreen,
    color: AppColors.success,
  ),
  AppNotificationType.paymentPending => const _NotificationVisual(
    icon: AppIcons.payment,
    background: AppColors.iconBgYellow,
    color: AppColors.warningDark,
  ),
  AppNotificationType.paymentReceived => const _NotificationVisual(
    icon: AppIcons.payment,
    background: AppColors.iconBgGreen,
    color: AppColors.successLight,
  ),
  AppNotificationType.system => const _NotificationVisual(
    icon: AppIcons.settings,
    background: AppColors.iconBgGray,
    color: AppColors.textMuted,
  ),
};

const List<String> _monthAbbreviations = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Renders [createdAt] as a short relative time ("2 min ago", "Yesterday",
/// or a compact date once it is old enough that a relative label stops
/// being useful).
String formatNotificationTime(DateTime createdAt) {
  final DateTime now = DateTime.now();
  final DateTime local = createdAt.toLocal();
  final Duration difference = now.difference(local);

  if (difference.inSeconds < 60) return 'Just now';
  if (difference.inMinutes < 60) {
    final int minutes = difference.inMinutes;
    return '$minutes min${minutes == 1 ? '' : 's'} ago';
  }
  if (difference.inHours < 24) {
    final int hours = difference.inHours;
    return '$hours hr${hours == 1 ? '' : 's'} ago';
  }

  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(local.year, local.month, local.day);
  final int dayDifference = today.difference(day).inDays;
  if (dayDifference == 1) return 'Yesterday';
  if (dayDifference < 7) return '$dayDifference days ago';

  final String month = _monthAbbreviations[local.month - 1];
  return '$month ${local.day}';
}

class NotificationCategoryChips extends StatelessWidget {
  const NotificationCategoryChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final NotificationCategory selected;
  final ValueChanged<NotificationCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.block,
      child: ListView.separated(
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
          vertical: AppSpacing.lg,
        ),
        itemBuilder: (BuildContext context, int index) {
          final NotificationCategory category =
              NotificationCategory.values[index];
          final bool isSelected = category == selected;
          return ChoiceChip(
            label: Text(category.label),
            selected: isSelected,
            showCheckmark: false,
            selectedColor: AppColors.primaryMuted,
            side: isSelected
                ? AppBorders.chipActiveSide
                : AppBorders.chipDefaultSide,
            labelStyle: AppTextStyles.buttonMedium.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            onSelected: (bool value) {
              if (value) onSelected(category);
            },
          );
        },
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemCount: NotificationCategory.values.length,
      ),
    );
  }
}

class NotificationMarkAllReadButton extends StatelessWidget {
  const NotificationMarkAllReadButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: AppBorders.cardElevated,
        borderRadius: AppRadius.buttonRadius,
        boxShadow: AppShadows.small,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadius.buttonRadius,
        child: InkWell(
          borderRadius: AppRadius.buttonRadius,
          onTap: onPressed,
          child: Padding(
            padding: AppSpacing.buttonSmallInsets,
            child: Text(
              'Mark all read',
              style: AppTextStyles.buttonSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationUnreadSummary extends StatelessWidget {
  const NotificationUnreadSummary({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primarySurface,
        border: AppBorders.primaryCard,
        borderRadius: AppRadius.inputRadius,
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            AppIcons.notifications,
            color: AppColors.primary,
            size: AppIconSizes.lg,
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            '$count unread notification${count == 1 ? '' : 's'}',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class NotificationListCard extends StatelessWidget {
  const NotificationListCard({
    required this.notification,
    required this.onTap,
    this.compactOrderNumber,
    this.customerName,
    this.displayMessage,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  /// Compact order number (e.g. "ORD-1043"), resolved from the Orders API
  /// once available. Null while loading, on error, or when the notification
  /// has no related order.
  final String? compactOrderNumber;

  /// Customer name for the related order, resolved alongside
  /// [compactOrderNumber]. Null under the same conditions.
  final String? customerName;

  /// Message text with the long order number swapped for its compact form,
  /// once resolved. Falls back to [AppNotification.message] when null.
  final String? displayMessage;

  @override
  Widget build(BuildContext context) {
    final _NotificationVisual visual = _visualFor(notification.type);
    final bool isRead = notification.isRead;

    return Semantics(
      button: !isRead,
      label: '${notification.title}, ${isRead ? 'read' : 'unread'}',
      child: AnimatedContainer(
        duration: AppDurations.normal,
        decoration: BoxDecoration(
          color: isRead ? AppColors.surface : AppColors.primarySurfaceAlt,
          border: isRead ? AppBorders.cardDefault : AppBorders.primaryCard,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: AppRadius.cardRadius,
            onTap: onTap,
            child: Padding(
              padding: AppSpacing.cardInsets,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: visual.background,
                      borderRadius: AppRadius.inputRadius,
                    ),
                    child: SizedBox.square(
                      dimension: AppSizes.touchTarget,
                      child: Icon(
                        visual.icon,
                        color: visual.color,
                        size: AppIconSizes.lg,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTextStyles.subtitle.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                            if (!isRead) ...<Widget>[
                              const SizedBox(width: AppSpacing.md),
                              const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: SizedBox.square(
                                  dimension: AppSpacing.mdPlus,
                                ),
                              ),
                            ],
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              formatNotificationTime(notification.createdAt),
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          displayMessage ?? notification.message,
                          style: AppTextStyles.bodySmall,
                        ),
                        if (compactOrderNumber != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            customerName == null
                                ? compactOrderNumber!
                                : '${compactOrderNumber!} · ${customerName!}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
