import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';
import 'package:nexoraa_mobile/features/tenant/services/tenant_api_service.dart';

class RolesAndStaffScreen extends StatefulWidget {
  const RolesAndStaffScreen({super.key, this.staffApiService, this.session});

  final StaffApiService? staffApiService;
  final AuthenticationSession? session;

  @override
  State<RolesAndStaffScreen> createState() => _RolesAndStaffScreenState();
}

class _RolesAndStaffScreenState extends State<RolesAndStaffScreen> {
  int _selectedTabIndex = 0; // 0: Staff, 1: Roles
  bool _isLoading = false;
  String? _errorMessage;
  String _tenantOwnerName = 'Owner';
  List<StaffMember> _branchStaff = <StaffMember>[];

  late final StaffApiService _staffApiService;

  @override
  void initState() {
    super.initState();
    _staffApiService =
        widget.staffApiService ??
        StaffApiService(tokenStorage: AuthenticationDependencies.tokenStorage);
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AuthenticationSession? session =
          widget.session ??
          AuthenticationDependencies.controller.session ??
          await AuthenticationDependencies.tokenStorage.read();
      final String? tenantId = session?.tenantId?.trim();
      if (tenantId == null || tenantId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'User session not found.';
          });
        }
        return;
      }

      final TenantApiService tenantApi = TenantApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      );
      String resolvedOwnerName = 'Owner';

      // 1. Fetch real Tenant Profile to always get the genuine Tenant Owner
      try {
        final profile = await tenantApi.getTenantProfile(tenantId);
        if (profile.ownerName.trim().isNotEmpty) {
          resolvedOwnerName = profile.ownerName.trim();
        }
      } catch (_) {
        if (session?.roleCode.toLowerCase() == 'owner' &&
            session?.ownerName != null &&
            session!.ownerName!.trim().isNotEmpty) {
          resolvedOwnerName = session.ownerName!.trim();
        }
      }

      // 2. Resolve active branch for branch-isolation
      String? activeBranchId = session?.branchId?.trim();
      if (activeBranchId == null || activeBranchId.isEmpty) {
        try {
          final List<TenantBranch> branches = await tenantApi.listBranches(
            tenantId,
          );
          if (branches.isNotEmpty) {
            activeBranchId = branches.first.branchId;
          }
        } catch (_) {
          // Fall back gracefully
        }
      }

      if (activeBranchId != null && activeBranchId.isNotEmpty) {
        _staffApiService.selectBranch(activeBranchId);
      }

      // 3. Fetch all staff for the tenant
      final List<StaffMember> allStaff = await _staffApiService.getStaffMembers(
        tenantId,
      );

      // Check if owner is listed in staff to retrieve real name if needed
      final StaffMember? ownerStaff = allStaff.cast<StaffMember?>().firstWhere(
        (StaffMember? m) =>
            m?.role.toLowerCase() == 'owner' ||
            m?.role.toLowerCase() == 'tenant owner' ||
            m?.role.toLowerCase() == 'tenant_owner',
        orElse: () => null,
      );
      if (ownerStaff != null && ownerStaff.displayName.isNotEmpty) {
        resolvedOwnerName = ownerStaff.displayName;
      }

      // 4. Strict tenant & branch isolation for staff members (excluding Owner)
      final List<StaffMember> filtered = allStaff
          .where((StaffMember member) {
            if (member.role.toLowerCase() == 'owner') return false;
            if (activeBranchId != null && activeBranchId.isNotEmpty) {
              return member.branches.contains(activeBranchId);
            }
            return false;
          })
          .toList(growable: true);

      // If logged in as Branch Manager and not yet returned in staff list, include them
      final bool isViewerManager =
          session?.roleCode.toLowerCase() == 'branch manager' ||
          session?.roleCode.toLowerCase() == 'branch_manager';
      final bool managerInList = filtered.any(
        (StaffMember m) =>
            m.role.toLowerCase() == 'branch manager' ||
            m.role.toLowerCase() == 'branch_manager' ||
            m.role.toLowerCase() == 'manager',
      );

      if (isViewerManager && !managerInList) {
        filtered.insert(
          0,
          StaffMember(
            id: session?.ownerUserId ?? 'current-manager',
            tenantId: tenantId,
            email: session?.ownerEmail ?? '',
            phone: '',
            status: 'Active',
            role: 'Branch Manager',
            branches: <String>[if (activeBranchId != null) activeBranchId],
            firstName: session?.ownerName ?? 'Branch Manager',
            loginId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _tenantOwnerName = resolvedOwnerName;
          _branchStaff = filtered;
          _isLoading = false;
        });
      }
    } on StaffApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.userMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load staff members.';
        });
      }
    }
  }

  void _updateStaffRole(String staffId, String newRole) {
    setState(() {
      _branchStaff = _branchStaff.map((StaffMember s) {
        if (s.id == staffId) {
          return StaffMember(
            id: s.id,
            tenantId: s.tenantId,
            email: s.email,
            phone: s.phone,
            status: s.status,
            availability: s.availability,
            role: newRole,
            branches: s.branches,
            firstName: s.firstName,
            lastName: s.lastName,
            departmentValue: s.departmentValue,
            loginId: s.loginId,
            createdAt: s.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        return s;
      }).toList();
    });
  }

  String _getInitials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(int index) {
    const List<Color> colors = <Color>[
      Color(0xFF7C3AED), // Purple
      Color(0xFF059669), // Emerald
      Color(0xFFEA580C), // Orange
      Color(0xFF0284C7), // Sky Blue
      Color(0xFFDB2777), // Pink
      Color(0xFF4F46E5), // Indigo
    ];
    return colors[index % colors.length];
  }

  String _displayRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'branch manager':
      case 'branch_manager':
      case 'manager':
        return 'Branch Manager';
      case 'cashier':
        return 'Cashier';
      case 'worker':
      case 'staff':
      default:
        return 'Worker';
    }
  }

  ({Color bg, Color text}) _getRoleBadgeColors(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return (bg: const Color(0xFFFEF9C3), text: const Color(0xFFA16207));
      case 'branch manager':
      case 'branch_manager':
      case 'manager':
        return (bg: const Color(0xFFF5F3FF), text: const Color(0xFF7C3AED));
      case 'cashier':
        return (bg: const Color(0xFFECFDF5), text: const Color(0xFF10B981));
      case 'worker':
      case 'staff':
      default:
        return (bg: const Color(0xFFEFF6FF), text: const Color(0xFF2563EB));
    }
  }

  void _showPermissionsSheet(String roleName, List<String> permissions) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '$roleName Permissions',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...permissions.map(
                  (String p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          AppIcons.arrowBack,
                          size: 20,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Roles & Staff',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage access control',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Selector (Staff / Roles)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 0),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              'Staff',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _selectedTabIndex == 0
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedTabIndex = 1),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? const Color(0xFF2563EB)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              'Roles',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _selectedTabIndex == 1
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildStaffTab()
                  : _buildRolesTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffTab() {
    // Separate Branch Manager and other Staff/Workers
    StaffMember? branchManager;
    final List<StaffMember> otherStaff = <StaffMember>[];

    for (final StaffMember member in _branchStaff) {
      final String role = member.role.toLowerCase();
      if (branchManager == null &&
          (role == 'branch manager' ||
              role == 'branch_manager' ||
              role == 'manager')) {
        branchManager = member;
      } else {
        otherStaff.add(member);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        // 1. OWNER CARD (Always Tenant Owner at top, visually separated)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF59E0B),
                child: Text(
                  _getInitials(_tenantOwnerName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _tenantOwnerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Owner',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFA16207),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. BRANCH MANAGER CARD (Immediately below Owner if present)
        if (branchManager != null) ...<Widget>[
          _buildStaffCard(branchManager, index: 0, isManager: true),
        ],

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          )
        else if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          )
        else if (branchManager == null && otherStaff.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No staff members assigned to this branch.',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          )
        else
          // 3. OTHER BRANCH STAFF (Workers and Cashiers)
          ...otherStaff.indexed.map((entry) {
            final int index = entry.$1 + (branchManager != null ? 1 : 0);
            final StaffMember staff = entry.$2;
            return _buildStaffCard(staff, index: index, isManager: false);
          }),
      ],
    );
  }

  Widget _buildStaffCard(
    StaffMember staff, {
    required int index,
    required bool isManager,
  }) {
    final Color avatarColor = _getAvatarColor(index);
    final String displayRole = _displayRoleName(staff.role);
    final ({Color bg, Color text}) roleColors = _getRoleBadgeColors(
      displayRole,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarColor,
            child: Text(
              _getInitials(staff.displayName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  staff.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: roleColors.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayRole,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: roleColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              // Role Selector dropdown (Options: Branch Manager, Worker, Cashier)
              _RoleDropdown(
                currentRole: displayRole,
                onChanged: (String newRole) =>
                    _updateStaffRole(staff.id, newRole),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _showPermissionsSheet(
                  displayRole,
                  _getPermissionsForRole(displayRole),
                ),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'View Permissions',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRolesTab() {
    final List<
      ({
        String title,
        String subtitle,
        IconData icon,
        Color iconColor,
        Color iconBg,
        List<String> permissions,
      })
    >
    roles =
        <
          ({
            String title,
            String subtitle,
            IconData icon,
            Color iconColor,
            Color iconBg,
            List<String> permissions,
          })
        >[
          (
            title: 'Owner',
            subtitle: 'Full access — non-editable',
            icon: Icons.star,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            permissions: <String>[
              'Full administrative access',
              'Manage business & branch settings',
              'Manage all staff, roles & permissions',
              'View financial reports & payments',
              'Manage services & pricing',
            ],
          ),
          (
            title: 'Branch Manager',
            subtitle: '14 permissions enabled',
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFFF5F3FF),
            permissions: <String>[
              'Manage branch orders',
              'Assign workers & pressers',
              'View branch reports & cash register',
              'Manage branch staff & availability',
              'Record branch expenses & payments',
            ],
          ),
          (
            title: 'Worker',
            subtitle: '4 permissions enabled',
            icon: Icons.group_outlined,
            iconColor: const Color(0xFF3B82F6),
            iconBg: const Color(0xFFEFF6FF),
            permissions: <String>[
              'View assigned tasks & orders',
              'Update task & order progress',
              'Set staff availability status',
              'View customer contact for task',
            ],
          ),
          (
            title: 'Cashier',
            subtitle: '6 permissions enabled',
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFECFDF5),
            permissions: <String>[
              'Create new customer orders',
              'Accept payments & print receipts',
              'Manage cash register sessions',
              'View customer profiles',
            ],
          ),
        ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: roles.length,
      itemBuilder: (BuildContext context, int index) {
        final role = roles[index];
        return InkWell(
          onTap: () => _showPermissionsSheet(role.title, role.permissions),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: role.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(role.icon, color: role.iconColor, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        role.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  AppIcons.chevronRight,
                  size: 20,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _getPermissionsForRole(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return <String>[
          'Full administrative access',
          'Manage business & branch settings',
          'Manage all staff, roles & permissions',
          'View financial reports & payments',
        ];
      case 'branch manager':
      case 'branch_manager':
      case 'manager':
        return <String>[
          'Manage branch orders',
          'Assign workers & pressers',
          'View branch reports & cash register',
          'Manage branch staff & availability',
        ];
      case 'cashier':
        return <String>[
          'Create new customer orders',
          'Accept payments & print receipts',
          'Manage cash register sessions',
        ];
      case 'worker':
      case 'staff':
      default:
        return <String>[
          'View assigned tasks & orders',
          'Update task & order progress',
          'Set staff availability status',
        ];
    }
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({required this.currentRole, required this.onChanged});

  final String currentRole;
  final ValueChanged<String> onChanged;

  static const List<String> staffRoles = <String>[
    'Branch Manager',
    'Worker',
    'Cashier',
  ];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFF1F5F9),
      surfaceTintColor: Colors.transparent,
      itemBuilder: (BuildContext context) => staffRoles
          .map((String role) {
            final bool isSelected = role == currentRole;
            return PopupMenuItem<String>(
              value: role,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    role,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check, size: 16, color: Color(0xFF2563EB)),
                ],
              ),
            );
          })
          .toList(growable: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              currentRole,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}
