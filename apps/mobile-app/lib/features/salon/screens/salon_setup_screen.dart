import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';
import 'package:nexoraa_mobile/features/online_requests/services/shop_marketplace_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';
import 'package:nexoraa_mobile/features/salon/models/salon_models.dart';

/// The salon owner's online-booking setup: slot length, the team with their roles, and the service menu.
class SalonSetupScreen extends StatefulWidget {
  const SalonSetupScreen({required this.branch, this.service, super.key});

  final ShopBranchArgs branch;
  final ShopMarketplaceApiService? service;

  @override
  State<SalonSetupScreen> createState() => _SalonSetupScreenState();
}

class _SalonSetupScreenState extends State<SalonSetupScreen> {
  static const List<int> _slotLengths = <int>[15, 30, 45, 60];

  late final ShopMarketplaceApiService _api =
      widget.service ??
      ShopMarketplaceApiService(tokenStorage: AuthenticationDependencies.tokenStorage, branchId: widget.branch.branchId);

  bool _loading = true;
  bool _saving = false;
  Object? _loadError;
  int _slotMinutes = 30;
  List<SalonStaff> _staff = <SalonStaff>[];
  List<SalonMenuItem> _menu = <SalonMenuItem>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final SalonConfig config = await _api.getSalonConfig();
      if (!mounted) return;
      setState(() {
        _slotMinutes = config.slotMinutes;
        _staff = List<SalonStaff>.of(config.staff);
        _menu = List<SalonMenuItem>.of(config.menu);
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loadError = error;
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final SalonConfig saved = await _api.saveSalonConfig(slotMinutes: _slotMinutes, staff: _staff, menu: _menu);
      if (!mounted) return;
      setState(() {
        _staff = List<SalonStaff>.of(saved.staff);
        _menu = List<SalonMenuItem>.of(saved.menu);
      });
      context.showConsumerToast('Saved. Customers can now book online.');
    } on Object catch (error) {
      if (mounted) await context.showShopError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> get _roles => <String>{..._staff.map((SalonStaff s) => s.role)}.toList();

  Future<void> _editStaff([int? index]) async {
    final SalonStaff? result = await showDialog<SalonStaff>(
      context: context,
      builder: (BuildContext _) => _StaffDialog(existing: index == null ? null : _staff[index], knownRoles: _roles),
    );
    if (result == null) return;
    setState(() => index == null ? _staff.add(result) : _staff[index] = result);
  }

  Future<void> _editMenu([int? index]) async {
    if (_roles.isEmpty) {
      context.showConsumerToast('Add your team first, then their services');
      return;
    }
    final SalonMenuItem? result = await showDialog<SalonMenuItem>(
      context: context,
      builder: (BuildContext _) => _MenuDialog(existing: index == null ? null : _menu[index], roles: _roles),
    );
    if (result == null) return;
    setState(() => index == null ? _menu.add(result) : _menu[index] = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Salon team & services')),
      bottomNavigationBar: _loading || _loadError != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConsumerPrimaryButton(
                  key: const Key('salon.setup.save'),
                  label: 'Save',
                  busy: _saving,
                  onPressed: _save,
                ),
              ),
            ),
      body: _loading
          ? const AppLoadingView()
          : _loadError != null
          ? AppErrorView(message: context.consumerError(_loadError!), onRetry: _load)
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: <Widget>[
                const ConsumerSectionTitle('Time slot'),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final int length in _slotLengths)
                      ChoiceChip(
                        label: Text('$length min'),
                        selected: _slotMinutes == length,
                        onSelected: (_) => setState(() => _slotMinutes = length),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text('Customers pick a start time every $_slotMinutes minutes.', style: AppTextStyles.caption),
                const SizedBox(height: AppSpacing.xl),
                const ConsumerSectionTitle('Your team'),
                Text(
                  'Add each person with their role. A booking for a service is given to someone with that role who is free.',
                  style: AppTextStyles.caption,
                ),
                for (int i = 0; i < _staff.length; i++)
                  ListTile(
                    key: Key('salon.staff.$i'),
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(_staff[i].name),
                    subtitle: Text(_staff[i].role),
                    onTap: () => _editStaff(i),
                    trailing: IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: () => setState(() => _staff.removeAt(i)),
                    ),
                  ),
                TextButton.icon(
                  key: const Key('salon.staff.add'),
                  onPressed: _editStaff,
                  icon: const Icon(AppIcons.add),
                  label: const Text('Add team member'),
                ),
                const SizedBox(height: AppSpacing.xl),
                const ConsumerSectionTitle('Service menu'),
                for (int i = 0; i < _menu.length; i++)
                  ListTile(
                    key: Key('salon.menu.$i'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(_menu[i].name),
                    subtitle: Text(
                      '${rupees(_menu[i].price)} · ${durationText(_menu[i].durationMinutes)} · ${_menu[i].role}',
                    ),
                    onTap: () => _editMenu(i),
                    trailing: IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: () => setState(() => _menu.removeAt(i)),
                    ),
                  ),
                TextButton.icon(
                  key: const Key('salon.menu.add'),
                  onPressed: _editMenu,
                  icon: const Icon(AppIcons.add),
                  label: const Text('Add service'),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Customers pay at the salon after the service. There is no advance payment.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
    );
  }
}

/// Add or edit one team member. Owns its text fields so they are disposed with the dialog.
class _StaffDialog extends StatefulWidget {
  const _StaffDialog({required this.existing, required this.knownRoles});

