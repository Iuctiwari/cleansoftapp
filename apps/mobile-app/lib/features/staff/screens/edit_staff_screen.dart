import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/models/system_role.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';

class EditStaffScreen extends StatefulWidget {
  final StaffMember staff;

  const EditStaffScreen({super.key, required this.staff});

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
  AccessPolicy get _accessPolicy =>
      AccessPolicy.fromSession(AuthenticationDependencies.controller.session);
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _departmentController;

  final _staffApiService = StaffApiService();

  late String _selectedRole;
  List<Branch> _availableBranches = [];
  late List<String> _selectedBranchIds;
  List<SystemRole> _systemRoles = [];

  late bool _customAccess = widget.staff.accessCustom;
  late final Set<String> _perms = widget.staff.customPermissions.toSet();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.displayName);
    _emailController = TextEditingController(text: widget.staff.email);
    _mobileController = TextEditingController(text: widget.staff.mobileNumber);
    _departmentController = TextEditingController(
      text: widget.staff.department,
    );
    _selectedRole = widget.staff.role;
    _selectedBranchIds = List.from(widget.staff.branches);
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final futures = await Future.wait([
        BranchManagementDependencies.service.listBranches(pageSize: 100),
        _staffApiService.getSystemRoles(),
      ]);

      setState(() {
        _availableBranches = (futures[0] as BranchListResult).items;
        _systemRoles = futures[1] as List<SystemRole>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool get _accessChanged {
    if (!_accessPolicy.isOwner || _selectedRole != 'Staff') return false;
    if (_customAccess != widget.staff.accessCustom) return true;
    return _customAccess && !_sameSet(_perms, widget.staff.customPermissions.toSet());
  }

  static bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  SystemRole? get _currentRoleInfo {
    try {
      return _systemRoles.firstWhere((r) => r.role == _selectedRole);
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      await AppAlertDialog.show(
        context,
        title: 'Required information',
        message: 'Please fix the highlighted fields before saving.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _staffApiService.updateStaff(
        userId: widget.staff.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        department: _departmentController.text.trim(),
        role: _accessPolicy.isOwner ? _selectedRole : null,
        branchIds: _accessPolicy.isOwner && _selectedBranchIds.isNotEmpty
            ? _selectedBranchIds
            : null,
        // Only sent when the owner actually changed it (a change signs that person out).
        accessMode: _accessChanged ? (_customAccess ? 'custom' : 'default') : null,
        permissions: _accessChanged && _customAccess ? _perms.toList() : null,
      );

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      final String message = e is StaffApiException ? e.userMessage : e.toString();
      setState(() {
        _errorMessage = message;
        _isSubmitting = false;
      });
      if (mounted) {
        await AppAlertDialog.show(context, title: AppAlertDialog.titleFor(message), message: message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Staff Details')),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingView()
            : _errorMessage != null && _systemRoles.isEmpty
            ? AppErrorView(message: _errorMessage!, onRetry: _loadData)
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage != null) ...[
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppColors.error),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                            _buildSectionTitle('STAFF INFORMATION'),
                            AppTextField(
                              label: 'Full Name *',
                              hintText: 'Enter full name',
                              icon: AppIcons.user,
                              controller: _nameController,
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Please enter a name'
                                  : null,
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              label: 'Email',
                              hintText: 'Email address',
                              icon: AppIcons.email,
                              controller: _emailController,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              label: 'Mobile Number',
                              hintText: 'Mobile number',
                              icon: AppIcons.phone,
                              controller: _mobileController,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppTextField(
                              label: 'Department',
                              hintText: 'e.g. Laundry, Finance',
                              icon: AppIcons.branch,
                              controller: _departmentController,
                            ),
                            if (_accessPolicy.isOwner) ...<Widget>[
                              const SizedBox(height: AppSpacing.xxxl),
                              _buildSectionTitle('ROLE & ACCESS'),
                              _buildRoleDropdown(),
                              if (_currentRoleInfo != null)
                                _buildRolePreview(_currentRoleInfo!),
                              if (_selectedRole == 'Staff') ...[
                                const SizedBox(height: AppSpacing.xxxl),
                                _buildSectionTitle('MODULE ACCESS'),
                                _buildModuleAccess(),
                              ],
                              const SizedBox(height: AppSpacing.xxxl),
                              _buildSectionTitle('BRANCH ASSIGNMENT'),
                              _buildBranchSelection(),
                            ],
                            const SizedBox(height: AppSpacing.xxxl),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: AppTextStyles.label.copyWith(color: AppColors.textSubtle),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    final roles = ['Branch Manager', 'Staff'];
    // Default to 'Staff' if current selection is not in the list
    if (!roles.contains(_selectedRole)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedRole = 'Staff';
        });
      });
    }

    return DropdownButtonFormField<String>(
      initialValue: roles.contains(_selectedRole) ? _selectedRole : 'Staff',
      decoration: const InputDecoration(
        labelText: 'Select Role *',
        prefixIcon: Icon(AppIcons.user),
      ),
      items: roles.map((role) {
        return DropdownMenuItem(value: role, child: Text(role));
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRole = value;
          });
        }
      },
    );
  }

  Widget _buildRolePreview(SystemRole role) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${role.role} — ${role.permissions.length} permissions',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...role.permissions.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    AppIcons.brandCheck,
                    size: AppIconSizes.xs,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(p, style: AppTextStyles.bodySmall)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // (label, read permission, write permission or null)
  static const List<(String, String, String?)> _modules = [
    ('Orders', 'orders:read', 'orders:write'),
    ('Customers', 'customers:read', 'customers:write'),
    ('Payments', 'payments:read', 'payments:write'),
    ('Expenses', 'expenses:read', 'expenses:write'),
    ('Reports', 'reports:read', null),
    ('Cash register', 'cash-register:access', null),
  ];

  /// Default = what the Staff role normally gets. Custom = the owner ticks each module.
  Widget _buildModuleAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          key: const Key('staff.access.mode'),
          segments: const [
            ButtonSegment<bool>(value: false, label: Text('Default')),
            ButtonSegment<bool>(value: true, label: Text('Custom')),
          ],
          selected: {_customAccess},
          onSelectionChanged: (Set<bool> value) {
            setState(() {
              _customAccess = value.first;
              // Starting custom access from "nothing" would lock the person out by surprise,
              // so begin from the Staff defaults.
              if (_customAccess && _perms.isEmpty) {
                _perms.addAll(const [
                  'orders:read',
                  'orders:write',
                  'customers:read',
                  'customers:write',
                ]);
              }
            });
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _customAccess
              ? 'Switch on only what this person needs. They keep notifications and their own profile.'
              : 'Uses the standard Staff access: orders and customers.',
          style: AppTextStyles.caption,
        ),
        if (_customAccess)
          for (final (String label, String read, String? write) in _modules) ...[
            const Divider(),
            Text(label, style: AppTextStyles.labelBold),
            SwitchListTile(
              key: Key('staff.access.${read}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('See ${label.toLowerCase()}'),
              value: _perms.contains(read),
              onChanged: (bool on) {
                setState(() {
                  if (on) {
                    _perms.add(read);
                  } else {
                    _perms.remove(read);
                    if (write != null) _perms.remove(write);
                  }
                });
              },
            ),
            if (write != null)
              SwitchListTile(
                key: Key('staff.access.${write}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  label == 'Orders'
                      ? 'Create & update orders'
                      : label == 'Payments'
                      ? 'Record payments'
                      : 'Add & edit ${label.toLowerCase()}',
                ),
                value: _perms.contains(write),
                onChanged: (bool on) {
                  setState(() {
                    if (on) {
                      _perms
                        ..add(write)
                        ..add(read);
                    } else {
                      _perms.remove(write);
                    }
                  });
                },
              ),
          ],
        if (_accessChanged) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This person will be signed out and must sign in again for the new access to apply.',
            style: AppTextStyles.caption,
          ),
        ],
      ],
    );
  }

  Widget _buildBranchSelection() {
    if (_availableBranches.isEmpty) {
      return const Text('No branches available');
    }
    return Column(
      children: _availableBranches.map((branch) {
        final isSelected = _selectedBranchIds.contains(branch.branchId);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedBranchIds.remove(branch.branchId);
              } else {
                _selectedBranchIds.add(branch.branchId);
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch.branchName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (branch.isHeadOffice)
                        Text(
                          'Head Office',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check, size: 18),
              label: Text(_isSubmitting ? 'Saving...' : 'Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
