import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/branch/controllers/branch_form_controller.dart';

enum BranchFormMode { add, edit }

/// One scrollable form shared by Add Branch and Edit Branch.
class BranchFormScreen extends StatefulWidget {
  const BranchFormScreen({required this.mode, this.branch, super.key})
    : assert(
        mode != BranchFormMode.edit || branch != null,
        'Edit mode requires an existing branch.',
      );

  final BranchFormMode mode;
  final Branch? branch;

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BranchFormController _controller = BranchFormController(
    service: BranchManagementDependencies.service,
  );

  late final TextEditingController _branchNameController;
  late final TextEditingController _codeController;
  late final TextEditingController _streetAddressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _countryController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _openingTimeController;
  late final TextEditingController _closingTimeController;
  late final TextEditingController _managerIdController;

  BranchStatus _status = BranchStatus.active;
  bool _unassignManager = false;

  bool get _isEdit => widget.mode == BranchFormMode.edit;

  @override
  void initState() {
    super.initState();
    final Branch? branch = widget.branch;
    _branchNameController = TextEditingController(text: branch?.branchName ?? '');
    _codeController = TextEditingController(text: branch?.code ?? '');
    _streetAddressController = TextEditingController(
      text: branch?.streetAddress ?? '',
    );
    _cityController = TextEditingController(text: branch?.city ?? '');
    _stateController = TextEditingController(text: branch?.state ?? '');
    _countryController = TextEditingController(text: branch?.country ?? '');
    _postalCodeController = TextEditingController(text: branch?.postalCode ?? '');
    _phoneController = TextEditingController(text: branch?.phone ?? '');
    _emailController = TextEditingController(text: branch?.email ?? '');
    _openingTimeController = TextEditingController(
      text: branch?.openingTime ?? '',
    );
    _closingTimeController = TextEditingController(
      text: branch?.closingTime ?? '',
    );
    _managerIdController = TextEditingController(text: branch?.managerId ?? '');
    _status = branch?.status ?? BranchStatus.active;
  }

  @override
  void dispose() {
    _branchNameController.dispose();
    _codeController.dispose();
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _openingTimeController.dispose();
    _closingTimeController.dispose();
    _managerIdController.dispose();
    _controller.dispose();
    super.dispose();
  }

