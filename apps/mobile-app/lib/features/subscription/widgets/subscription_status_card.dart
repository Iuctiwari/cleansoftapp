import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/subscription/models/subscription_models.dart';

/// Prominent, at-a-glance subscription summary on the Owner dashboard — not
/// buried in More. Tapping it opens the full Subscription screen.
class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({
    required this.onTap,
    this.status,
    this.loading = false,
    super.key,
  });

  final VoidCallback onTap;
  final TenantSubscriptionStatus? status;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final TenantSubscriptionSummary? subscription = status?.subscription;
    final TenantPlan? plan = status?.plan;
    final int? daysRemaining = subscription?.daysRemaining;
    final bool lowOnDays = daysRemaining != null && daysRemaining <= 3;

    return AppCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBackgroundBlue,
              borderRadius: AppRadius.cardRadius,
            ),
            child: const Icon(AppIcons.payment, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('My Plan', style: AppTextStyles.captionBold),
                const SizedBox(height: 2),
                if (loading)
                  Text('Loading…', style: AppTextStyles.bodySmall)
                else if (status == null || !status!.hasSubscription)
                  Text(
                    'No plan selected — tap to choose one',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                  )
                else
                  Text(
                    plan?.displayName ?? subscription!.planKey,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
          if (status != null && status!.hasSubscription) ...<Widget>[
            if (daysRemaining != null)
              Text(
                daysRemaining >= 0 ? '${daysRemaining}d left' : 'Expired',
                style: AppTextStyles.captionBold.copyWith(
                  color: lowOnDays ? AppColors.error : AppColors.textSubtle,
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
          ],
          const Icon(Icons.chevron_right, color: AppColors.textSubtle),
        ],
      ),
    );
  }
}
