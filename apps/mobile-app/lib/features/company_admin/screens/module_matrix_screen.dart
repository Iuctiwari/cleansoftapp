import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/screens/admin_session_gate.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

/// Reads/writes via the GET/PUT /platform-admin/tenants/:tenantId/modules
/// controller added in Phase 5 (Phase 2 built only the schema + ModuleGuard,
/// no HTTP surface — see that phase's own report). This screen does not
/// enable/disable ModuleGuard's enforcement anywhere; it only edits the
/// TenantModuleAccess records ModuleGuard will eventually read (Phase 6).
class ModuleMatrixScreen extends StatefulWidget {
  const ModuleMatrixScreen({required this.tenantId, super.key, this.apiService});

  final String tenantId;
  final CompanyAdminApiService? apiService;

  @override
  State<ModuleMatrixScreen> createState() => _ModuleMatrixScreenState();
}

class _ModuleMatrixScreenState extends State<ModuleMatrixScreen> {
  late final CompanyAdminApiService _apiService;
  bool _isLoading = true;
  String? _error;
  List<ModuleMatrixEntryModel> _entries = <ModuleMatrixEntryModel>[];
  final Set<String> _pendingKeys = <String>{};

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
      final List<ModuleMatrixEntryModel> entries = await _apiService.getModuleMatrix(
        widget.tenantId,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
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

  Future<void> _toggle(ModuleMatrixEntryModel entry, bool newValue) async {
    setState(() => _pendingKeys.add(entry.moduleKey));
    try {
      final ModuleMatrixEntryModel updated = await _apiService.setModule(
        widget.tenantId,
        entry.moduleKey,
        isEnabled: newValue,
      );
      if (!mounted) return;
      setState(() {
        _entries = _entries
            .map((e) => e.moduleKey == updated.moduleKey ? updated : e)
            .toList(growable: false);
        _pendingKeys.remove(entry.moduleKey);
      });
    } on CompanyAdminApiException catch (e) {
      if (!mounted) return;
      setState(() => _pendingKeys.remove(entry.moduleKey));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminSessionGate(
      child: Scaffold(
        appBar: AppBar(title: const Text('Module Access')),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoadingView();
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int index) {
        final ModuleMatrixEntryModel entry = _entries[index];
        final bool isPending = _pendingKeys.contains(entry.moduleKey);
        return AppCard(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  entry.moduleKey.replaceAll('_', ' '),
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              if (isPending)
                const SizedBox.square(
                  dimension: AppIconSizes.md,
                  child: CircularProgressIndicator(strokeWidth: AppBorderWidths.medium),
                )
              else
                Switch(
                  value: entry.isEnabled,
                  onChanged: (bool value) => _toggle(entry, value),
                ),
            ],
          ),
        );
      },
    );
  }
}
