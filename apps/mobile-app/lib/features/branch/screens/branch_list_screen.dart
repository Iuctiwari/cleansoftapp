import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/branch/branch_dependencies.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/branch/controllers/branch_list_controller.dart';
import 'package:nexoraa_mobile/features/branch/widgets/branch_stat_tile.dart';

class BranchListScreen extends StatefulWidget {
  const BranchListScreen({super.key});

  @override
  State<BranchListScreen> createState() => _BranchListScreenState();
}

class _BranchListScreenState extends State<BranchListScreen> {
  late final BranchListController _controller = BranchListController(
    service: BranchManagementDependencies.service,
  );
  late final ScrollController _scrollController = ScrollController()
    ..addListener(_onScroll);

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  Future<void> _openAddBranch() async {
    final Branch? created = await context.pushNamed<Branch>(
      AppRouteNames.branchAdd,
    );
    if (created != null) {
      await _controller.load(statusFilter: _controller.statusFilter);
    }
  }

  Future<void> _openDetails(Branch branch) async {
    final Branch? updated = await context.pushNamed<Branch>(
      AppRouteNames.branchDetails,
      pathParameters: <String, String>{'branchId': branch.branchId},
      extra: branch,
    );
    if (updated != null) {
      _controller.replaceBranch(updated);
    }
  }

  Future<void> _openEdit(Branch branch) async {
    final Branch? updated = await context.pushNamed<Branch>(
      AppRouteNames.branchEdit,
      pathParameters: <String, String>{'branchId': branch.branchId},
      extra: branch,
    );
    if (updated != null) {
      _controller.replaceBranch(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branches'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _openAddBranch,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.controlMediumLarge),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                ),
                icon: const Icon(AppIcons.add, size: AppIconSizes.sm),
                label: const Text('Add Branch'),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (BuildContext context, Widget? _) {
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.xl,
                    AppSpacing.pageHorizontal,
                    AppSpacing.lg,
                  ),
                  child: BranchStatRow(
                    tiles: <BranchStatTile>[
                      BranchStatTile(
                        value: '${_controller.total}',
                        label: 'Branches',
                        color: AppColors.primary,
                        background: AppColors.primarySurface,
                      ),
                      // Total Staff has no backing API yet; kept at 0 until
                      // Staff Management ships (see branch feature notes).
                      const BranchStatTile(
                        value: '0',
                        label: 'Total Staff',
                        color: AppColors.success,
                        background: AppColors.successSurface,
                      ),
                      // Orders Today has no backing API yet; kept at 0 until
                      // Order Management ships.
                      const BranchStatTile(
                        value: '0',
                        label: 'Orders Today',
                        color: AppColors.secondary,
                        background: AppColors.secondarySurface,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.none,
                    AppSpacing.pageHorizontal,
                    AppSpacing.lg,
                  ),
                  child: _StatusFilterBar(
                    value: _controller.statusFilter,
                    onChanged: (BranchStatus? next) =>
                        _controller.load(statusFilter: next),
                    total: _controller.total,
                  ),
                ),
                Expanded(child: _buildBody(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.status) {
      case BranchListStatus.initial:
      case BranchListStatus.loading:
        return const AppLoadingView();
      case BranchListStatus.error:
        return AppErrorView(
          message: _controller.errorMessage ?? 'Something went wrong.',
          onRetry: () =>
              _controller.load(statusFilter: _controller.statusFilter),
        );
      case BranchListStatus.loaded:
        if (_controller.branches.isEmpty) {
          return const AppEmptyState(
            icon: AppIcons.branch,
            title: 'No branches yet',
            message: 'Add your first branch to get started.',
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              _controller.load(statusFilter: _controller.statusFilter),
          child: ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.none,
              AppSpacing.pageHorizontal,
              AppSpacing.pageBottom,
            ),
            itemCount:
                _controller.branches.length +
                (_controller.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (BuildContext context, int index) {
              if (index >= _controller.branches.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              final Branch branch = _controller.branches[index];
              return _BranchCard(
                branch: branch,
                onTap: () => _openDetails(branch),
                onEdit: () => _openEdit(branch),
              );
            },
          ),
        );
    }
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.value,
    required this.onChanged,
    required this.total,
  });

  final BranchStatus? value;
  final ValueChanged<BranchStatus?> onChanged;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AppDropdownField<BranchStatus?>(
            label: 'Status',
            value: value,
            icon: AppIcons.filter,
            items: const <AppDropdownOption<BranchStatus?>>[
              AppDropdownOption<BranchStatus?>(
                value: null,
                label: 'All branches',
              ),
              AppDropdownOption<BranchStatus?>(
                value: BranchStatus.active,
                label: 'Active',
              ),
              AppDropdownOption<BranchStatus?>(
                value: BranchStatus.inactive,
                label: 'Inactive',
              ),
            ],
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: Text('$total total', style: AppTextStyles.caption),
        ),
      ],
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.onTap,
    required this.onEdit,
  });

  final Branch branch;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(branch.branchName, style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.xs),
                    AppStatusBadge(
                      label: branch.status == BranchStatus.active
                          ? 'Active'
                          : 'Inactive',
                      tone: branch.status == BranchStatus.active
                          ? AppBadgeTone.success
                          : AppBadgeTone.neutral,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onEdit,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.controlMedium),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                ),
                icon: const Icon(AppIcons.edit, size: AppSizes.iconSmall),
                label: const Text('Edit'),
              ),
            ],
          ),
          if (branch.streetAddress.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                const Icon(
                  AppIcons.location,
                  color: AppColors.textSubtle,
                  size: AppSizes.iconSmall,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    branch.streetAddress,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          if (branch.phone.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const Icon(
                  AppIcons.phone,
                  color: AppColors.textSubtle,
                  size: AppSizes.iconSmall,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(branch.phone, style: AppTextStyles.bodySmall),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              const Icon(
                AppIcons.users,
                color: AppColors.textSubtle,
                size: AppSizes.iconSmall,
              ),
              const SizedBox(width: AppSpacing.xs),
              // Staff count is not yet available from Branch Service.
              const Text('0 staff', style: AppTextStyles.caption),
              const SizedBox(width: AppSpacing.lg),
              const Icon(
                AppIcons.orders,
                color: AppColors.textSubtle,
                size: AppSizes.iconSmall,
              ),
              const SizedBox(width: AppSpacing.xs),
              // Orders-today is not yet available from Branch Service.
              const Text('0 orders today', style: AppTextStyles.caption),
              if (branch.managerId?.isNotEmpty ?? false) ...<Widget>[
                const Spacer(),
                const Icon(
                  AppIcons.user,
                  color: AppColors.textSubtle,
                  size: AppSizes.iconSmall,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    branch.managerId!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
