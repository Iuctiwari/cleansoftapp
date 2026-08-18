import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';
import 'package:nexoraa_mobile/features/payments/controllers/payments_controller.dart';
import 'package:nexoraa_mobile/features/payments/screens/payments_screen.dart';

@immutable
class MoreUserProfileData {
  const MoreUserProfileData({required this.email, required this.name});

  static const MoreUserProfileData placeholder = MoreUserProfileData(
    email: 'user@example.com',
    name: 'User',
  );

  final String email;
  final String name;
}

@immutable
class MoreMenuItemData {
  const MoreMenuItemData({
    required this.backgroundColor,
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  final Color backgroundColor;
  final IconData icon;
  final Color iconColor;
  final String title;
}

@immutable
class MoreMenuSectionData {
  const MoreMenuSectionData({required this.items, required this.title});

  final List<MoreMenuItemData> items;
  final String title;
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    required this.businessName,
    required this.role,
    required this.userProfile,
    this.branchId,
    this.orderController,
    super.key,
  });

  final String businessName;
  final String role;
  final MoreUserProfileData userProfile;
  final String? branchId;
  final OrderController? orderController;

  static const List<MoreMenuSectionData> _sections = <MoreMenuSectionData>[
    MoreMenuSectionData(
      title: 'Finance',
      items: <MoreMenuItemData>[
        MoreMenuItemData(
          backgroundColor: AppColors.successSurface,
          icon: AppIcons.payment,
          iconColor: AppColors.successLight,
          title: 'Payments',
        ),
        MoreMenuItemData(
          backgroundColor: AppColors.warningSurface,
          icon: AppIcons.receipt,
          iconColor: AppColors.warning,
          title: 'Expenses',
        ),
        MoreMenuItemData(
          backgroundColor: AppColors.secondarySurface,
          icon: AppIcons.money,
          iconColor: AppColors.secondary,
          title: 'Cash Register',
        ),
      ],
    ),
    MoreMenuSectionData(
      title: 'Analytics',
      items: <MoreMenuItemData>[
        MoreMenuItemData(
          backgroundColor: AppColors.primarySurface,
          icon: AppIcons.analytics,
          iconColor: AppColors.primary,
          title: 'Reports',
        ),
      ],
    ),
    MoreMenuSectionData(
      title: 'Business',
      items: <MoreMenuItemData>[
        MoreMenuItemData(
          backgroundColor: AppColors.infoSurface,
          icon: AppIcons.users,
          iconColor: AppColors.info,
          title: 'Staff Management',
        ),
        MoreMenuItemData(
          backgroundColor: AppColors.successSurface,
          icon: AppIcons.activity,
          iconColor: AppColors.successLight,
          title: 'Worker Availability',
        ),
        MoreMenuItemData(
          backgroundColor: AppColors.indigoSurface,
          icon: AppIcons.branch,
          iconColor: AppColors.indigo,
          title: 'Branch Management',
        ),
        MoreMenuItemData(
          backgroundColor: AppColors.surfaceMuted,
          icon: AppIcons.settings,
          iconColor: AppColors.textMuted,
          title: 'Business Settings',
        ),
      ],
    ),
    MoreMenuSectionData(
      title: 'Account',
      items: <MoreMenuItemData>[
        MoreMenuItemData(
          backgroundColor: AppColors.primarySurface,
          icon: AppIcons.user,
          iconColor: AppColors.primary,
          title: 'My Profile',
        ),
      ],
    ),
  ];

  void _showPlaceholder(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$title is not available yet.')));
  }

  void _handleItemTap(BuildContext context, MoreMenuItemData item) {
    if (item.title == 'Branch Management') {
      context.pushNamed(AppRouteNames.branchList);
      return;
    }
    if (item.title == 'Payments') {
      _openPayments(context);
      return;
    }
    _showPlaceholder(context, item.title);
  }

