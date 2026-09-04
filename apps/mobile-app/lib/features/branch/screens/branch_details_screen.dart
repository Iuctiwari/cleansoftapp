import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/branch/screens/assign_branch_manager_screen.dart';
import 'package:nexoraa_mobile/features/branch/screens/branch_form_screen.dart';
import 'package:nexoraa_mobile/features/branch/services/branch_api_service.dart';
import 'package:nexoraa_mobile/features/branch/widgets/branch_stat_tile.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/screens/staff_management_screen.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

class BranchDetailsScreen extends StatefulWidget {
  const BranchDetailsScreen({
    required this.branch,
    this.staffApiService,
    super.key,
  });

  final Branch branch;
  final StaffApiService? staffApiService;

  @override
  State<BranchDetailsScreen> createState() => _BranchDetailsScreenState();
}

class _BranchDetailsScreenState extends State<BranchDetailsScreen> {
  AccessPolicy get _accessPolicy =>
      AccessPolicy.fromSession(AuthenticationDependencies.controller.session);
  late Branch _branch = widget.branch;
  late final StaffApiService _staffApiService =
      widget.staffApiService ?? StaffApiService();
  List<StaffMember> _tenantStaff = const <StaffMember>[];
  List<StaffMember> _staff = const <StaffMember>[];
  bool _isLoadingStaff = true;
  String? _staffError;
  bool _isDeactivating = false;
  String? _actionError;

  /// True if this screen ever replaced the branch it was opened with —
  /// signals the caller (branch list) to refresh its copy on pop.
  bool _changed = false;

  bool get _canManage =>
      _accessPolicy.isOwner ||
      _accessPolicy.isBranchManager ||
      _accessPolicy.allows(AppCapability.branchesEdit);

  StaffMember? get _assignedManager {
    if (_branch.managerId == null || _branch.managerId!.isEmpty) return null;
    return _tenantStaff.cast<StaffMember?>().firstWhere(
      (m) => m?.id == _branch.managerId,
      orElse: () => null,
    );
  }

