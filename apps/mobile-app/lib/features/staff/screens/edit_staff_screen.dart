import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/models/system_role.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

class EditStaffScreen extends StatefulWidget {
  final StaffMember staff;

  const EditStaffScreen({super.key, required this.staff});

  @override
  State<EditStaffScreen> createState() => _EditStaffScreenState();
}

class _EditStaffScreenState extends State<EditStaffScreen> {
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

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff.displayName);
    _emailController = TextEditingController(text: widget.staff.email);
    _mobileController = TextEditingController(text: widget.staff.mobileNumber);
    _departmentController = TextEditingController(text: widget.staff.department);
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

  SystemRole? get _currentRoleInfo {
    try {
      return _systemRoles.firstWhere((r) => r.role == _selectedRole);
    } catch (e) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
        role: _selectedRole,
        branchIds: _selectedBranchIds.isEmpty ? null : _selectedBranchIds,
      );

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Staff Details'),
      ),
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
                                  Text(_errorMessage!,
                                      style: const TextStyle(color: AppColors.error)),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                _buildSectionTitle('STAFF INFORMATION'),
                                AppTextField(
                                  label: 'Full Name *',
                                  hintText: 'Enter full name',
                                  icon: AppIcons.user,
                                  controller: _nameController,
                                  validator: (value) =>
                                      value == null || value.isEmpty ? 'Please enter a name' : null,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Login ID (Read-only)',
                                    prefixIcon: Icon(Icons.account_circle_outlined),
                                  ),
                                  controller: TextEditingController(text: widget.staff.loginId),
                                  readOnly: true,
                                ),
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
                                const SizedBox(height: AppSpacing.xxxl),
                                _buildSectionTitle('ROLE & ACCESS'),
                                _buildRoleDropdown(),
                                if (_currentRoleInfo != null) _buildRolePreview(_currentRoleInfo!),
                                const SizedBox(height: AppSpacing.xxxl),
                                _buildSectionTitle('BRANCH ASSIGNMENT'),
                                _buildBranchSelection(),
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
      child: Text(title, style: AppTextStyles.label.copyWith(color: AppColors.textSubtle)),
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
      value: roles.contains(_selectedRole) ? _selectedRole : 'Staff',
      decoration: const InputDecoration(
        labelText: 'Select Role *',
        prefixIcon: Icon(AppIcons.user),
      ),
      items: roles.map((role) {
        return DropdownMenuItem(
          value: role,
          child: Text(role),
        );
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
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${role.role} — ${role.permissions.length} permissions',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: AppSpacing.sm),
          ...role.permissions.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(AppIcons.brandCheck, size: AppIconSizes.xs, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(p, style: AppTextStyles.bodySmall)),
                  ],
                ),
              )),
        ],
      ),
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
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(AppIcons.branch,
                    color: isSelected ? AppColors.primary : AppColors.textSubtle),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(branch.branchName,
                      style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                ),
                if (isSelected) const Icon(AppIcons.brandCheck, color: AppColors.primary),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: const Icon(AppIcons.brandCheck, size: AppIconSizes.sm),
              label: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
