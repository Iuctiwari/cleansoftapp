import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

const List<String> _kPlanKeys = <String>['FREE_TRIAL', 'STARTER', 'PRO', 'ENTERPRISE', 'CUSTOM'];

/// Pushed route — create when [existing] is null, edit otherwise. Pops with
/// `true` on save so the Subscriptions tab knows to reload.
class PlanFormScreen extends StatefulWidget {
  const PlanFormScreen({super.key, this.existing, this.apiService});

  final SubscriptionPlanModel? existing;
  final CompanyAdminApiService? apiService;

  @override
  State<PlanFormScreen> createState() => _PlanFormScreenState();
}

class _PlanFormScreenState extends State<PlanFormScreen> {
  late final CompanyAdminApiService _apiService;
  late final TextEditingController _displayNameController;
  late final TextEditingController _monthlyPriceController;
  late final TextEditingController _annualPriceController;
  late final TextEditingController _trialDaysController;
  late final TextEditingController _maxBranchesController;
  late final TextEditingController _maxStaffController;
  late final TextEditingController _maxMonthlyOrdersController;
  late String _planKey;
  late final Set<String> _selectedModules;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CompanyAdminDependencies.apiService;
    final SubscriptionPlanModel? existing = widget.existing;
    _planKey = existing?.planKey ?? _kPlanKeys.first;
    _displayNameController = TextEditingController(text: existing?.displayName ?? '');
    _monthlyPriceController = TextEditingController(
      text: existing == null ? '' : (existing.monthlyPriceInPaise / 100).toStringAsFixed(0),
    );
    _annualPriceController = TextEditingController(
      text: existing == null ? '' : (existing.annualPriceInPaise / 100).toStringAsFixed(0),
    );
    _trialDaysController = TextEditingController(text: '${existing?.trialDays ?? 0}');
    _maxBranchesController = TextEditingController(text: '${existing?.maxBranches ?? 1}');
    _maxStaffController = TextEditingController(text: '${existing?.maxStaff ?? 5}');
    _maxMonthlyOrdersController = TextEditingController(
      text: '${existing?.maxMonthlyOrders ?? 100}',
    );
    _selectedModules = Set<String>.of(existing?.includedModuleKeys ?? const <String>[]);
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _monthlyPriceController.dispose();
    _annualPriceController.dispose();
    _trialDaysController.dispose();
    _maxBranchesController.dispose();
    _maxStaffController.dispose();
    _maxMonthlyOrdersController.dispose();
    super.dispose();
  }

  int _parseInt(String text) => int.tryParse(text.trim()) ?? 0;

  Future<void> _save() async {
    if (_displayNameController.text.trim().isEmpty) {
      _showMessage('Enter a display name.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await _apiService.updateSubscriptionPlan(
          _planKey,
          displayName: _displayNameController.text.trim(),
          monthlyPriceInPaise: _parseInt(_monthlyPriceController.text) * 100,
          annualPriceInPaise: _parseInt(_annualPriceController.text) * 100,
          maxBranches: _parseInt(_maxBranchesController.text),
          maxStaff: _parseInt(_maxStaffController.text),
          maxMonthlyOrders: _parseInt(_maxMonthlyOrdersController.text),
          trialDays: _parseInt(_trialDaysController.text),
          includedModuleKeys: _selectedModules.toList(growable: false),
          isActive: _isActive,
        );
      } else {
        await _apiService.createSubscriptionPlan(
          planKey: _planKey,
          displayName: _displayNameController.text.trim(),
          monthlyPriceInPaise: _parseInt(_monthlyPriceController.text) * 100,
          annualPriceInPaise: _parseInt(_annualPriceController.text) * 100,
          maxBranches: _parseInt(_maxBranchesController.text),
          maxStaff: _parseInt(_maxStaffController.text),
          maxMonthlyOrders: _parseInt(_maxMonthlyOrdersController.text),
          trialDays: _parseInt(_trialDaysController.text),
          includedModuleKeys: _selectedModules.toList(growable: false),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on CompanyAdminApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Plan' : 'New Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppDropdownField<String>(
              label: 'Plan Key',
              value: _planKey,
              enabled: !_isEditing,
              items: _kPlanKeys
                  .map((k) => AppDropdownOption<String>(value: k, label: k))
                  .toList(growable: false),
              onChanged: (String value) => setState(() => _planKey = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _displayNameController,
              label: 'Display Name',
              hintText: 'e.g. Pro',
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: _monthlyPriceController,
                    label: 'Monthly Price (₹)',
                    hintText: '999',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _annualPriceController,
                    label: 'Annual Price (₹)',
                    hintText: '9999',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _trialDaysController,
              label: 'Free Trial Length (days)',
              hintText: '14',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Limits', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: _maxBranchesController,
                    label: 'Max Branches',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _maxStaffController,
                    label: 'Max Staff',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _maxMonthlyOrdersController,
              label: 'Max Monthly Orders',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Included Modules', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: kModuleKeys
                  .map(
                    (key) => FilterChip(
                      label: Text(key.replaceAll('_', ' ')),
                      selected: _selectedModules.contains(key),
                      onSelected: (bool selected) => setState(() {
                        if (selected) {
                          _selectedModules.add(key);
                        } else {
                          _selectedModules.remove(key);
                        }
                      }),
                    ),
                  )
                  .toList(growable: false),
            ),
            if (_isEditing) ...<Widget>[
              const SizedBox(height: AppSpacing.xl),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Plan active'),
                subtitle: const Text('Inactive plans stay assigned but can no longer be chosen.'),
                value: _isActive,
                onChanged: (bool value) => setState(() => _isActive = value),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                PrimaryButton(
                  label: _isSaving ? '' : (_isEditing ? 'Save Changes' : 'Create Plan'),
                  onPressed: _isSaving ? null : _save,
                ),
                if (_isSaving)
                  const SizedBox.square(
                    dimension: AppIconSizes.xl,
                    child: CircularProgressIndicator(
                      color: AppColors.surface,
                      strokeWidth: AppBorderWidths.medium,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
