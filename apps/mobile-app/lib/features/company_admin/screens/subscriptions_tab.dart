import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

String _formatRupees(int paise) {
  final double rupees = paise / 100;
  return '₹${rupees.toStringAsFixed(rupees.truncateToDouble() == rupees ? 0 : 2)}';
}

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({super.key, this.apiService});

  final CompanyAdminApiService? apiService;

  @override
  State<SubscriptionsTab> createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab> {
  late final CompanyAdminApiService _apiService;
  bool _isLoading = true;
  String? _error;
  List<SubscriptionPlanModel> _plans = <SubscriptionPlanModel>[];
  Map<String, int> _tenantCounts = <String, int>{};

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CompanyAdminDependencies.apiService;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final List<SubscriptionPlanModel> plans = await _apiService.listSubscriptionPlans();
      final Map<String, int> counts = await _apiService.getSubscriptionPlanTenantCounts();
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _tenantCounts = counts;
        _isLoading = false;
      });
    } on CompanyAdminApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final bool? saved = await context.pushNamed<bool>(AppRouteNames.companyAdminPlanForm);
    if (saved == true && mounted) await _load();
  }

  Future<void> _openEdit(SubscriptionPlanModel plan) async {
    final bool? saved = await context.pushNamed<bool>(
      AppRouteNames.companyAdminPlanForm,
      extra: plan,
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(SubscriptionPlanModel plan) async {
    final int tenantsOnPlan = _tenantCounts[plan.planKey] ?? 0;
    final bool confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete ${plan.displayName}',
      message: tenantsOnPlan > 0
          ? '$tenantsOnPlan tenant${tenantsOnPlan == 1 ? '' : 's'} ${tenantsOnPlan == 1 ? 'is' : 'are'} '
                'currently on this plan. Reassign them to another plan first — this plan cannot '
                'be deleted while tenants depend on it.'
          : 'This plan has no tenants assigned. This cannot be undone.',
      confirmLabel: tenantsOnPlan > 0 ? 'OK' : 'Delete',
      destructive: tenantsOnPlan == 0,
    );
    if (!confirmed || tenantsOnPlan > 0) return;
    try {
      await _apiService.deleteSubscriptionPlan(plan.planKey);
      if (mounted) await _load();
    } on CompanyAdminApiException catch (e) {
      _showMessage(e.message);
    }
  }

  void _openTenantsOnPlan(SubscriptionPlanModel plan) {
    context.pushNamed(
      AppRouteNames.companyAdminPlanTenants,
      pathParameters: <String, String>{'planKey': plan.planKey},
      extra: plan.displayName,
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        tooltip: 'New plan',
        child: const Icon(AppIcons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoadingView();
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);
    if (_plans.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.wallet,
        title: 'No subscription plans yet',
        message: 'Tap + to create your first plan (e.g. Starter, Pro, Enterprise).',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _plans.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final SubscriptionPlanModel plan = _plans[index];
          final int tenantCount = _tenantCounts[plan.planKey] ?? 0;
          return AppCard(
            onTap: () => _openTenantsOnPlan(plan),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(plan.displayName, style: AppTextStyles.headingSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            plan.planKey,
                            style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                          ),
                        ],
                      ),
                    ),
                    if (!plan.isActive)
                      const Padding(
                        padding: EdgeInsets.only(right: AppSpacing.sm),
                        child: AppStatusBadge(label: 'Inactive', tone: AppBadgeTone.neutral),
                      ),
                    IconButton(
                      icon: const Icon(AppIcons.edit, color: AppColors.textMuted),
                      tooltip: 'Edit plan',
                      onPressed: () => _openEdit(plan),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.delete, color: AppColors.error),
                      tooltip: 'Delete plan',
                      onPressed: () => _delete(plan),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _Stat(
                        label: 'Monthly',
                        value: _formatRupees(plan.monthlyPriceInPaise),
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Annual',
                        value: _formatRupees(plan.annualPriceInPaise),
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Trial',
                        value: plan.trialDays == 0 ? 'None' : '${plan.trialDays}d',
                      ),
                    ),
                    Expanded(
                      child: _Stat(label: 'Tenants', value: '$tenantCount'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(value, style: AppTextStyles.bodyLarge),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
      ],
    );
  }
}
