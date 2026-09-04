import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/branch/services/branch_api_service.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

class AssignBranchManagerScreen extends StatefulWidget {
  const AssignBranchManagerScreen({required this.branch, super.key});

  final Branch branch;

  @override
  State<AssignBranchManagerScreen> createState() =>
      _AssignBranchManagerScreenState();
}

class _AssignBranchManagerScreenState extends State<AssignBranchManagerScreen> {
  final StaffApiService _staffApiService = StaffApiService();
  late Future<List<StaffMember>> _staffFuture;
  StaffMember? _selectedStaff;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final session = AuthenticationDependencies.controller.session;
    final tenantId = session?.tenantId ?? widget.branch.tenantId;
    _staffFuture = _staffApiService.getStaffMembers(tenantId);
  }

  String _getFirstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0] : 'Manager';
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'M';
    if (parts.length == 1) {
      final s = parts[0];
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(int index) {
    const colors = <Color>[
      Color(0xFF2563EB), // Blue
      Color(0xFF6C38CC), // Purple
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEC4899), // Pink
      Color(0xFF06B6D4), // Cyan
    ];
    return colors[index % colors.length];
  }

  Future<void> _submitAssignment() async {
    if (_selectedStaff == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final Branch updated = await BranchManagementDependencies.service
          .updateBranch(
            widget.branch.branchId,
            UpdateBranchInput(
              managerId: _selectedStaff!.id,
              managerIdChanged: true,
            ),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Branch Manager assigned to ${_selectedStaff!.displayName}.',
          ),
        ),
      );
      Navigator.of(context).pop(updated);
    } on BranchApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.userMessage)));
    } on BranchApiNetworkException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign branch manager.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String branchName = widget.branch.branchName;
    final String actionWorkerName = _selectedStaff != null
        ? _getFirstName(_selectedStaff!.displayName)
        : 'Manager';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Assign Branch Manager',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<StaffMember>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Failed to load available staff.',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          final session =
                              AuthenticationDependencies.controller.session;
                          final tenantId =
                              session?.tenantId ?? widget.branch.tenantId;
                          _staffFuture = _staffApiService.getStaffMembers(
                            tenantId,
                          );
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final List<StaffMember> staffList = snapshot.data ?? <StaffMember>[];

          return Column(
            children: <Widget>[
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.md,
                    AppSpacing.pageHorizontal,
                    AppSpacing.pageBottom,
                  ),
                  children: <Widget>[
                    // Branch Reference Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1D4ED8),
                                  fontWeight: FontWeight.w500,
                                ),
                                children: <InlineSpan>[
                                  const TextSpan(
                                    text: 'Assigning manager for ',
                                  ),
                                  TextSpan(
                                    text: branchName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Section Heading
                    const Text(
                      'Select Manager',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (staffList.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: const Center(
                          child: Text(
                            'No eligible staff members found for this tenant.',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      ...List<Widget>.generate(staffList.length, (int index) {
                        final StaffMember staff = staffList[index];
                        final bool isCurrentManager =
                            widget.branch.managerId == staff.id;
                        final bool isSelected = _selectedStaff?.id == staff.id;
                        final bool isOffline =
                            staff.status.toLowerCase() == 'inactive';
                        final Color avatarBg = _getAvatarColor(index);
                        final String initials = _getInitials(staff.displayName);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: InkWell(
                            onTap: isOffline
                                ? null
                                : () {
                                    setState(() {
                                      _selectedStaff = isSelected
                                          ? null
                                          : staff;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFF0F7FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFFE2E8F0),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x08000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  // Avatar with status dot
                                  Stack(
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: avatarBg,
                                        foregroundColor: Colors.white,
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: isOffline
                                                ? const Color(0xFF94A3B8)
                                                : const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),

                                  // Details Column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Flexible(
                                              child: Text(
                                                staff.displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (isCurrentManager)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFEFF6FF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'Current',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              )
                                            else
                                              _buildStatusBadge(staff.status),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          staff.role,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Status text
                                        Row(
                                          children: <Widget>[
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: isOffline
                                                    ? const Color(0xFF94A3B8)
                                                    : const Color(0xFF10B981),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isOffline
                                                  ? 'Inactive'
                                                  : 'Eligible for manager',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),

              // Sticky Bottom CTA
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: _isSubmitting
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person_add_alt_1_outlined,
                                    size: 18,
                                  ),
                            label: Text(
                              _isSubmitting
                                  ? 'Assigning...'
                                  : 'Assign $actionWorkerName',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF93C5FD),
                              disabledForegroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _selectedStaff != null && !_isSubmitting
                                ? _submitAssignment
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final String lower = status.toLowerCase();
    final Color bg;
    final Color fg;
    final String label;

    if (lower == 'active' || lower == 'available') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF10B981);
      label = 'Active';
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF94A3B8);
      label = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
