import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

/// TenantBusinessType values (apps/backend/tenant-service/src/tenant/tenant.types.ts),
/// duplicated locally the same way platform-admin-service's own BusinessType
/// schema does — no shared-types package carries this enum.
const List<String> _kBusinessTypeValues = <String>[
  'laundry',
  'dry_cleaning',
  'tailoring',
  'shoe_cleaning',
  'appliance_repair',
  'mobile_repair',
  'vehicle_wash',
  'salon',
  'general',
  'custom',
];

/// Pushed route — create when [existing] is null, edit otherwise. Pops with
/// `true` on save so the Businesses tab knows to reload.
class BusinessTypeFormScreen extends StatefulWidget {
  const BusinessTypeFormScreen({super.key, this.existing, this.apiService});

  final BusinessTypeModel? existing;
  final CompanyAdminApiService? apiService;

  @override
  State<BusinessTypeFormScreen> createState() => _BusinessTypeFormScreenState();
}

class _BusinessTypeFormScreenState extends State<BusinessTypeFormScreen> {
  late final CompanyAdminApiService _apiService;
  late final TextEditingController _labelController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _customerLabelController;
  late final TextEditingController _orderLabelController;
  late final TextEditingController _itemLabelController;
  late final TextEditingController _deliveryLabelController;
  late String _selectedValue;
  late List<String> _orderStatuses;
  late List<String> _services;
  late List<String> _itemCategories;
  late List<String> _expenseCategories;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CompanyAdminDependencies.apiService;
    final BusinessTypeModel? existing = widget.existing;
    _selectedValue = existing?.value ?? _kBusinessTypeValues.first;
    _labelController = TextEditingController(text: existing?.label ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    final BusinessTypeTerminologyModel terminology =
        existing?.defaultTerminology ?? BusinessTypeTerminologyModel.fallback;
    _customerLabelController = TextEditingController(text: terminology.customerLabel);
    _orderLabelController = TextEditingController(text: terminology.orderLabel);
    _itemLabelController = TextEditingController(text: terminology.itemLabel);
    _deliveryLabelController = TextEditingController(text: terminology.deliveryLabel);
    _orderStatuses = List<String>.of(existing?.defaultOrderStatuses ?? const <String>[]);
    _services = List<String>.of(existing?.defaultServices ?? const <String>[]);
    _itemCategories = List<String>.of(existing?.defaultItemCategories ?? const <String>[]);
    _expenseCategories = List<String>.of(existing?.defaultExpenseCategories ?? const <String>[]);
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _descriptionController.dispose();
    _customerLabelController.dispose();
    _orderLabelController.dispose();
    _itemLabelController.dispose();
    _deliveryLabelController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_labelController.text.trim().isEmpty) {
      _showMessage('Enter a display label.');
      return;
    }
    setState(() => _isSaving = true);
    final BusinessTypeTerminologyModel terminology = BusinessTypeTerminologyModel(
      customerLabel: _customerLabelController.text.trim().isEmpty
          ? 'Customer'
          : _customerLabelController.text.trim(),
      orderLabel: _orderLabelController.text.trim().isEmpty
          ? 'Order'
          : _orderLabelController.text.trim(),
      itemLabel: _itemLabelController.text.trim().isEmpty
          ? 'Item'
          : _itemLabelController.text.trim(),
      deliveryLabel: _deliveryLabelController.text.trim().isEmpty
          ? 'Delivery'
          : _deliveryLabelController.text.trim(),
    );
    try {
      if (_isEditing) {
        await _apiService.updateBusinessType(
          widget.existing!.id,
          label: _labelController.text.trim(),
          description: _descriptionController.text.trim(),
          isActive: _isActive,
          defaultTerminology: terminology,
          defaultOrderStatuses: _orderStatuses,
          defaultServices: _services,
          defaultItemCategories: _itemCategories,
          defaultExpenseCategories: _expenseCategories,
        );
      } else {
        await _apiService.createBusinessType(
          value: _selectedValue,
          label: _labelController.text.trim(),
          description: _descriptionController.text.trim(),
          defaultTerminology: terminology,
          defaultOrderStatuses: _orderStatuses,
          defaultServices: _services,
          defaultItemCategories: _itemCategories,
          defaultExpenseCategories: _expenseCategories,
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
      appBar: AppBar(title: Text(_isEditing ? 'Edit Business Type' : 'New Business Type')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (!_isEditing)
              AppDropdownField<String>(
                label: 'Business Type Value',
                value: _selectedValue,
                items: _kBusinessTypeValues
                    .map((v) => AppDropdownOption<String>(value: v, label: v))
                    .toList(growable: false),
                onChanged: (String value) => setState(() => _selectedValue = value),
              ),
            if (!_isEditing) const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _labelController,
              label: 'Display Label',
              hintText: 'e.g. Laundry',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _descriptionController,
              label: 'Description (optional)',
            ),
            if (_isEditing) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available during onboarding'),
                value: _isActive,
                onChanged: (bool value) => setState(() => _isActive = value),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Text('Terminology', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'What a new shop of this type calls these concepts.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: _customerLabelController,
                    label: 'Customer',
                    hintText: 'Customer',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _orderLabelController,
                    label: 'Order',
                    hintText: 'Order',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: _itemLabelController,
                    label: 'Item',
                    hintText: 'Item',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _deliveryLabelController,
                    label: 'Delivery',
                    hintText: 'Delivery',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Default Setup', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Seeded once, automatically, when a new shop of this type onboards.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            _ChipListEditor(
              label: 'Default Services',
              hintText: 'e.g. Wash & Fold',
              values: _services,
              onChanged: (List<String> next) => setState(() => _services = next),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ChipListEditor(
              label: 'Default Item Categories',
              hintText: 'e.g. Shirts',
              values: _itemCategories,
              onChanged: (List<String> next) => setState(() => _itemCategories = next),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ChipListEditor(
              label: 'Default Order Statuses',
              hintText: 'e.g. Ready for Pickup',
              values: _orderStatuses,
              onChanged: (List<String> next) => setState(() => _orderStatuses = next),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ChipListEditor(
              label: 'Default Expense Categories',
              hintText: 'e.g. Detergent',
              values: _expenseCategories,
              onChanged: (List<String> next) => setState(() => _expenseCategories = next),
            ),
            const SizedBox(height: AppSpacing.xl),
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                PrimaryButton(
                  label: _isSaving ? '' : (_isEditing ? 'Save Changes' : 'Create Business Type'),
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

/// Add/remove chips for a string[] default (services, item categories, ...).
class _ChipListEditor extends StatefulWidget {
  const _ChipListEditor({
    required this.label,
    required this.hintText,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String hintText;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_ChipListEditor> createState() => _ChipListEditorState();
}

class _ChipListEditorState extends State<_ChipListEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final String value = _controller.text.trim();
    if (value.isEmpty || widget.values.contains(value)) return;
    widget.onChanged(<String>[...widget.values, value]);
    _controller.clear();
  }

  void _remove(String value) {
    widget.onChanged(widget.values.where((v) => v != value).toList(growable: false));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: AppTextStyles.inputLabel.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: AppRadius.inputRadius),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              icon: const Icon(AppIcons.add),
              onPressed: _add,
            ),
          ],
        ),
        if (widget.values.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: widget.values
                .map(
                  (value) => Chip(
                    label: Text(value),
                    onDeleted: () => _remove(value),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}
