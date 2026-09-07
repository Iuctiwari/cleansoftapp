import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/models/system_role.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

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
  StaffStatistics? _staffStats;
  Map<String, String> _branchNames = {};
  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _selectedRoleFilter = 'All';

  AccessPolicy get _accessPolicy =>
      AccessPolicy.fromSession(AuthenticationDependencies.controller.session);

  @override
  void initState() {
    super.initState();
    // In the design there are 3 tabs: Staff, Invitations, Roles
    _tabController = TabController(
      length: _accessPolicy.isOwner ? 3 : 2,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
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
        if (_accessPolicy.isOwner) _staffApiService.getSystemRoles(),
        BranchManagementDependencies.service.listBranches(pageSize: 100),
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
        _systemRoles = _accessPolicy.isOwner
            ? futures[1] as List<SystemRole>
            : const <SystemRole>[];
        _staffStats = stats;
        final branchResult = futures.length > (_accessPolicy.isOwner ? 2 : 1)
            ? futures.last as BranchListResult
            : null;
        if (branchResult != null) {
          _branchNames = {
            for (var b in branchResult.items) b.branchId: b.branchName,
          };
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e is StaffApiException ? e.userMessage : e.toString();
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRouteNames.dashboard);
            }
          },
        ),
        title: Text(
          'Staff Management',
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _openRegisterStaff,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text(
                  'Invite',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const AppLoadingView()
            : _errorMessage != null
            ? AppErrorView(message: _errorMessage!, onRetry: _loadData)
            : Column(
                children: [
                  _buildCustomTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        _buildStaffTab(),
                        const Center(child: Text('Invitations (Coming soon)')),
                        if (_accessPolicy.isOwner) _buildRolesTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    final tabs = ['Staff', 'Invitations', if (_accessPolicy.isOwner) 'Roles'];
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (index) {
          final isSelected = _tabController.index == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(index),
              child: Container(
                margin: EdgeInsets.only(right: index < tabs.length - 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
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
          if (filteredStaff.isEmpty)
            const AppEmptyState(
              icon: AppIcons.users,
              title: 'No staff found',
              message: 'Try adjusting your filters.',
            )
          else
            ...filteredStaff.map(
              (member) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _StaffCard(
                  staff: member,
                  branchNames: _branchNames,
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
    final active =
        _staffStats?.activeStaff ??
        _staff.where((s) => s.status.toLowerCase() == 'active').length;
    final pending = _staff
        .where((s) => s.status.toLowerCase() == 'pending')
        .length;
    final suspended =
        _staffStats?.inactiveStaff ??
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextFormField(
        decoration: InputDecoration(
          hintText: 'Search by name or phone...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
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
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRoleFilter = role),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
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
    final String availability = staff.availability.isNotEmpty
        ? staff.availability
        : (status == 'active' ? 'Available' : 'Offline');
    final (Color availColor, Color availBg) = switch (availability
        .toLowerCase()) {
      'busy' => (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      'on break' ||
      'break' => (const Color(0xFFEA580C), const Color(0xFFFFEDD5)),
      'offline' ||
      'suspended' ||
      'inactive' => (const Color(0xFF94A3B8), const Color(0xFFF1F5F9)),
      _ => (const Color(0xFF10B981), const Color(0xFFECFDF5)),
    };

    String branchDisplay = 'No Branch';
    if (staff.branches.isNotEmpty) {
      final firstBranchId = staff.branches.first;
      branchDisplay = branchNames[firstBranchId] ?? firstBranchId;
      if (branchDisplay.length > 20) branchDisplay = 'Main Branch';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _getAvatarColor(staff.displayName),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
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
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: availColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  staff.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (staff.role.toLowerCase() == 'owner') ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.star,
                                  color: Colors.deepOrange,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onSelected: (action) =>
                              _handleAction(context, action),
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
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: staff.role.toLowerCase() == 'owner'
                                ? Colors.orange.withOpacity(0.1)
                                : Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            staff.role,
                            style: TextStyle(
                              color: staff.role.toLowerCase() == 'owner'
                                  ? Colors.orange
                                  : Colors.purple,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
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
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status == 'active'
                                ? 'Active'
                                : status.substring(0, 1).toUpperCase() +
                                      status.substring(1),
                            style: TextStyle(
                              color: status == 'active'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: availBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            availability.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: availColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.storefront,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          branchDisplay,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          staff.mobileNumber.isNotEmpty
                              ? staff.mobileNumber
                              : 'No Phone',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _handleAction(context, 'view_profile'),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.05),
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (canManage &&
                  status == 'active' &&
                  staff.id !=
                      AuthenticationDependencies
                          .controller
                          .session
                          ?.ownerUserId) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => _handleAction(context, 'suspend'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.05),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Suspend',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.blue,
      Colors.redAccent,
      Colors.teal,
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }
}
