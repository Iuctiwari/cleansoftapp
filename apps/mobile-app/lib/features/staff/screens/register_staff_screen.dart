import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/staff/models/system_role.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';

class RegisterStaffScreen extends StatefulWidget {
  final String tenantId;

  const RegisterStaffScreen({super.key, required this.tenantId});

  @override
  State<RegisterStaffScreen> createState() => _RegisterStaffScreenState();
}

class _RegisterStaffScreenState extends State<RegisterStaffScreen> {
  AccessPolicy get _accessPolicy =>
      AccessPolicy.fromSession(AuthenticationDependencies.controller.session);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _departmentController = TextEditingController();
  final _staffApiService = StaffApiService();

  String _selectedRole = 'Staff';
  List<Branch> _availableBranches = [];
  final List<String> _selectedBranchIds = [];
  List<SystemRole> _systemRoles = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _passwordVisible = false;
  bool _confirmVisible = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBranchIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign at least one branch')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _staffApiService.registerStaff(
        tenantId: widget.tenantId,
        name: _nameController.text.trim(),
        loginId: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
        email: _emailController.text.trim().toLowerCase(),
        mobileNumber: _mobileController.text.trim().isEmpty
            ? null
            : _mobileController.text.trim(),
        department: _departmentController.text.trim().isEmpty
            ? null
            : _departmentController.text.trim(),
        role: _selectedRole,
        branches: _selectedBranchIds,
      );
      if (mounted) context.pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = e is StaffApiException ? e.userMessage : e.toString();
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Staff Member'), centerTitle: true),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingView()
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                        children: [
                          Text('Enter details to create a new staff account', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSubtle)),
                          const SizedBox(height: AppSpacing.xl),
                          if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),

                    // ── Personal Info ───────────────────────────────────────
                    _sectionTitle('STAFF INFORMATION'),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name is required'
                          : null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(AppIcons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Email is required';
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(v.trim()))
                          return 'Enter a valid email';
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: Icon(AppIcons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Department',
                        prefixIcon: Icon(AppIcons.branch),
                      ),
                      textInputAction: TextInputAction.next,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // ── Login Credentials ───────────────────────────────────
                    _sectionTitle('Login Credentials'),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'The employee will use these to sign in to the app.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSubtle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible,
                          ),
                        ),
                        helperText:
                            'Min 8 chars, upper + lower + number + special',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.isEmpty)
                          return 'Password is required';
                        if (v.length < 8)
                          return 'At least 8 characters required';
                        if (!v.contains(RegExp(r'[A-Z]')))
                          return 'Add an uppercase letter';
                        if (!v.contains(RegExp(r'[a-z]')))
                          return 'Add a lowercase letter';
                        if (!v.contains(RegExp(r'[0-9]')))
                          return 'Add a number';
                        if (!v.contains(RegExp(r'[^A-Za-z0-9]')))
                          return 'Add a special character';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_confirmVisible,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password *',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _confirmVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _confirmVisible = !_confirmVisible,
                          ),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (v) => v != _passwordController.text
                          ? 'Passwords do not match'
                          : null,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // ── Role ────────────────────────────────────────────────
                    _sectionTitle('Role'),
                    const SizedBox(height: AppSpacing.md),
                    _buildRoleDropdown(),
                    if (_currentRoleInfo != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildRolePreview(_currentRoleInfo!),
                    ],

                    const SizedBox(height: AppSpacing.xxl),

                    // ── Branches ────────────────────────────────────────────
                    _sectionTitle('BRANCH ASSIGNMENT'),
                    _buildBranchList(),

                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
              Container(
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
                        icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, size: 18),
                        label: Text(_isSubmitting ? 'Creating...' : 'Create Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: AppTextStyles.headingSmall);

  Widget _buildRoleDropdown() {
    final roles = _accessPolicy.isOwner
        ? <String>['Branch Manager', 'Staff']
        : <String>['Staff'];
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Permissions:', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          ...role.permissions.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(Icons.check, size: 14, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(p, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchList() {
    if (_availableBranches.isEmpty) {
      return Text('No branches available', style: AppTextStyles.bodySmall);
    }
    return Column(
      children: _availableBranches.map((branch) {
        final selected = _selectedBranchIds.contains(branch.branchId);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
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
              color: selected ? AppColors.primary.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 2),
                    color: selected ? AppColors.primary : Colors.transparent,
                  ),
                  child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch.branchName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      if (branch.isHeadOffice)
                        Text('Head Office', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
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
}
