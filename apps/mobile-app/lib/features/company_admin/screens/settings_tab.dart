import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

/// Theme and module access are per-tenant settings, so this tab starts with
/// a tenant picker; once one is selected, both editors become reachable.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key, this.apiService});

  final CompanyAdminApiService? apiService;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final CompanyAdminApiService _apiService;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  static const int _pageSize = 50;

  bool _isSearching = false;
  bool _isLoadingMore = false;
  String? _error;
  String _query = '';
  int _page = 1;
  int _total = 0;
  List<TenantOverviewEntryModel> _results = <TenantOverviewEntryModel>[];
  TenantOverviewEntryModel? _selected;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CompanyAdminDependencies.apiService;
    _searchController.addListener(_onSearchChanged);
    // Show every tenant straight away; typing only narrows the list.
    unawaited(_search(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final String value = _searchController.text.trim();
    if (value == _query) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  /// Loads the first page for [value] (empty = all tenants).
  Future<void> _search(String value) async {
    setState(() {
      _isSearching = true;
      _error = null;
      _query = value;
    });
    try {
      final TenantOverviewPageModel page = await _apiService.listTenantsOverview(
        search: value,
        limit: _pageSize,
      );
      if (!mounted || value != _query) return;
      setState(() {
        _results = page.items;
        _page = 1;
        _total = page.total;
        _isSearching = false;
      });
    } on CompanyAdminApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _error = e.message;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final TenantOverviewPageModel page = await _apiService.listTenantsOverview(
        search: _query,
        page: _page + 1,
        limit: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _results = <TenantOverviewEntryModel>[..._results, ...page.items];
        _page = page.page;
        _total = page.total;
        _isLoadingMore = false;
      });
    } on CompanyAdminApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final TenantOverviewEntryModel? selected = _selected;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        Text('Choose a tenant', style: AppTextStyles.headingSmall),
        const SizedBox(height: AppSpacing.md),
        if (selected != null)
          AppCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(selected.businessName, style: AppTextStyles.headingSmall),
                      Text(
                        selected.ownerEmail,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() => _selected = null);
                    _searchController.clear();
                    if (_query.isNotEmpty || _results.isEmpty) unawaited(_search(''));
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
          )
        else ...<Widget>[
          AppTextField(
            controller: _searchController,
            label: 'Search',
            hintText: 'Search by shop name or owner name',
            icon: AppIcons.search,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            AppErrorView(message: _error!, onRetry: () => _search(_query))
          else if (_results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                _query.isEmpty ? 'No tenants yet.' : 'No tenant matches "$_query".',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            )
          else ...<Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                _query.isEmpty
                    ? 'All tenants ($_total)'
                    : '$_total match${_total == 1 ? '' : 'es'}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
            ),
            ..._results.map(
              (tenant) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  onTap: () => setState(() => _selected = tenant),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(tenant.businessName, style: AppTextStyles.bodyLarge),
                      Text(
                        tenant.ownerEmail,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_results.length < _total)
              Center(
                child: TextButton(
                  onPressed: _isLoadingMore ? null : _loadMore,
                  child: Text(
                    _isLoadingMore
                        ? 'Loading…'
                        : 'Load more (${_total - _results.length} more)',
                  ),
                ),
              ),
          ],
        ],
        if (selected != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          Text('Theme & Modules', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => context.pushNamed(
              AppRouteNames.companyAdminTenantTheme,
              pathParameters: <String, String>{'tenantId': selected.tenantId},
            ),
            child: const Row(
              children: <Widget>[
                Icon(AppIcons.tag, color: AppColors.primary),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Theme & Branding', style: AppTextStyles.bodyLarge),
                      Text(
                        'Colors, dark mode, app title, logo',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.chevronRight, color: AppColors.textSubtle),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: () => context.pushNamed(
              AppRouteNames.companyAdminTenantModules,
              pathParameters: <String, String>{'tenantId': selected.tenantId},
            ),
            child: const Row(
              children: <Widget>[
                Icon(AppIcons.checklist, color: AppColors.primary),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Module Access', style: AppTextStyles.bodyLarge),
                      Text(
                        'Enable or disable features for this tenant',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(AppIcons.chevronRight, color: AppColors.textSubtle),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
