import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

class BusinessesTab extends StatefulWidget {
  const BusinessesTab({super.key, this.apiService});

  final CompanyAdminApiService? apiService;

  @override
  State<BusinessesTab> createState() => _BusinessesTabState();
}

class _BusinessesTabState extends State<BusinessesTab> {
  late final CompanyAdminApiService _apiService;
  bool _isLoading = true;
  String? _error;
  List<BusinessTypeModel> _businessTypes = <BusinessTypeModel>[];

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
      final List<BusinessTypeModel> types = await _apiService.listBusinessTypes();
      if (!mounted) return;
      setState(() {
        _businessTypes = types;
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
    final bool? saved = await context.pushNamed<bool>(AppRouteNames.companyAdminBusinessTypeForm);
    if (saved == true && mounted) await _load();
  }

  /// Create a configuration for a built-in type that has none yet.
  Future<void> _openConfigure(String value) async {
    final bool? saved = await context.pushNamed<bool>(
      AppRouteNames.companyAdminBusinessTypeForm,
      extra: value,
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _openEdit(BusinessTypeModel type) async {
    final bool? saved = await context.pushNamed<bool>(
      AppRouteNames.companyAdminBusinessTypeForm,
      extra: type,
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(BusinessTypeModel type) async {
    final bool confirmed = await AppConfirmDialog.show(
      context,
      title: 'Remove configuration',
      message:
          'Remove the defaults for "${type.label}"? The business type stays available to shops, '
          'and tenants already using it are unaffected.',
      confirmLabel: 'Remove',
    );
    if (!confirmed) return;
    try {
      await _apiService.deleteBusinessType(type.id);
      if (mounted) await _load();
    } on CompanyAdminApiException catch (e) {
      _showMessage(e.message);
    }
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
        tooltip: 'New business type',
        child: const Icon(AppIcons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoadingView();
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);

    // Every built-in type shops can pick at sign-up is always listed; the
    // configured record (defaults, label) is shown where one exists.
    final List<Widget> rows = <Widget>[];
    for (final MapEntry<String, String> builtIn in kBuiltInBusinessTypes.entries) {
      final List<BusinessTypeModel> configured =
          _businessTypes.where((BusinessTypeModel t) => t.value == builtIn.key).toList();
      if (configured.isEmpty) {
        rows.add(_notConfiguredCard(builtIn.key, builtIn.value));
      } else {
        rows.addAll(configured.map(_configuredCard));
      }
    }
    // Anything configured outside the built-in list (should not happen).
    rows.addAll(
      _businessTypes
          .where((BusinessTypeModel t) => !kBuiltInBusinessTypes.containsKey(t.value))
          .map(_configuredCard),
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
        itemCount: rows.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            final int configuredCount = _businessTypes.length;
            return Text(
              '${kBuiltInBusinessTypes.length} business types · $configuredCount configured',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            );
          }
          return rows[index - 1];
        },
      ),
    );
  }

  Widget _notConfiguredCard(String value, String label) {
    return AppCard(
      key: ValueKey<String>('business-type-$value'),
      onTap: () => _openConfigure(value),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(label, style: AppTextStyles.headingSmall),
                    const SizedBox(width: AppSpacing.sm),
                    const AppStatusBadge(label: 'Built-in', tone: AppBadgeTone.info),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Not configured yet — tap to set defaults',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                ),
              ],
            ),
          ),
          const Icon(AppIcons.chevronRight, color: AppColors.textSubtle),
        ],
      ),
    );
  }

  Widget _configuredCard(BusinessTypeModel type) {
    final int defaultsCount =
        type.defaultServices.length +
        type.defaultItemCategories.length +
        type.defaultOrderStatuses.length +
        type.defaultExpenseCategories.length;
    return AppCard(
      key: ValueKey<String>('business-type-${type.value}-${type.id}'),
      onTap: () => _openEdit(type),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(child: Text(type.label, style: AppTextStyles.headingSmall)),
                    const SizedBox(width: AppSpacing.sm),
                    AppStatusBadge(
                      label: type.isActive ? 'Configured' : 'Inactive',
                      tone: type.isActive ? AppBadgeTone.success : AppBadgeTone.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(type.value, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                if (type.description != null && type.description!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(type.description!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSubtle)),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  defaultsCount == 0
                      ? 'No defaults configured yet'
                      : '$defaultsCount default${defaultsCount == 1 ? '' : 's'} configured',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove configuration',
            icon: const Icon(AppIcons.delete, color: AppColors.error),
            onPressed: () => _delete(type),
          ),
        ],
      ),
    );
  }
}
