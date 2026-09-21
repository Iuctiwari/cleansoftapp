import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_status_tone.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

const List<String> _kSubscriptionStatusFilters = <String>[
  'TRIALING',
  'ACTIVE',
  'PAST_DUE',
  'EXPIRED',
  'SUSPENDED',
  'CANCELED',
];

class ClientsTab extends StatefulWidget {
  const ClientsTab({super.key, this.apiService});

  final CompanyAdminApiService? apiService;

  @override
  State<ClientsTab> createState() => _ClientsTabState();
}

class _ClientsTabState extends State<ClientsTab> {
  late final CompanyAdminApiService _apiService;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  String? _error;
  List<TenantOverviewEntryModel> _tenants = <TenantOverviewEntryModel>[];
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CompanyAdminDependencies.apiService;
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final TenantOverviewPageModel page = await _apiService.listTenantsOverview(
        search: _searchController.text.trim(),
        subscriptionStatus: _statusFilter,
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
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: AppTextField(
            controller: _searchController,
            hintText: 'Search by shop name or owner name',
            icon: AppIcons.search,
            label: 'Search',
            textInputAction: TextInputAction.search,
          ),
        ),
        SizedBox(
          height: AppSizes.iconMedium + AppSpacing.xl,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (_) {
                    setState(() => _statusFilter = null);
                    _load();
                  },
                ),
              ),
              ..._kSubscriptionStatusFilters.map(
                (status) => Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: _statusFilter == status,
                    onSelected: (_) {
                      setState(() => _statusFilter = status);
                      _load();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoadingView();
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);
    if (_tenants.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.branch,
        title: 'No clients found',
        message: 'Try a different search or filter.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        itemCount: _tenants.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final TenantOverviewEntryModel tenant = _tenants[index];
          return AppCard(
            onTap: () => context.pushNamed(
              AppRouteNames.companyAdminTenantDetail,
              pathParameters: <String, String>{'tenantId': tenant.tenantId},
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(tenant.businessName, style: AppTextStyles.headingSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${tenant.ownerName} · ${tenant.businessType}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (tenant.subscriptionStatus != null)
                      AppStatusBadge(
                        label: tenant.subscriptionStatus!,
                        tone: companyAdminStatusTone(tenant.subscriptionStatus!),
                      )
                    else
                      const AppStatusBadge(label: 'No plan', tone: AppBadgeTone.neutral),
                  ],
                ),
                if (tenant.planKey != null || tenant.daysRemaining != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      if (tenant.planKey != null) ...<Widget>[
                        const Icon(AppIcons.wallet, size: AppIconSizes.sm, color: AppColors.textSubtle),
                        const SizedBox(width: AppSpacing.xs),
                        Text(tenant.planKey!, style: AppTextStyles.caption),
                      ],
                      if (tenant.planKey != null && tenant.daysRemaining != null)
                        const SizedBox(width: AppSpacing.md),
                      if (tenant.daysRemaining != null)
                        Text(
                          tenant.daysRemaining! < 0
                              ? '${-tenant.daysRemaining!} days overdue'
                              : '${tenant.daysRemaining} days remaining',
                          style: AppTextStyles.caption.copyWith(
                            color: tenant.daysRemaining! < 0
                                ? AppColors.error
                                : AppColors.textSubtle,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
