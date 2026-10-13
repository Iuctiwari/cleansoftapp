import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/staff/models/system_role.dart';

/// (label, read permission, write permission or null) — the modules an owner can switch.
const List<(String, String, String?)> kRoleModules = <(String, String, String?)>[
  ('Orders', 'orders:read', 'orders:write'),
  ('Customers', 'customers:read', 'customers:write'),
  ('Payments', 'payments:read', 'payments:write'),
  ('Expenses', 'expenses:read', 'expenses:write'),
  ('Reports', 'reports:read', null),
  ('Cash register', 'cash-register:access', null),
];

/// The owner ticks which modules everyone with this role gets in the shop.
/// Pops the chosen permissions, or nothing when cancelled.
class RoleAccessSheet extends StatefulWidget {
  const RoleAccessSheet({required this.role, super.key});

  final SystemRole role;

  @override
  State<RoleAccessSheet> createState() => _RoleAccessSheetState();
}

class _RoleAccessSheetState extends State<RoleAccessSheet> {
  late final Set<String> _perms = widget.role.permissions.toSet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Text('Access for ${widget.role.role}', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Switch on what everyone with this role can use in your shop. '
              'People already signed in will need to sign in again.',
              style: AppTextStyles.caption,
            ),
            for (final (String label, String read, String? write) in kRoleModules) ...<Widget>[
              const Divider(),
              Text(label, style: AppTextStyles.labelBold),
              SwitchListTile(
                key: Key('role.access.$read'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('See ${label.toLowerCase()}'),
                value: _perms.contains(read),
                onChanged: (bool on) {
                  setState(() {
                    if (on) {
                      _perms.add(read);
                    } else {
                      _perms.remove(read);
                      if (write != null) _perms.remove(write);
                    }
                  });
                },
              ),
              if (write != null)
                SwitchListTile(
                  key: Key('role.access.$write'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    label == 'Orders'
                        ? 'Create & update orders'
                        : label == 'Payments'
                        ? 'Record payments'
                        : 'Add & edit ${label.toLowerCase()}',
                  ),
                  value: _perms.contains(write),
                  onChanged: (bool on) {
                    setState(() {
                      if (on) {
                        _perms
                          ..add(write)
                          ..add(read);
                      } else {
                        _perms.remove(write);
                      }
                    });
                  },
                ),
            ],
            if (widget.role.role == 'Branch Manager') ...<Widget>[
              const Divider(),
              Text(
                'A Branch Manager always keeps managing staff, branches and assigning orders.',
                style: AppTextStyles.caption,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('role.access.save'),
                    onPressed: () => Navigator.of(context).pop(<String>[
                      for (final (String _, String read, String? write) in kRoleModules) ...<String>[
                        if (_perms.contains(read)) read,
                        if (write != null && _perms.contains(write)) write,
                      ],
                    ]),
                    child: const Text('Save access'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