  final SalonStaff? existing;
  final List<String> knownRoles;

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _role = TextEditingController(text: widget.existing?.role ?? '');

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add team member' : 'Edit team member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              key: const Key('salon.staff.name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('salon.staff.role'),
              controller: _role,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: <Widget>[
                for (final String suggestion in <String>{...suggestedSalonRoles, ...widget.knownRoles})
                  ActionChip(label: Text(suggestion), onPressed: () => setState(() => _role.text = suggestion)),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          key: const Key('salon.staff.save'),
          onPressed: () {
            if (_name.text.trim().isEmpty || _role.text.trim().isEmpty) return;
            Navigator.pop(
              context,
              SalonStaff(staffId: widget.existing?.staffId ?? '', name: _name.text, role: _role.text),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Add or edit one menu service: name, price, how long, and which role does it.
class _MenuDialog extends StatefulWidget {
  const _MenuDialog({required this.existing, required this.roles});

  final SalonMenuItem? existing;
  final List<String> roles;

  @override
  State<_MenuDialog> createState() => _MenuDialogState();
}

class _MenuDialogState extends State<_MenuDialog> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _price = TextEditingController(
    text: widget.existing == null ? '' : widget.existing!.price.toStringAsFixed(0),
  );
  late int _minutes = widget.existing?.durationMinutes ?? 30;
  late String _role = widget.existing != null && widget.roles.contains(widget.existing!.role)
      ? widget.existing!.role
      : widget.roles.first;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add service' : 'Edit service'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              key: const Key('salon.menu.name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Service (e.g. Haircut)'),
            ),
            TextField(
              key: const Key('salon.menu.price'),
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (Rs.)'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<int>(
              initialValue: _minutes,
              decoration: const InputDecoration(labelText: 'Takes'),
              items: <DropdownMenuItem<int>>[
                for (final int m in <int>{15, 30, 45, 60, 75, 90, 120, 150, 180, 240, _minutes}.toList()..sort())
                  DropdownMenuItem<int>(value: m, child: Text(durationText(m))),
              ],
              onChanged: (int? m) => setState(() => _minutes = m ?? _minutes),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Done by'),
              items: <DropdownMenuItem<String>>[
                for (final String r in widget.roles) DropdownMenuItem<String>(value: r, child: Text(r)),
              ],
              onChanged: (String? r) => setState(() => _role = r ?? _role),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          key: const Key('salon.menu.save'),
          onPressed: () {
            final double? amount = double.tryParse(_price.text.trim());
            if (_name.text.trim().isEmpty || amount == null || amount < 0) return;
            Navigator.pop(
              context,
              SalonMenuItem(
                serviceId: widget.existing?.serviceId ?? '',
                name: _name.text,
                price: amount,
                durationMinutes: _minutes,
                role: _role,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
