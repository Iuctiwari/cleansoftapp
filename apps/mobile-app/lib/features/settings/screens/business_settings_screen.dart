import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

class BusinessSettingsScreen extends StatelessWidget {
  const BusinessSettingsScreen({super.key});

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
                  const Text(
                    'Business Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: <Widget>[
                  // Catalog / Services, Items / Catalog, Pricing card
                  _SettingsCard(
                    items: <_SettingsItemData>[
                      _SettingsItemData(
                        title: 'Services',
                        subtitle: 'Manage your service offerings',
                        icon: AppIcons.service,
                        iconColor: const Color(0xFF3B82F6),
                        iconBg: const Color(0xFFEFF6FF),
                        onTap: () => _handleItemTap(context, 'Services'),
                      ),
                      _SettingsItemData(
                        title: 'Items / Catalog',
                        subtitle: 'Manage your item catalog',
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFF2563EB),
                        iconBg: const Color(0xFFEFF6FF),
                        onTap: () => _handleItemTap(context, 'Items / Catalog'),
                      ),
                      _SettingsItemData(
                        title: 'Pricing',
                        subtitle: 'Set prices per item / service',
                        icon: Icons.attach_money,
                        iconColor: const Color(0xFF10B981),
                        iconBg: const Color(0xFFECFDF5),
                        onTap: () => _handleItemTap(context, 'Pricing'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Preferences Header
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      'PREFERENCES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  _SettingsCard(
                    items: <_SettingsItemData>[
                      _SettingsItemData(
                        title: 'Notifications',
                        subtitle: 'Push, SMS & in-app alerts',
                        icon: AppIcons.notifications,
                        iconColor: const Color(0xFFEF4444),
                        iconBg: const Color(0xFFFEF2F2),
                        onTap: () => _handleItemTap(context, 'Notifications'),
                      ),
                      _SettingsItemData(
                        title: 'Roles & Permissions',
                        subtitle: 'Access control for staff',
                        icon: AppIcons.shield,
                        iconColor: const Color(0xFF64748B),
                        iconBg: const Color(0xFFF1F5F9),
                        onTap: () =>
                            _handleItemTap(context, 'Roles & Permissions'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleItemTap(BuildContext context, String title) {
    try {
      if (title == 'Services') {
        context.pushNamed(AppRouteNames.settingsServices);
        return;
      }
      if (title == 'Items / Catalog') {
        context.pushNamed(AppRouteNames.settingsItems);
        return;
      }
      if (title == 'Pricing') {
        context.pushNamed(AppRouteNames.settingsPricing);
        return;
      }
      if (title == 'Notifications') {
        context.pushNamed(AppRouteNames.notifications);
        return;
      }
      if (title == 'Roles & Permissions' || title == 'Roles & Staff') {
        context.pushNamed(AppRouteNames.rolesAndStaff);
        return;
      }
    } catch (_) {
      // Ignore navigation errors in tests without GoRouter context
    }
  }
}

class _SettingsItemData {
  const _SettingsItemData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.items});

  final List<_SettingsItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: items.indexed
            .map((entry) {
              final int index = entry.$1;
              final _SettingsItemData item = entry.$2;
              final bool isLast = index == items.length - 1;

              return Column(
                children: <Widget>[
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.vertical(
                      top: index == 0 ? const Radius.circular(16) : Radius.zero,
                      bottom: isLast ? const Radius.circular(16) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: item.iconBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                item.icon,
                                color: item.iconColor,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
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
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                ],
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
