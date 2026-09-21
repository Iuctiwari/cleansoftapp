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
      title: 'Remove Business Type',
      message: 'Remove "${type.label}"? Tenants already using it are unaffected.',
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
    if (_businessTypes.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.tag,
        title: 'No business types configured',
        message: 'Tap + to add the first one (e.g. Laundry, Salon, Dry Cleaning).',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _businessTypes.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final BusinessTypeModel type = _businessTypes[index];
          final int defaultsCount =
              type.defaultServices.length +
              type.defaultItemCategories.length +
              type.defaultOrderStatuses.length +
              type.defaultExpenseCategories.length;
          return AppCard(
            onTap: () => _openEdit(type),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(type.label, style: AppTextStyles.headingSmall),
                          if (!type.isActive) ...<Widget>[
                            const SizedBox(width: AppSpacing.sm),
                            const AppStatusBadge(label: 'Inactive', tone: AppBadgeTone.neutral),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        type.value,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                      if (type.description != null && type.description!.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          type.description!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSubtle),
                        ),
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
                  icon: const Icon(AppIcons.delete, color: AppColors.error),
                  onPressed: () => _delete(type),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
