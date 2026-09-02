import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

class ViewStaffProfileScreen extends StatefulWidget {
  final StaffMember staff;

  const ViewStaffProfileScreen({super.key, required this.staff});

  @override
  State<ViewStaffProfileScreen> createState() => _ViewStaffProfileScreenState();
}

class _ViewStaffProfileScreenState extends State<ViewStaffProfileScreen> {
  final _staffApiService = StaffApiService();
  bool _isLoading = false;

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _handleAction(String action) async {
    setState(() => _isLoading = true);
    try {
      if (action == 'suspend') {
        await _staffApiService.suspendStaff(widget.staff.id);
      } else if (action == 'reactivate') {
        await _staffApiService.reactivateStaff(widget.staff.id);
      }
      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.staff.status.toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Profile'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(AppIcons.more),
            onSelected: (action) async {
              if (action == 'edit') {
                final bool? updated = await context.pushNamed<bool>(
                  AppRouteNames.staffEdit,
                  extra: widget.staff,
                );
                if (updated == true && mounted) {
                  context.pop(true);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit Profile')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingView()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(status),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: AppSpacing.xl),
                    _buildInfoSection(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildStatsSection(status),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildAssignedBranches(),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildRolePermissions(),
                    const SizedBox(height: AppSpacing.xxxl),
                    _buildActionButtons(status),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(String status) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                _getInitials(widget.staff.displayName),
                style: const TextStyle(
                  fontSize: 32,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: status == 'active'
                      ? AppColors.success
                      : AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.staff.displayName, style: AppTextStyles.headingMedium),
              if (widget.staff.department.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.staff.department,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.staff.role,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'active'
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: status == 'active'
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(AppIcons.email, 'Email Address', widget.staff.email),
          const Divider(height: 1, color: AppColors.border),
          _buildInfoRow(
            AppIcons.phone,
            'Mobile Number',
            widget.staff.mobileNumber.isNotEmpty
                ? widget.staff.mobileNumber
                : 'Not provided',
          ),
          const Divider(height: 1, color: AppColors.border),
          _buildInfoRow(
            AppIcons.branch,
            'Department',
            widget.staff.department.isNotEmpty
                ? widget.staff.department
                : 'Not assigned',
          ),
          const Divider(height: 1, color: AppColors.border),
          _buildInfoRow(
            Icons.home_work_outlined,
            'Branches',
            widget.staff.branches.isNotEmpty
                ? widget.staff.branches.join(', ')
                : 'No branches assigned',
          ),
        ],
      ),
    );
  }

  String _getMonthYear(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildCompactInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSubtle),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(String status) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Text('32', style: AppTextStyles.headingLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Orders / month', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: status == 'active' ? AppColors.success.withOpacity(0.05) : AppColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              children: [
                Text(status == 'active' ? 'Active' : 'Suspended', style: AppTextStyles.headingLarge.copyWith(color: status == 'active' ? AppColors.success : AppColors.error, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Status', style: AppTextStyles.caption.copyWith(color: status == 'active' ? AppColors.success : AppColors.error)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedBranches() {
    final branchName = widget.staff.branches.isNotEmpty ? widget.staff.branches.first : 'No Branch';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ASSIGNED BRANCHES', style: AppTextStyles.label.copyWith(color: AppColors.textSubtle)),
            TextButton(
              onPressed: () {},
              child: const Text('Manage'),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(AppIcons.branch, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(branchName.length > 20 ? 'Main Branch' : branchName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Primary Branch', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRolePermissions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('ROLE PERMISSIONS', style: AppTextStyles.label.copyWith(color: AppColors.textSubtle)),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Orders', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildPermissionChip('View assigned orders'),
                  _buildPermissionChip('Update order status'),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Customers', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildPermissionChip('View customers'),
                  _buildPermissionChip('Add customers'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.brandCheck, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == 'active')
          OutlinedButton.icon(
            onPressed: () => _handleAction('suspend'),
            icon: const Icon(AppIcons.close, color: AppColors.error),
            label: const Text(
              'Suspend Account',
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error),
            ),
          )
        else if (status == 'suspended')
          OutlinedButton.icon(
            onPressed: () => _handleAction('reactivate'),
            icon: const Icon(AppIcons.brandCheck, color: AppColors.success),
            label: const Text(
              'Reactivate Account',
              style: TextStyle(color: AppColors.success),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.success),
            ),
          ),
      ],
    );
  }
}
