import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';

/// One shop in the "near me" list: name, distance, open/closed, Call and Book.
class ShopCard extends StatelessWidget {
  const ShopCard({
    required this.shop,
    required this.onOpen,
    this.highlightReach = false,
    super.key,
  });

  final ShopSummary shop;
  final VoidCallback onOpen;

  /// Show "Comes to your area" (when filtering by home service / pickup).
  final bool highlightReach;

  @override
  Widget build(BuildContext context) {
    final OpeningHoursDay? today = shop.todayHours;
    final String hours = today == null || today.closed || today.open == null || today.close == null
        ? context.l10n.consumerClosedToday
        : context.l10n.consumerTodayHours(context.formatClock(today.open!), context.formatClock(today.close!));

    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DecoratedBox(
                decoration: const BoxDecoration(color: AppColors.primarySurface, borderRadius: AppRadius.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Icon(
                    shop.categories.isEmpty ? AppIcons.service : categoryIcon(shop.categories.first),
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(shop.shopName, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      shop.categories.map(context.categoryLabel).join(', '),
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.consumerDistanceKm(shop.distanceKm.toStringAsFixed(1)),
                style: AppTextStyles.labelBold.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              const Icon(AppIcons.location, size: 16, color: AppColors.textSubtle),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(shop.addressLine, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              AppStatusBadge(
                label: shop.isOpenNow ? context.l10n.consumerOpenNow : context.l10n.consumerClosedNow,
                tone: shop.isOpenNow ? AppBadgeTone.success : AppBadgeTone.neutral,
              ),
              Text(hours, style: AppTextStyles.caption),
              if (highlightReach && shop.servesYourLocation)
                AppStatusBadge(label: context.l10n.consumerServesYou, tone: AppBadgeTone.info),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              for (final ServiceMode mode in shop.serviceModes)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Tooltip(
                    message: context.modeLabel(mode),
                    child: Icon(modeIcon(mode), size: 20, color: AppColors.textSecondary),
                  ),
                ),
              const Spacer(),
              if (shop.phone.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => context.callPhone(shop.phone),
                  icon: const Icon(AppIcons.phone, size: 18),
                  label: Text(context.l10n.consumerCall),
                ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(onPressed: onOpen, child: Text(context.l10n.consumerBook)),
            ],
          ),
        ],
      ),
    );
  }
}
