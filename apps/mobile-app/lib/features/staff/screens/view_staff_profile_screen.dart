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
          IconButton(
            icon: const Icon(AppIcons.edit),
            onPressed: () async {
              final bool? updated = await context.pushNamed<bool>(
                AppRouteNames.staffEdit,
                extra: widget.staff,
              );
              if (updated == true && mounted) {
                context.pop(true);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingView()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                child: Column(
                  children: [
                    _buildHeader(status),
                    const SizedBox(height: AppSpacing.xxxl),
                    _buildInfoSection(),
                    const SizedBox(height: AppSpacing.xxxl),
                    _buildActionButtons(status),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(String status) {
    return Column(
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
                width: 20,
                height: 20,
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
        const SizedBox(height: AppSpacing.lg),
        Text(widget.staff.displayName, style: AppTextStyles.headingMedium),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            widget.staff.role,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSizes.sm, color: AppColors.textSubtle),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
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
