import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/branch/screens/branch_form_screen.dart';
import 'package:nexoraa_mobile/features/branch/services/branch_api_service.dart';
import 'package:nexoraa_mobile/features/branch/widgets/branch_stat_tile.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';

class BranchDetailsScreen extends StatefulWidget {
  const BranchDetailsScreen({required this.branch, super.key});

  final Branch branch;

  @override
  State<BranchDetailsScreen> createState() => _BranchDetailsScreenState();
}

class _BranchDetailsScreenState extends State<BranchDetailsScreen> {
  AccessPolicy get _accessPolicy =>
      AccessPolicy.fromSession(AuthenticationDependencies.controller.session);
  late Branch _branch = widget.branch;
  final StaffApiService _staffApiService = StaffApiService();
  List<StaffMember> _staff = const <StaffMember>[];
  bool _isLoadingStaff = true;
  String? _staffError;
  bool _isDeactivating = false;
  String? _actionError;

  /// True if this screen ever replaced the branch it was opened with —
  /// signals the caller (branch list) to refresh its copy on pop.
  bool _changed = false;

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
                    value: '${_branch.totalStaff}',
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
                    Text('Manager', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _branch.managerName ?? _branch.managerId ?? 'Unassigned',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Staff', style: AppTextStyles.subtitle),
                    const SizedBox(height: AppSpacing.md),
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
        style: AppTextStyles.caption,
      );
    }
    return Column(
      children: _staff.indexed
          .map(((int, StaffMember) entry) {
            final StaffMember member = entry.$2;
            final bool active = member.status.toLowerCase() == 'active';
            return Column(
              children: <Widget>[
                if (entry.$1 > 0) const Divider(height: AppSpacing.xxl),
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        _initials(member.displayName),
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.primary,
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
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(member.role, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    AppStatusBadge(
                      label: active ? 'Active' : 'Inactive',
                      tone: active
                          ? AppBadgeTone.success
                          : AppBadgeTone.neutral,
                    ),
                  ],
                ),
              ],
            );
          })
          .toList(growable: false),
    );
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