  Future<void> _openPayments(BuildContext context) async {
    final String? scopedBranchId = branchId;
    final OrderController? scopedOrderController = orderController;
    if (scopedBranchId == null ||
        scopedBranchId == 'unavailable' ||
        scopedOrderController == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Select an active branch before viewing payments.'),
          ),
        );
      return;
    }
    final PaymentApiService paymentService = PaymentApiService(
      tokenStorage: AuthenticationDependencies.tokenStorage,
    )..selectBranch(scopedBranchId);
    final PaymentsController controller = PaymentsController(
      paymentService: paymentService,
      orderController: scopedOrderController,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentsScreen(controller: controller),
      ),
    );
    controller.dispose();
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.surface,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Yes, Sign Out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    await AuthenticationDependencies.controller.signOut();
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Signed out successfully')));
    context.goNamed(AppRouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: <Widget>[
        const SliverAppBar(pinned: true, title: Text('More')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.xl,
            AppSpacing.pageHorizontal,
            AppSpacing.pageBottom,
          ),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.authenticationContentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    MoreProfileCard(
                      businessName: businessName,
                      email: userProfile.email,
                      onTap: () => _showPlaceholder(context, 'My Profile'),
                      role: role,
                      userName: userProfile.name,
                    ),
                    const SizedBox(height: AppSpacing.xxlPlus),
                    ..._sections.map(
                      (MoreMenuSectionData section) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.xxlPlus,
                        ),
                        child: MoreMenuSection(
                          section: section,
                          onItemTap: (MoreMenuItemData item) =>
                              _handleItemTap(context, item),
                        ),
                      ),
                    ),
                    SignOutCard(onTap: () => _confirmSignOut(context)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MoreProfileCard extends StatelessWidget {
  const MoreProfileCard({
    required this.businessName,
    required this.email,
    required this.onTap,
    required this.role,
    required this.userName,
    super.key,
  });

  final String businessName;
  final String email;
  final VoidCallback onTap;
  final String role;
  final String userName;

  String get _initials {
    final List<String> words = userName
        .trim()
        .split(' ')
        .where((String word) => word.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return _MoreSurface(
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardInsets,
          child: Row(
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: AppRadius.avatar(AppSizes.avatarHero),
                ),
                child: SizedBox.square(
                  dimension: AppSizes.avatarHero,
                  child: Center(
                    child: Text(
                      _initials,
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '$role · $businessName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                AppIcons.chevronRight,
                color: AppColors.textSubtle,
                size: AppIconSizes.lg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoreMenuSection extends StatelessWidget {
  const MoreMenuSection({
    required this.onItemTap,
    required this.section,
    super.key,
  });

  final ValueChanged<MoreMenuItemData> onItemTap;
  final MoreMenuSectionData section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs),
          child: Text(
            section.title.toUpperCase(),
            style: AppTextStyles.labelUppercase.copyWith(
              color: AppColors.textSubtle,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _MoreSurface(
          child: Column(
            children: section.items.indexed
                .map(((int, MoreMenuItemData) entry) {
                  return Column(
                    children: <Widget>[
                      MoreMenuTile(
                        item: entry.$2,
                        onTap: () => onItemTap(entry.$2),
                      ),
                      if (entry.$1 < section.items.length - 1)
                        const Divider(height: AppBorderWidths.hairline),
                    ],
                  );
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class MoreMenuTile extends StatelessWidget {
  const MoreMenuTile({required this.item, required this.onTap, super.key});

  final MoreMenuItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xlPlus,
        ),
        child: Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: item.backgroundColor,
                borderRadius: AppRadius.inputRadius,
              ),
              child: SizedBox.square(
                dimension: AppSizes.touchTarget,
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: AppIconSizes.xl,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(child: Text(item.title, style: AppTextStyles.bodyLarge)),
            const Icon(
              AppIcons.chevronRight,
              color: AppColors.textDisabled,
              size: AppIconSizes.lg,
            ),
          ],
        ),
      ),
    );
  }
}

class SignOutCard extends StatelessWidget {
  const SignOutCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _MoreSurface(
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xlPlus,
          ),
          child: Row(
            children: <Widget>[
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.errorSurface,
                  borderRadius: AppRadius.inputRadius,
                ),
                child: SizedBox.square(
                  dimension: AppSizes.touchTarget,
                  child: Icon(
                    AppIcons.logout,
                    color: AppColors.error,
                    size: AppIconSizes.xl,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Text(
                  'Sign Out',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreSurface extends StatelessWidget {
  const _MoreSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: AppBorders.cardDefault,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadius.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
