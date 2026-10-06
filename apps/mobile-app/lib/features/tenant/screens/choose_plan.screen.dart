import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/widgets/app_state_views.dart';
import 'package:nexoraa_mobile/features/subscription/models/subscription_models.dart';
import 'package:nexoraa_mobile/features/subscription/services/subscription_api_service.dart';
import 'package:nexoraa_mobile/features/subscription/widgets/plan_list_view.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../models/tenant_onboarding_data.dart';

/// Post-onboarding "Choose your plan" gate. Reached two ways: (1) the new
/// Owner's onboarding flow, right after AllSetScreen, with [onboardingData]
/// carried through so the dashboard still gets the freshly-created
/// tenantId; (2) an EXISTING tenant who authenticated but has never chosen a
/// plan (SplashController redirects here instead of the dashboard) — no
/// onboarding context, [onboardingData] is null, and Continue goes straight
/// to the dashboard using the already-signed-in session's tenantId.
///
/// Selecting a plan here never triggers Razorpay, even for a paid plan — it
/// only calls the same plan-assignment action the admin panel uses. Payment
/// collection for a paid plan is handled later from the Subscription screen
/// (see subscription_screen.dart), not during onboarding.
class ChoosePlanScreen extends StatefulWidget {
  const ChoosePlanScreen({this.onboardingData, super.key});

  final TenantOnboardingData? onboardingData;

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  final SubscriptionApiService _service = SubscriptionApiService();
  List<TenantPlan> _plans = const <TenantPlan>[];
  String? _selectedPlanKey;
  String _billingCycle = 'MONTHLY';
  bool _loading = true;
  bool _submitting = false;
  String? _loadError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final List<TenantPlan> plans = await _service.listPlans();
      if (!mounted) return;
      final TenantPlan? freeTrial = plans
          .cast<TenantPlan?>()
          .firstWhere((TenantPlan? p) => p?.planKey == 'FREE_TRIAL', orElse: () => null);
      setState(() {
        _plans = plans;
        _selectedPlanKey = freeTrial?.planKey;
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
        _loadError = context.l10n.unableToLoadPlans;
      });
    }
  }

  Future<void> _continue() async {
    final String? planKey = _selectedPlanKey;
    if (planKey == null || _submitting) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await _service.selectPlan(planKey: planKey, billingCycle: _billingCycle);
      if (!mounted) return;
      context.goNamed(AppRouteNames.dashboard, extra: widget.onboardingData);
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
        _submitError = context.l10n.unableToSelectPlan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            color: kPrimary,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.paddingOf(context).top + 22,
              24,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.l10n.choosePlanTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.choosePlanSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
          SafeArea(
            top: false,
            child: Container(
              color: kBackground,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (_submitError != null) ...<Widget>[
                    Text(
                      _submitError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedPlanKey == null || _submitting ? null : _continue,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(context.l10n.commonContinue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const AppLoadingView();
    if (_loadError != null) {
      return AppErrorView(message: _loadError!, onRetry: _loadPlans);
    }
    if (_plans.isEmpty) {
      return AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: context.l10n.noPlansTitle,
        message: context.l10n.noPlansMessage,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: PlanListView(
        plans: _plans,
        selectedPlanKey: _selectedPlanKey,
        billingCycle: _billingCycle,
        onPlanSelected: (String key) => setState(() => _selectedPlanKey = key),
        onBillingCycleChanged: (String cycle) => setState(() => _billingCycle = cycle),
      ),
    );
  }
}
