import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/subscription/models/subscription_models.dart';

String formatPaise(int amountInPaise) {
  final double rupees = amountInPaise / 100;
  return '₹${rupees.toStringAsFixed(rupees.truncateToDouble() == rupees ? 0 : 2)}';
}

/// Selectable list of plans plus a Monthly/Annual billing-cycle toggle,
/// shared between onboarding's "Choose your plan" screen and the
/// Subscription screen's "Change Plan" flow — one plan-picking UI, not two.
class PlanListView extends StatelessWidget {
  const PlanListView({
    required this.plans,
    required this.selectedPlanKey,
    required this.billingCycle,
    required this.onPlanSelected,
    required this.onBillingCycleChanged,
    this.currentPlanKey,
    super.key,
  });

  final List<TenantPlan> plans;
  final String? selectedPlanKey;
  final String billingCycle;
  final ValueChanged<String> onPlanSelected;
  final ValueChanged<String> onBillingCycleChanged;

  /// The tenant's currently-assigned plan, if any — shown with a "Current
  /// plan" badge so it's clear which card that is during an upgrade/change.
  final String? currentPlanKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _BillingCycleToggle(value: billingCycle, onChanged: onBillingCycleChanged),
        const SizedBox(height: AppSpacing.lg),
        ...plans.map(
          (TenantPlan plan) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _PlanCard(
              plan: plan,
              billingCycle: billingCycle,
              selected: plan.planKey == selectedPlanKey,
              isCurrent: plan.planKey == currentPlanKey,
              onTap: () => onPlanSelected(plan.planKey),
            ),
          ),
        ),
      ],
    );
  }
}

class _BillingCycleToggle extends StatelessWidget {
  const _BillingCycleToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _CycleOption(
            label: context.l10n.billingMonthly,
            selected: value == 'MONTHLY',
            onTap: () => onChanged('MONTHLY'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _CycleOption(
            label: context.l10n.billingAnnual,
            selected: value == 'ANNUAL',
            onTap: () => onChanged('ANNUAL'),
          ),
        ),
      ],
    );
  }
}

class _CycleOption extends StatelessWidget {
  const _CycleOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySurface : AppColors.surfaceMuted,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.billingCycle,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  final TenantPlan plan;
  final String billingCycle;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int price = plan.priceForCycle(billingCycle);
    final bool isFree = price == 0;

    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.primary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.textSubtle,
                size: AppIconSizes.md,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(plan.displayName, style: AppTextStyles.headingSmall),
              ),
              if (isCurrent)
                AppStatusBadge(
                  label: context.l10n.currentPlan,
                  tone: AppBadgeTone.info,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: isFree ? context.l10n.planFree : formatPaise(price),
                  style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary),
                ),
                if (!isFree)
                  TextSpan(
                    text: billingCycle == 'ANNUAL'
                        ? context.l10n.perYear
                        : context.l10n.perMonth,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSubtle),
                  ),
              ],
            ),
          ),
          if (plan.trialDays > 0) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.freeTrialDays(plan.trialDays),
              style: AppTextStyles.caption.copyWith(color: AppColors.success),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.planLimits(
              plan.maxBranches,
              plan.maxStaff,
              plan.maxMonthlyOrders,
            ),
            style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
          ),
        ],
      ),
    );
  }
}
