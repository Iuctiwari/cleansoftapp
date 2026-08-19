import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class ProfileData {
  const ProfileData({
    required this.displayName,
    required this.email,
    required this.role,
    required this.businessName,
    required this.phone,
    required this.location,
    required this.memberSince,
    required this.plan,
    required this.branch,
    required this.passwordLastChanged,
  });

  /// Build from the live [AuthenticationSession] coming from the backend JWT.
  /// Falls back to placeholder strings so the UI always renders.
  factory ProfileData.fromSession(AuthenticationSession? session) {
    return ProfileData(
      displayName: session?.ownerName ?? 'User',
      email: session?.ownerEmail ?? '—',
      role: 'Owner',
      businessName: session?.businessName ?? '—',
      phone: '—', // not yet stored in session; extend when user-service returns it
      location: '—', // not yet stored in session; extend when user-service returns it
      memberSince: 'Jan 2025', // will come from tenant.createdAt once wired
      plan: 'Pro', // will come from subscription when wired
      branch: 'Main', // will come from selected branch when wired
      passwordLastChanged: '30 days ago', // will come from user-service when wired
    );
  }

  final String displayName;
  final String email;
  final String role;
  final String businessName;
  final String phone;
  final String location;
  final String memberSince;
  final String plan;
  final String branch;
  final String passwordLastChanged;

  /// Two-letter initials from the display name.
  String get initials {
    final words = displayName
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

@immutable
class _RoleOption {
  const _RoleOption({
    required this.title,
    required this.subtitle,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final bool isActive;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

/// My Profile screen — matches the two-screenshot design exactly.
///
/// Backend-integration notes (for when the remaining services are wired):
///   • [ProfileData.fromSession] is the single entry point — extend the factory
///     with additional fields as the user-service / tenant-service APIs mature.
///   • Sign-out calls [AuthenticationController.signOut] (clears tokens via
///     flutter_secure_storage) then navigates directly to the login page via
///     GoRouter so the router's auth-guard does not need to do anything extra.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _activeRoleIndex = 0;

  static const List<_RoleOption> _roles = <_RoleOption>[
    _RoleOption(
      title: 'Owner',
      subtitle: 'Full access to all features',
      isActive: true,
    ),
    _RoleOption(
      title: 'Branch Manager',
      subtitle: 'Branch operations & staff',
      isActive: false,
    ),
    _RoleOption(
      title: 'Staff Member',
      subtitle: 'Assigned orders only',
      isActive: false,
    ),
  ];

  Future<void> _signOut() async {
    await AuthenticationDependencies.controller.signOut();
    if (!mounted) return;
    context.goNamed(AppRouteNames.login);
  }

  void _onEditPressed() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Edit profile coming soon.')),
      );
  }

  void _onChangePassword() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Change password coming soon.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final session = AuthenticationDependencies.controller.session;
    final data = ProfileData.fromSession(session);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: <Widget>[
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            leading: IconButton(
              icon: const Icon(AppIcons.arrowBack),
              onPressed: () => context.pop(),
            ),
            title: const Text('My Profile'),
            actions: <Widget>[
              IconButton(
                icon: const Icon(AppIcons.edit),
                onPressed: _onEditPressed,
                tooltip: 'Edit profile',
              ),
            ],
          ),

          // ── Scrollable body ───────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.xxl,
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
                      // ── Avatar + name ───────────────────────────────────
                      _ProfileHeader(data: data),
                      const SizedBox(height: AppSpacing.xxlPlus),

                      // ── Personal Information ────────────────────────────
                      _ProfileSection(
                        title: 'PERSONAL INFORMATION',
                        children: <Widget>[
                          _InfoTile(
                            icon: AppIcons.branch,
                            label: 'Business',
                            value: data.businessName,
                          ),
                          const _SectionDivider(),
                          _InfoTile(
                            icon: AppIcons.phone,
                            label: 'Phone',
                            value: data.phone,
                          ),
                          const _SectionDivider(),
                          _InfoTile(
                            icon: AppIcons.email,
                            label: 'Email',
                            value: data.email,
                          ),
                          const _SectionDivider(),
                          _InfoTile(
                            icon: AppIcons.location,
                            label: 'Location',
                            value: data.location,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Security ────────────────────────────────────────
                      _ProfileSection(
                        title: 'SECURITY',
                        children: <Widget>[
                          _SecurityTile(
                            icon: AppIcons.key,
                            title: 'Change Password',
                            subtitle: 'Last changed ${data.passwordLastChanged}',
                            onTap: _onChangePassword,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Stats row ───────────────────────────────────────
                      _StatsRow(data: data),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Role Switch ─────────────────────────────────────
                      _ProfileSection(
                        title: 'ROLE SWITCH',
                        headerSubtitle: 'Demo mode — switch dashboard view',
                        children: List<Widget>.generate(
                          _roles.length,
                          (int i) => Column(
                            children: <Widget>[
                              _RoleTile(
                                role: _roles[i],
                                isSelected: _activeRoleIndex == i,
                                onTap: () => setState(() => _activeRoleIndex = i),
                              ),
                              if (i < _roles.length - 1)
                                const _SectionDivider(),
                            ],
                          ),
                          growable: false,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // ── Sign Out button ─────────────────────────────────
                      _SignOutButton(onTap: _signOut),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.data});

  final ProfileData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        // Avatar circle
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.avatar(AppSizes.avatarHero),
          ),
          child: SizedBox.square(
            dimension: AppSizes.avatarHero,
            child: Center(
              child: Text(
                data.initials,
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Name
        Text(
          data.displayName,
          textAlign: TextAlign.center,
          style: AppTextStyles.headingSmall,
        ),
        const SizedBox(height: AppSpacing.xs),

        // Role badge
        Text(
          data.role,
          textAlign: TextAlign.center,
          style: AppTextStyles.captionBold.copyWith(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),

        // Business name
        Text(
          data.businessName,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

// ── Section card wrapper ─────────────────────────────────────────────────────

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
    this.headerSubtitle,
  });

  final String title;
  final String? headerSubtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Section label row
        Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: Text(
                title,
                style: AppTextStyles.labelUppercase.copyWith(
                  color: AppColors.textSubtle,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (headerSubtitle != null) ...<Widget>[
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '— ${headerSubtitle!}',
                  style: AppTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Card
        _CardSurface(
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Info tile (Personal Information rows) ────────────────────────────────────

class _InfoTile extends StatelessWidget {
  const _InfoTile({
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lgPlus,
      ),
      child: Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.inputRadius,
            ),
            child: SizedBox.square(
              dimension: AppSizes.touchTarget,
              child: Icon(icon, color: AppColors.textMuted, size: AppIconSizes.xl),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: AppTextStyles.bodyLarge),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Security tile ────────────────────────────────────────────────────────────

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.cardRadius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lgPlus,
        ),
        child: Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: AppRadius.inputRadius,
              ),
              child: SizedBox.square(
                dimension: AppSizes.touchTarget,
                child: Icon(
                  icon,
                  color: AppColors.textMuted,
                  size: AppIconSizes.xl,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
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

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.data});

  final ProfileData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _StatChip(value: data.memberSince, label: 'Member Since')),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: _StatChip(value: data.plan, label: 'Plan')),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: _StatChip(value: data.branch, label: 'Branch')),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return _CardSurface(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xl,
          horizontal: AppSpacing.md,
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              textAlign: TextAlign.center,
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Role tile ────────────────────────────────────────────────────────────────

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  final _RoleOption role;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          borderRadius: AppRadius.cardRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lgPlus,
          ),
          child: Row(
            children: <Widget>[
              // Role indicator dot
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : AppColors.textDisabled,
                ),
                child: const SizedBox.square(dimension: 10),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      role.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      role.subtitle,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Text(
                  'Active',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sign Out button ──────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.errorSurface,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        borderRadius: AppRadius.cardRadius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(AppIcons.logout, color: AppColors.error, size: AppIconSizes.xl),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Sign Out',
                style: AppTextStyles.buttonLarge.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared card surface ──────────────────────────────────────────────────────

class _CardSurface extends StatelessWidget {
  const _CardSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: child,
    );
  }
}

// ── Hairline divider inside sections ────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.8,
      color: AppColors.border,
      indent: AppSpacing.xl + AppSizes.touchTarget + AppSpacing.xl,
    );
  }
}