  static final RegExp _timePattern = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
  static final RegExp _codePattern = RegExp(r'^[A-Za-z0-9\-_]+$');
  static final RegExp _phonePattern = RegExp(r'^\d{10}$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();

  String? _validateTime(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!_timePattern.hasMatch(trimmed)) {
      return 'Use 24-hour HH:mm, e.g. 09:00';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final Branch? result = _isEdit
        ? await _controller.update(
            widget.branch!.branchId,
            UpdateBranchInput(
              branchName: _optional(_branchNameController.text),
              code: _optional(_codeController.text),
              streetAddress: _optional(_streetAddressController.text),
              city: _optional(_cityController.text),
              state: _optional(_stateController.text),
              country: _optional(_countryController.text),
              postalCode: _optional(_postalCodeController.text),
              phone: _optional(_phoneController.text),
              email: _optional(_emailController.text),
              openingTime: _optional(_openingTimeController.text),
              closingTime: _optional(_closingTimeController.text),
              status: _status,
              managerId: _unassignManager
                  ? null
                  : (_optional(_managerIdController.text) ?? const _KeepUnset()),
            ),
          )
        : await _controller.create(
            CreateBranchInput(
              branchName: _branchNameController.text.trim(),
              phone: _phoneController.text.trim(),
              email: _emailController.text.trim(),
              code: _optional(_codeController.text),
              streetAddress: _optional(_streetAddressController.text),
              city: _optional(_cityController.text),
              state: _optional(_stateController.text),
              country: _optional(_countryController.text),
              postalCode: _optional(_postalCodeController.text),
              openingTime: _optional(_openingTimeController.text),
              closingTime: _optional(_closingTimeController.text),
              managerId: _optional(_managerIdController.text),
            ),
          );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(result);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? 'Branch updated successfully' : 'Branch created successfully',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Branch' : 'Add Branch')),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (BuildContext context, Widget? _) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.xl,
                AppSpacing.pageHorizontal,
                AppSpacing.pageBottom,
              ),
              children: <Widget>[
                if (_controller.errorMessage != null) ...<Widget>[
                  _FormErrorBanner(message: _controller.errorMessage!),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Text('Branch Information', style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _branchNameController,
                  label: 'Branch Name',
                  hintText: 'e.g. Main Branch',
                  icon: AppIcons.branch,
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Branch name is required';
                    }
                    if (value.trim().length > 160) {
                      return 'Branch name must be at most 160 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.formGroupGap),
                AppTextField(
                  controller: _codeController,
                  label: 'Branch Code (optional)',
                  hintText: 'e.g. NX-001',
                  validator: (String? value) {
                    final String trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return null;
                    if (trimmed.length > 16 || !_codePattern.hasMatch(trimmed)) {
                      return 'Use up to 16 letters, numbers, - or _';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.formGroupGap),
                AppTextField(
                  controller: _streetAddressController,
                  label: 'Street Address (optional)',
                  hintText: 'Full street address',
                ),
                const SizedBox(height: AppSpacing.formGroupGap),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppTextField(
                        controller: _cityController,
                        label: 'City (optional)',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppTextField(
                        controller: _stateController,
                        label: 'State (optional)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.formGroupGap),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppTextField(
                        controller: _countryController,
                        label: 'Country (optional)',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppTextField(
                        controller: _postalCodeController,
                        label: 'Postal Code (optional)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.formGroupGap),
                AppTextField(
                  controller: _phoneController,
                  label: _isEdit ? 'Contact Number (optional)' : 'Contact Number',
                  hintText: '10-digit mobile number',
                  icon: AppIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (String? value) {
                    final String trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return _isEdit ? null : 'Contact number is required';
                    }
                    if (!_phonePattern.hasMatch(trimmed)) {
                      return 'Enter a valid 10-digit mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.formGroupGap),
                AppTextField(
                  controller: _emailController,
                  label: _isEdit ? 'Email (optional)' : 'Email',
                  hintText: 'branch@nexoraa.com',
                  icon: AppIcons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (String? value) {
                    final String trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return _isEdit ? null : 'Email is required';
                    }
                    if (!_emailPattern.hasMatch(trimmed)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.formSectionGap),
                Text('Operating Hours', style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AppTextField(
                        controller: _openingTimeController,
                        label: 'Opening Time (optional)',
                        hintText: 'HH:mm, e.g. 09:00',
                        icon: AppIcons.clock,
                        validator: _validateTime,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppTextField(
                        controller: _closingTimeController,
                        label: 'Closing Time (optional)',
                        hintText: 'HH:mm, e.g. 21:00',
                        icon: AppIcons.clock,
                        validator: _validateTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.formSectionGap),
                Text('Management & Status', style: AppTextStyles.subtitle),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _managerIdController,
                  label: 'Manager User ID (optional)',
                  hintText: "Enter the manager's user ID",
                  icon: AppIcons.user,
                ),
                if (_isEdit && (widget.branch!.managerId?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: <Widget>[
                        Checkbox(
                          value: _unassignManager,
                          onChanged: (bool? checked) => setState(
                            () => _unassignManager = checked ?? false,
                          ),
                        ),
                        const Text('Unassign current manager'),
                      ],
                    ),
                  ),
                if (_isEdit) ...<Widget>[
                  const SizedBox(height: AppSpacing.formGroupGap),
                  AppDropdownField<BranchStatus>(
                    label: 'Status',
                    value: _status,
                    items: const <AppDropdownOption<BranchStatus>>[
                      AppDropdownOption<BranchStatus>(
                        value: BranchStatus.active,
                        label: 'Active',
                      ),
                      AppDropdownOption<BranchStatus>(
                        value: BranchStatus.inactive,
                        label: 'Inactive',
                      ),
                    ],
                    onChanged: (BranchStatus next) =>
                        setState(() => _status = next),
                  ),
                ],
                const SizedBox(height: AppSpacing.section),
                PrimaryButton(
                  label: _controller.isSubmitting
                      ? 'Saving...'
                      : (_isEdit ? 'Save Changes' : 'Create Branch'),
                  onPressed: _controller.isSubmitting ? null : _submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FormErrorBanner extends StatelessWidget {
  const _FormErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.errorSurface,
        border: AppBorders.errorCard,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: <Widget>[
            const Icon(AppIcons.alert, color: AppColors.error, size: AppSizes.iconMedium),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sentinel used only to keep [UpdateBranchInput.managerId] unset when the
/// user left the manager field untouched (as opposed to explicitly clearing
/// it) — see `branch_models.dart` for the tri-state contract.
class _KeepUnset {
  const _KeepUnset();
}