  String? get _managerDisplayName {
    final StaffMember? manager = _assignedManager;
    if (manager != null && manager.displayName.isNotEmpty) {
      return manager.displayName;
    }
    if (_branch.managerName != null && _branch.managerName!.isNotEmpty) {
      return _branch.managerName;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoadingStaff = true;
      _staffError = null;
    });
    try {
      final List<StaffMember> tenantStaff = await _staffApiService
          .getStaffMembers(_branch.tenantId);

      if (!mounted) return;
      setState(() {
        _tenantStaff = tenantStaff;
        _staff = tenantStaff
            .where((member) => member.branches.contains(_branch.branchId))
            .toList(growable: false);
        _isLoadingStaff = false;
      });
    } on StaffApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _staffError = error.userMessage;
        _isLoadingStaff = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _staffError = 'Unable to load branch staff.';
        _isLoadingStaff = false;
      });
    }
  }

  Future<void> _openEdit() async {
    final Branch? updated = await Navigator.of(context).push<Branch>(
      MaterialPageRoute<Branch>(
        builder: (_) =>
            BranchFormScreen(mode: BranchFormMode.edit, branch: _branch),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _branch = updated;
        _changed = true;
      });
      await _loadStaff();
    }
  }

  Future<void> _openAssignManager() async {
    final Branch? updated = await Navigator.of(context).push<Branch>(
      MaterialPageRoute<Branch>(
        builder: (_) => AssignBranchManagerScreen(branch: _branch),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _branch = updated;
        _changed = true;
      });
      await _loadStaff();
    }
  }

  Future<void> _openAssignStaff() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const StaffManagementScreen()),
    );
    if (mounted) {
      await _loadStaff();
    }
  }

  Future<void> _deactivate() async {
    final bool confirmed = await AppConfirmDialog.show(
      context,
      title: 'Deactivate Branch?',
      message:
          'Are you sure you want to deactivate this branch? It will no longer '
          'be available for active operations.',
      confirmLabel: 'Deactivate',
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _isDeactivating = true;
      _actionError = null;
    });

    try {
      final Branch updated = await BranchManagementDependencies.service
          .deactivateBranch(_branch.branchId);
      if (!mounted) return;
      setState(() {
        _branch = updated;
        _changed = true;
        _isDeactivating = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Branch deactivated')));
    } on BranchApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeactivating = false;
        _actionError = error.userMessage;
      });
    } on BranchApiNetworkException catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeactivating = false;
        _actionError = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? managerName = _managerDisplayName;
    final String managerStatus = _assignedManager?.status ?? 'Active';

    return PopScope<Branch>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Branch? _) {
        if (didPop) return;
        Navigator.of(context).pop<Branch>(_changed ? _branch : null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Branch Details'),
          actions: <Widget>[
            IconButton(onPressed: _openEdit, icon: const Icon(AppIcons.edit)),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.xl,
              AppSpacing.pageHorizontal,
              AppSpacing.pageBottom,
            ),
            children: <Widget>[
              if (_actionError != null) ...<Widget>[
                _ErrorBanner(message: _actionError!),
                const SizedBox(height: AppSpacing.xl),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _branch.branchName,
                            style: AppTextStyles.headingMedium,
                          ),
                        ),
                        AppStatusBadge(
                          label: _branch.status == BranchStatus.active
                              ? 'Active'
                              : 'Inactive',
                          tone: _branch.status == BranchStatus.active
                              ? AppBadgeTone.success
                              : AppBadgeTone.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (managerName != null && managerName.isNotEmpty)
                      _InfoRow(
                        icon: AppIcons.user,
                        label: 'Manager',
                        value: managerName,
                      ),
                    if (_branch.code != null)
                      _InfoRow(
                        icon: AppIcons.branch,
                        label: 'Branch Code',
                        value: _branch.code!,
                      ),
                    if (_branch.streetAddress.isNotEmpty)
                      _InfoRow(
                        icon: AppIcons.location,
                        label: 'Address',
                        value: <String>[
                          _branch.streetAddress,
                          _branch.city,
                          _branch.state,
                          _branch.country,
                          _branch.postalCode,
                        ].where((String value) => value.isNotEmpty).join(', '),
                      ),
                    if (_branch.phone.isNotEmpty)
                      _InfoRow(
                        icon: AppIcons.phone,
                        label: 'Contact',
                        value: _branch.phone,
                      ),
                    if (_branch.email.isNotEmpty)
                      _InfoRow(
                        icon: AppIcons.email,
                        label: 'Email',
                        value: _branch.email,
                      ),
                    if (_branch.openingTime != null &&
                        _branch.closingTime != null)
                      _InfoRow(
                        icon: AppIcons.clock,
                        label: 'Hours',
                        value:
                            '${_branch.openingTime} - ${_branch.closingTime}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              BranchStatRow(
                tiles: <BranchStatTile>[
                  BranchStatTile(
                    value: '${_staff.length}',
                    label: 'Total Staff',
                    color: AppColors.success,
                    background: AppColors.successSurface,
                  ),
                  BranchStatTile(
                    value: '${_branch.ordersToday}',
                    label: 'Orders Today',
                    color: AppColors.primary,
                    background: AppColors.primarySurface,
                  ),
                  BranchStatTile(
                    value: '${_branch.totalOrders}',
                    label: 'Total Orders',
                    color: AppColors.secondary,
                    background: AppColors.secondarySurface,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Branch Manager',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (_canManage)
                          _PillButton(
                            label: 'Assign Manager',
                            onPressed: _openAssignManager,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (managerName != null && managerName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFF2563EB),
                              child: Text(
                                _initials(managerName),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    managerName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Branch Manager',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusDot(managerStatus),
                          ],
                        ),
                      )
                    else
                      const Text(
                        'No branch manager assigned.',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Staff (${_staff.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (_canManage)
                          _PillButton(
                            label: 'Assign Staff',
                            onPressed: _openAssignStaff,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStaffContent(),
                  ],
                ),
              ),
              if (_accessPolicy.isOwner &&
                  _branch.status == BranchStatus.active) ...<Widget>[
                const SizedBox(height: AppSpacing.section),
                Text(
                  'DANGER ZONE',
                  style: AppTextStyles.labelUppercase.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  borderColor: AppColors.errorBorder,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Deactivate Branch',
                              style: AppTextStyles.bodyLarge,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              'Branch will stop accepting new orders',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _isDeactivating ? null : _deactivate,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.errorBorder),
                        ),
                        child: Text(
                          _isDeactivating ? 'Deactivating...' : 'Deactivate',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffContent() {
    if (_isLoadingStaff) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_staffError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_staffError!, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: _loadStaff,
            icon: const Icon(AppIcons.refresh),
            label: const Text('Try again'),
          ),
        ],
      );
    }
    if (_staff.isEmpty) {
      return const Text(
        'No staff are assigned to this branch.',
        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
      );
    }
    return Column(
      children: _staff.indexed
          .map(((int, StaffMember) entry) {
            final int index = entry.$1;
            final StaffMember member = entry.$2;
            final Color avatarBg = _getAvatarColor(index);
            final String roleLabel = member.department.isNotEmpty
                ? member.department
                : member.role;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index < _staff.length - 1 ? AppSpacing.md : 0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: avatarBg,
                      child: Text(
                        _initials(member.displayName),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            member.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roleLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusDot(
                      member.availability.isNotEmpty
                          ? member.availability
                          : member.status,
                    ),
                  ],
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildStatusDot(String status) {
    final String lower = status.toLowerCase();
    final Color color;
    final String label;

    if (lower == 'active' || lower == 'available') {
      color = const Color(0xFF10B981);
      label = 'Available';
    } else if (lower == 'busy') {
      color = const Color(0xFFF59E0B);
      label = 'Busy';
    } else if (lower == 'on break' || lower == 'break') {
      color = const Color(0xFFEA580C);
      label = 'On Break';
    } else {
      color = const Color(0xFF94A3B8);
      label = 'Offline';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getAvatarColor(int index) {
    const colors = <Color>[
      Color(0xFF2563EB), // Blue
      Color(0xFF7C3AED), // Purple
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFFEC4899), // Pink
      Color(0xFF06B6D4), // Cyan
    ];
    return colors[index % colors.length];
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2563EB),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.textMuted, size: AppSizes.iconSmall),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: AppTextStyles.label),
                const SizedBox(height: AppSpacing.xxs),
                Text(value, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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
            const Icon(
              AppIcons.alert,
              color: AppColors.error,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.errorText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
