import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/models/system_role.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StaffApiService _staffApiService = StaffApiService();

  List<StaffMember> _staff = [];
  List<SystemRole> _systemRoles = [];
<<<<<<< Updated upstream
  StaffStatistics? _staffStats;
=======
  Map<String, String> _branchNames = {};
>>>>>>> Stashed changes
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  AccessPolicy get _accessPolicy =>
      AccessPolicy.fromSession(AuthenticationDependencies.controller.session);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _accessPolicy.isOwner ? 2 : 1,
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = AuthenticationDependencies.controller.session;
      if (session == null ||
          session.tenantId == null ||
          session.tenantId!.isEmpty) {
        throw Exception('User is not logged in to a tenant.');
      }

      final futures = await Future.wait(<Future<Object>>[
        _staffApiService.getStaffMembers(session.tenantId!),
<<<<<<< Updated upstream
        if (_accessPolicy.isOwner) _staffApiService.getSystemRoles(),
=======
        _staffApiService.getSystemRoles(),
        BranchManagementDependencies.service.listBranches(pageSize: 100),
>>>>>>> Stashed changes
      ]);

      StaffStatistics? stats;
      try {
        stats = await _staffApiService.getStaffStatistics(
          session.tenantId!,
          branchId: _accessPolicy.isBranchManager ? session.branchId : null,
        );
      } catch (_) {
        // Fallback to local counts if statistics endpoint encounters network issue
      }

      setState(() {
        _staff = futures[0] as List<StaffMember>;
<<<<<<< Updated upstream
        _systemRoles = _accessPolicy.isOwner
            ? futures[1] as List<SystemRole>
            : const <SystemRole>[];
        _staffStats = stats;
=======
        _systemRoles = futures[1] as List<SystemRole>;
        final branches = (futures[2] as BranchListResult).items;
        _branchNames = {for (var b in branches) b.branchId: b.branchName};
>>>>>>> Stashed changes
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openRegisterStaff() async {
    final session = AuthenticationDependencies.controller.session;
    final tenantId = session?.tenantId ?? '';
    final bool? created = await context.pushNamed<bool>(
      AppRouteNames.staffRegister,
      extra: tenantId,
    );
    if (created == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _openRegisterStaff,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.controlMediumLarge),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                ),
                icon: const Icon(AppIcons.add, size: AppIconSizes.sm),
                label: const Text('Add Staff'),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSubtle,
          indicatorColor: AppColors.primary,
          tabs: <Widget>[
            const Tab(text: 'Staff'),
            if (_accessPolicy.isOwner) const Tab(text: 'Roles'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingView()
            : _errorMessage != null
            ? AppErrorView(message: _errorMessage!, onRetry: _loadData)
            : TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildStaffTab(),
                  if (_accessPolicy.isOwner) _buildRolesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildStaffTab() {
    // Show all active/suspended staff
    final staffList = _staff;

    // Apply search and filter
    final filteredStaff = staffList.where((s) {
      final matchesSearch =
          s.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.email.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesRole =
          _selectedRoleFilter == 'All' || s.role == _selectedRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          _buildSummaryCards(),
          const SizedBox(height: AppSpacing.lg),
          _buildSearchBar(),
          const SizedBox(height: AppSpacing.md),
          _buildRoleFilters(),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(
            onPressed: _openRegisterStaff,
            icon: const Icon(AppIcons.add),
            label: const Text('Add Staff Member'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              side: const BorderSide(
                color: AppColors.primary,
                style: BorderStyle.solid,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (filteredStaff.isEmpty)
            const AppEmptyState(
              icon: AppIcons.users,
              title: 'No staff found',
              message: 'Try adjusting your filters.',
            )
          else
<<<<<<< Updated upstream
            ...filteredStaff.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _StaffCard(
                  staff: member,
                  apiService: _staffApiService,
                  onRefresh: _loadData,
                  canRemove: _accessPolicy.isOwner,
                  canManage:
                      _accessPolicy.isOwner ||
                      member.id !=
                          AuthenticationDependencies
                              .controller
                              .session
                              ?.ownerUserId,
                ),
=======
            ...filteredStaff.map((member) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _StaffCard(
                staff: member,
                branchNames: _branchNames,
                apiService: _staffApiService,
                onRefresh: _loadData,
>>>>>>> Stashed changes
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRolesTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(AppIcons.lock, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'System roles are read-only. Contact your administrator to request permission changes.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ..._systemRoles.map(
          (role) => Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ExpansionTile(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                    child: const Icon(Icons.star, color: AppColors.warning),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(role.role, style: AppTextStyles.headingSmall),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            AppIcons.lock,
                            size: AppIconSizes.xs,
                            color: AppColors.textSubtle,
                          ),
                        ],
                      ),
                      Text(
                        '${role.permissions.length} permissions',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: role.permissions
                        .map(
                          (p) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  AppIcons.brandCheck,
                                  size: AppIconSizes.sm,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    p,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final total = _staffStats?.totalStaff ?? _staff.length;
    final active = _staffStats?.activeStaff ??
        _staff.where((s) => s.status.toLowerCase() == 'active').length;
    final pending = _staff
        .where((s) => s.status.toLowerCase() == 'pending')
        .length;
    final suspended = _staffStats?.inactiveStaff ??
        _staff.where((s) => s.status.toLowerCase() == 'suspended').length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Staff',
            count: total,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            title: 'Active',
            count: active,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            title: 'Pending Invite',
            count: pending,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SummaryCard(
            title: 'Suspended',
            count: suspended,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextFormField(
      decoration: InputDecoration(
        hintText: 'Search by name or phone...',
        prefixIcon: const Icon(AppIcons.search, color: AppColors.textSubtle),
      ),
      onChanged: (val) => setState(() => _searchQuery = val),
    );
  }

  Widget _buildRoleFilters() {
    final roles = ['All', 'Owner', 'Manager', 'Staff', 'Cashier'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: roles.map((role) {
          final isSelected = _selectedRoleFilter == role;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
<<<<<<< Updated upstream
            child: FilterChip(
              label: Text(role),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedRoleFilter = role);
              },
              backgroundColor: AppColors.surfaceMuted,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
=======
            child: GestureDetector(
              onTap: () => setState(() => _selectedRoleFilter = role),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                child: Text(
                  role,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSubtle,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
>>>>>>> Stashed changes
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
<<<<<<< Updated upstream
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppTextStyles.headingMedium.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
=======
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Text(count.toString(), style: AppTextStyles.headingLarge.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text(title, style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
>>>>>>> Stashed changes
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.staff,
    required this.branchNames,
    required this.apiService,
    required this.onRefresh,
    required this.canRemove,
    required this.canManage,
  });

  final StaffMember staff;
  final Map<String, String> branchNames;
  final StaffApiService apiService;
  final VoidCallback onRefresh;
  final bool canRemove;
  final bool canManage;

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _handleAction(BuildContext context, String action) async {
    try {
      if (action == 'suspend') {
        await apiService.suspendStaff(staff.id);
      } else if (action == 'reactivate') {
        await apiService.reactivateStaff(staff.id);
      } else if (action == 'edit_details') {
        final bool? updated = await context.pushNamed<bool>(
          AppRouteNames.staffEdit,
          pathParameters: {'staffId': staff.id},
          extra: staff,
        );
        if (updated == true) {
          onRefresh();
          return;
        }
      } else if (action == 'view_profile') {
        final bool? changed = await context.pushNamed<bool>(
          AppRouteNames.staffViewProfile,
          pathParameters: {'staffId': staff.id},
          extra: staff,
        );
        if (changed == true) {
          onRefresh();
          return;
        }
      } else if (action == 'remove') {
        await apiService.removeStaff(staff.id);
      }
      onRefresh();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = staff.status.toLowerCase();

    String branchDisplay = 'No Branch';
    if (staff.branches.isNotEmpty) {
      final firstBranchId = staff.branches.first;
      branchDisplay = branchNames[firstBranchId] ?? firstBranchId;
      if (branchDisplay.length > 20) branchDisplay = 'Main Branch';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.warning,
                    child: Text(
                      _getInitials(staff.displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: status == 'active'
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Text(staff.displayName, style: AppTextStyles.headingSmall),
                        if (staff.role.toLowerCase() == 'owner') ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(Icons.star, color: AppColors.warning, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            staff.role,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.warning,
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
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        const Icon(AppIcons.branch, size: 14, color: AppColors.textSubtle),
                        const SizedBox(width: 4),
                        Text(branchDisplay, style: AppTextStyles.caption),
                        const SizedBox(width: AppSpacing.md),
                        const Icon(AppIcons.phone, size: 14, color: AppColors.textSubtle),
                        const SizedBox(width: 4),
                        Text(staff.mobileNumber.isNotEmpty ? staff.mobileNumber : 'No Phone', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(AppIcons.more),
                onSelected: (action) => _handleAction(context, action),
                itemBuilder: (context) {
                  final items = <PopupMenuEntry<String>>[];
                  items.add(
                    const PopupMenuItem(
                      value: 'view_profile',
                      child: Text('View Profile'),
                    ),
                  );
                  if (canManage) {
                    items.add(
                      const PopupMenuItem(
                        value: 'edit_details',
                        child: Text('Edit Details'),
                      ),
                    );
                  }
                  if (canManage && status == 'active') {
                    items.add(
                      const PopupMenuItem(
                        value: 'suspend',
                        child: Text(
                          'Suspend',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }
                  if (canManage && status == 'suspended') {
                    items.add(
                      const PopupMenuItem(
                        value: 'reactivate',
                        child: Text(
                          'Reactivate',
                          style: TextStyle(color: AppColors.success),
                        ),
                      ),
                    );
                  }
                  if (canRemove) {
                    items.add(
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          'Remove Employee',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    );
                  }
                  return items;
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Icon(
                AppIcons.branch,
                size: AppIconSizes.xs,
                color: AppColors.textSubtle,
              ),
              const SizedBox(width: 4),
              Text(branchDisplay, style: AppTextStyles.caption),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                AppIcons.phone,
                size: AppIconSizes.xs,
                color: AppColors.textSubtle,
              ),
              const SizedBox(width: 4),
              Text(
                staff.mobileNumber.isNotEmpty ? staff.mobileNumber : 'No Phone',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
