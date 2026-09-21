import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/subscription/models/subscription_models.dart';
import 'package:nexoraa_mobile/features/subscription/services/subscription_api_service.dart';
import 'package:nexoraa_mobile/features/subscription/widgets/plan_list_view.dart';

/// Tenant-facing "My Plan" screen — current plan/status/days remaining/what's
/// included, plus changing to a different plan. Reached from the dashboard's
/// subscription card (see SubscriptionStatusCard), not buried in More.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionApiService _service = SubscriptionApiService();

  bool _loading = true;
  String? _loadError;
  TenantSubscriptionStatus? _status;

  bool _changingPlan = false;
  List<TenantPlan> _plans = const <TenantPlan>[];
  bool _plansLoading = false;
  String? _selectedPlanKey;
  String _billingCycle = 'MONTHLY';
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final TenantSubscriptionStatus status = await _service.getStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } on SubscriptionApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Unable to load your subscription. Please try again.';
      });
    }
  }

  Future<void> _startChangePlan() async {
    setState(() {
      _changingPlan = true;
      _plansLoading = true;
      _selectedPlanKey = _status?.subscription?.planKey;
      _billingCycle = _status?.subscription?.billingCycle ?? 'MONTHLY';
      _submitError = null;
    });
    try {
      final List<TenantPlan> plans = await _service.listPlans();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _plansLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _plansLoading = false;
        _submitError = 'Unable to load plans. Please try again.';
      });
    }
  }

  void _cancelChangePlan() => setState(() => _changingPlan = false);

  Future<void> _confirmPlanChange() async {
    final String? planKey = _selectedPlanKey;
    if (planKey == null || _submitting) return;
    final TenantPlan? plan = _plans.cast<TenantPlan?>().firstWhere(
      (TenantPlan? p) => p?.planKey == planKey,
      orElse: () => null,
    );
    if (plan == null) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final TenantSubscriptionStatus updated = await _service.selectPlan(
        planKey: planKey,
        billingCycle: _billingCycle,
      );
      if (!mounted) return;
      setState(() {
        _status = updated;
        _changingPlan = false;
        _submitting = false;
      });

      if (!plan.isFreeForCycle(_billingCycle)) {
        unawaited(_startPaidPlanOrder());
      }
    } on SubscriptionApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = error.message;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = 'Unable to change plan. Please try again.';
      });
    }
  }

  /// The plan has already switched (selectPlan above always applies
  /// immediately, same as the admin panel's own assign action) — this only
  /// creates the Razorpay order to collect payment for it. There is no
  /// in-app checkout UI yet, so the order id/amount is shown for now rather
  /// than silently doing nothing.
  Future<void> _startPaidPlanOrder() async {
    try {
      final TenantBillingOrder order = await _service.createOrder(
        billingCycle: _billingCycle,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Payment order created'),
          content: Text(
            'Your plan has been updated. An order for '
            '${formatPaise(order.amountInPaise)} has been created '
            '(order ${order.razorpayOrderId}) — checkout to complete this '
            'payment is not available in this build yet.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      final String message = error is SubscriptionApiException
          ? error.message
          : 'Unable to create a payment order for this plan.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Plan')),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) return const AppLoadingView();
    if (_loadError != null) return AppErrorView(message: _loadError!, onRetry: _load);

    final TenantSubscriptionStatus? status = _status;
    if (status == null || !status.hasSubscription) {
      return const AppEmptyState(
        icon: AppIcons.payment,
        title: 'No plan selected yet',
        message: 'Choose a plan to activate your workspace.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: <Widget>[
          _CurrentPlanCard(status: status),
          const SizedBox(height: AppSpacing.lg),
          if (!_changingPlan)
            SecondaryButton(label: 'Change Plan', onPressed: _startChangePlan)
          else
            _ChangePlanSection(
              plans: _plans,
              loading: _plansLoading,
              currentPlanKey: status.subscription?.planKey,
              selectedPlanKey: _selectedPlanKey,
              billingCycle: _billingCycle,
              submitting: _submitting,
              error: _submitError,
              onPlanSelected: (String key) => setState(() => _selectedPlanKey = key),
              onBillingCycleChanged: (String cycle) => setState(() => _billingCycle = cycle),
              onCancel: _cancelChangePlan,
              onConfirm: _confirmPlanChange,
            ),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({required this.status});

  final TenantSubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final TenantSubscriptionSummary subscription = status.subscription!;
    final TenantPlan? plan = status.plan;
    final int? daysRemaining = subscription.daysRemaining;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  plan?.displayName ?? subscription.planKey,
                  style: AppTextStyles.headingMedium,
                ),
              ),
              AppStatusBadge(label: subscription.status, tone: _statusTone(subscription.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (plan != null)
            Text(
              plan.isFreeForCycle(subscription.billingCycle)
                  ? 'Free'
                  : '${formatPaise(plan.priceForCycle(subscription.billingCycle))} / '
                        '${subscription.billingCycle == 'ANNUAL' ? 'year' : 'month'}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            daysRemaining == null
                ? 'No renewal date set yet'
                : daysRemaining >= 0
                ? '$daysRemaining day${daysRemaining == 1 ? '' : 's'} remaining'
                : 'Expired ${-daysRemaining} day${-daysRemaining == 1 ? '' : 's'} ago',
            style: AppTextStyles.bodySmall.copyWith(
              color: daysRemaining != null && daysRemaining < 0
                  ? AppColors.error
                  : AppColors.textSubtle,
            ),
          ),
          if (plan != null && plan.includedModuleKeys.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            const Text('Included', style: AppTextStyles.captionBold),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: plan.includedModuleKeys
                  .map(
                    (String key) => Chip(
                      label: Text(_moduleLabel(key)),
                      backgroundColor: AppColors.surfaceMuted,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  AppBadgeTone _statusTone(String status) => switch (status) {
    'ACTIVE' || 'TRIALING' => AppBadgeTone.success,
    'PAST_DUE' => AppBadgeTone.warning,
    _ => AppBadgeTone.error,
  };

  String _moduleLabel(String key) => key
      .split('_')
      .map((String w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');
}

class _ChangePlanSection extends StatelessWidget {
  const _ChangePlanSection({
    required this.plans,
    required this.loading,
    required this.currentPlanKey,
    required this.selectedPlanKey,
    required this.billingCycle,
    required this.submitting,
    required this.error,
    required this.onPlanSelected,
    required this.onBillingCycleChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  final List<TenantPlan> plans;
  final bool loading;
  final String? currentPlanKey;
  final String? selectedPlanKey;
  final String billingCycle;
  final bool submitting;
  final String? error;
  final ValueChanged<String> onPlanSelected;
  final ValueChanged<String> onBillingCycleChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    if (loading) return const AppLoadingView();

    final bool selectingSamePlan =
        selectedPlanKey != null && selectedPlanKey == currentPlanKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PlanListView(
          plans: plans,
          selectedPlanKey: selectedPlanKey,
          billingCycle: billingCycle,
          currentPlanKey: currentPlanKey,
          onPlanSelected: onPlanSelected,
          onBillingCycleChanged: onBillingCycleChanged,
        ),
        if (error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(child: SecondaryButton(label: 'Cancel', onPressed: onCancel)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PrimaryButton(
                label: submitting ? 'Saving…' : 'Confirm',
                onPressed: selectedPlanKey == null || selectingSamePlan || submitting
                    ? null
                    : onConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
