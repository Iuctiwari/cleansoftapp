import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_status_tone.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

/// Pushed from a Subscriptions-tab plan card — every tenant currently on
/// [planKey], reusing the same enriched overview endpoint the Clients tab
/// uses, just filtered server-side by plan instead of by search text.
class PlanTenantsScreen extends StatefulWidget {
  const PlanTenantsScreen({
    required this.planKey,
    required this.planDisplayName,
    super.key,
    this.apiService,
  });

  final String planKey;
  final String planDisplayName;
  final CompanyAdminApiService? apiService;

  @override
  State<PlanTenantsScreen> createState() => _PlanTenantsScreenState();
}

class _PlanTenantsScreenState extends State<PlanTenantsScreen> {
  late final CompanyAdminApiService _apiService;
  bool _isLoading = true;
  String? _error;
  List<TenantOverviewEntryModel> _tenants = <TenantOverviewEntryModel>[];

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
      final TenantOverviewPageModel page = await _apiService.listTenantsOverview(
        planKey: widget.planKey,
        limit: 100,
      );
      if (!mounted) return;
      setState(() {
        _tenants = page.items;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.planDisplayName} — Tenants')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoadingView();
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);
    if (_tenants.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.wallet,
        title: 'No tenants on this plan',
        message: 'Assign tenants to this plan from their subscription screen.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _tenants.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final TenantOverviewEntryModel tenant = _tenants[index];
        return AppCard(
          onTap: () => context.pushNamed(
            AppRouteNames.companyAdminTenantDetail,
            pathParameters: <String, String>{'tenantId': tenant.tenantId},
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(tenant.businessName, style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      tenant.ownerName,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (tenant.subscriptionStatus != null)
                AppStatusBadge(
                  label: tenant.subscriptionStatus!,
                  tone: companyAdminStatusTone(tenant.subscriptionStatus!),
                ),
            ],
          ),
        );
      },
    );
  }
}
