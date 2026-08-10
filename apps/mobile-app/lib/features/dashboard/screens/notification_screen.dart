import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

enum NotificationCategory { all, orders, payments, staff, system }

extension on NotificationCategory {
  String get label => switch (this) {
    NotificationCategory.all => 'All',
    NotificationCategory.orders => 'Orders',
    NotificationCategory.payments => 'Payments',
    NotificationCategory.staff => 'Staff',
    NotificationCategory.system => 'System',
  };
}

@immutable
class DashboardNotificationItem {
  const DashboardNotificationItem({
    required this.category,
    required this.description,
    required this.icon,
    required this.id,
    required this.isRead,
    required this.time,
    required this.title,
  });

  final NotificationCategory category;
  final String description;
  final IconData icon;
  final String id;
  final bool isRead;
  final String time;
  final String title;

  DashboardNotificationItem copyWith({bool? isRead}) {
    return DashboardNotificationItem(
      category: category,
      description: description,
      icon: icon,
      id: id,
      isRead: isRead ?? this.isRead,
      time: time,
      title: title,
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;
  List<DashboardNotificationItem> _notifications =
      const <DashboardNotificationItem>[
        DashboardNotificationItem(
          category: NotificationCategory.orders,
          description: 'ORD-1043 has been assigned and is ready to review.',
          icon: AppIcons.orders,
          id: 'order-1043',
          isRead: false,
          time: '2 min ago',
          title: 'New Order Assigned',
        ),
        DashboardNotificationItem(
          category: NotificationCategory.payments,
          description: 'Rs. 850 was collected for order ORD-1042.',
          icon: AppIcons.payment,
          id: 'payment-1042',
          isRead: false,
          time: '1 hr ago',
          title: 'Payment Received',
        ),
      ];

  List<DashboardNotificationItem> get _visibleNotifications {
    if (_selectedCategory == NotificationCategory.all) return _notifications;
    return _notifications
        .where(
          (DashboardNotificationItem item) =>
              item.category == _selectedCategory,
        )
        .toList(growable: false);
  }

  int get _unreadCount => _notifications
      .where((DashboardNotificationItem item) => !item.isRead)
      .length;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRouteNames.dashboard);
    }
  }

  void _markRead(String id) {
    setState(() {
      _notifications = _notifications
          .map(
            (DashboardNotificationItem item) =>
                item.id == id ? item.copyWith(isRead: true) : item,
          )
          .toList(growable: false);
    });
  }

  void _markAllRead() {
    setState(() {
      _notifications = _notifications
          .map((DashboardNotificationItem item) => item.copyWith(isRead: true))
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<DashboardNotificationItem> visible = _visibleNotifications;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(AppIcons.arrowBack),
          tooltip: 'Back to dashboard',
        ),
        title: const Text('Notifications'),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.authenticationContentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (_unreadCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      AppSpacing.xl,
                      AppSpacing.pageHorizontal,
                      AppSpacing.none,
                    ),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _MarkAllReadButton(onPressed: _markAllRead),
                    ),
                  ),
                if (_unreadCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      AppSpacing.md,
                      AppSpacing.pageHorizontal,
                      AppSpacing.none,
                    ),
                    child: _UnreadSummary(count: _unreadCount),
                  ),
                SizedBox(
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
                      return ChoiceChip(
                        label: Text(category.label),
                        selected: category == _selectedCategory,
                        showCheckmark: false,
                        selectedColor: AppColors.primaryMuted,
                        side: category == _selectedCategory
                            ? AppBorders.chipActiveSide
                            : AppBorders.chipDefaultSide,
                        labelStyle: AppTextStyles.buttonMedium.copyWith(
                          color: category == _selectedCategory
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        onSelected: (bool selected) {
                          if (selected) {
                            setState(() => _selectedCategory = category);
                          }
                        },
                      );
                    },
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppSpacing.md),
                    itemCount: NotificationCategory.values.length,
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppDurations.normal,
                    child: visible.isEmpty
                        ? const _NotificationEmptyState(
                            key: ValueKey<String>('empty'),
                          )
                        : ListView.separated(
                            key: ValueKey<NotificationCategory>(
                              _selectedCategory,
                            ),
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.pageHorizontal,
                              AppSpacing.sm,
                              AppSpacing.pageHorizontal,
                              AppSpacing.pageBottom,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final DashboardNotificationItem item =
                                  visible[index];
                              return NotificationCard(
                                item: item,
                                onTap: item.isRead
                                    ? null
                                    : () => _markRead(item.id),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.lg),
                            itemCount: visible.length,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkAllReadButton extends StatelessWidget {
  const _MarkAllReadButton({required this.onPressed});

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
              'Mark All Read',
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

class _UnreadSummary extends StatelessWidget {
  const _UnreadSummary({required this.count});

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

class NotificationCard extends StatelessWidget {
  const NotificationCard({required this.item, required this.onTap, super.key});

  final DashboardNotificationItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isOrder = item.category == NotificationCategory.orders;
    final Color accent = isOrder ? AppColors.primary : AppColors.success;
    final Color iconBackground = isOrder
        ? AppColors.primarySurface
        : AppColors.successSurface;

    return Semantics(
      button: !item.isRead,
      label: '${item.title}, ${item.isRead ? 'read' : 'unread'}',
      child: AnimatedContainer(
        duration: AppDurations.normal,
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.surface : AppColors.primarySurfaceAlt,
          border: item.isRead ? AppBorders.cardDefault : AppBorders.primaryCard,
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
                      color: iconBackground,
                      borderRadius: AppRadius.inputRadius,
                    ),
                    child: SizedBox.square(
                      dimension: AppSizes.touchTarget,
                      child: Icon(
                        item.icon,
                        color: accent,
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
                                item.title,
                                style: AppTextStyles.subtitle,
                              ),
                            ),
                            if (!item.isRead) ...<Widget>[
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
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(item.description, style: AppTextStyles.bodySmall),
                        const SizedBox(height: AppSpacing.md),
                        Text(item.time, style: AppTextStyles.caption),
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

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxlPlus),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.cardRadius,
              ),
              child: SizedBox.square(
                dimension: AppSizes.emptyStateIcon,
                child: Icon(
                  AppIcons.notificationsOff,
                  color: AppColors.textSubtle,
                  size: AppIconSizes.h,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text('No notifications', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.sm),
            const Text("You're all caught up!", style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
