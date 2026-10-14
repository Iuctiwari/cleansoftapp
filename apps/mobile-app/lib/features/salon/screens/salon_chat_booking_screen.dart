import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';
import 'package:nexoraa_mobile/features/salon/models/salon_models.dart';

enum _Step { greeting, services, date, slot, mode, address, confirm, sending }

class _Bubble {
  const _Bubble(this.text, {required this.fromBot});

  final String text;
  final bool fromBot;
}

/// Salon booking as a short chat: say hi, pick services, a day, a time, and confirm.
/// Other businesses keep the normal booking form.
class SalonChatBookingScreen extends StatefulWidget {
  const SalonChatBookingScreen({required this.shop, this.api, super.key});

  final ShopDetail shop;

  /// Tests pass a fake; null uses the signed-in customer's API.
  final ConsumerApiService? api;

  @override
  State<SalonChatBookingScreen> createState() => _SalonChatBookingScreenState();
}

class _SalonChatBookingScreenState extends State<SalonChatBookingScreen> {
  static const int _daysShown = 14;

  final List<_Bubble> _bubbles = <_Bubble>[];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  ConsumerApiService get _api => widget.api ?? ConsumerDependencies.api;

  _Step _step = _Step.greeting;
  SalonMenu? _menu;
  Object? _loadError;
  final Set<String> _chosen = <String>{};
  DateTime? _date;
  SalonSlots? _slots;
  bool _loadingSlots = false;
  SalonSlot? _slot;
  late ServiceMode _mode = _modes.first;
  List<ConsumerAddress> _addresses = <ConsumerAddress>[];
  String? _addressId;

  /// Salons serve in the shop or at home; pickup & drop is for laundry.
  List<ServiceMode> get _modes {
    final List<ServiceMode> modes = widget.shop.serviceModes
        .where((ServiceMode m) => m != ServiceMode.pickupDrop)
        .toList();
    return modes.isEmpty ? <ServiceMode>[ServiceMode.visitShop] : modes;
  }

  List<SalonMenuItem> get _chosenItems =>
      _menu?.menu.where((SalonMenuItem i) => _chosen.contains(i.serviceId)).toList() ?? <SalonMenuItem>[];

  double get _total => _chosenItems.fold(0, (double sum, SalonMenuItem i) => sum + i.price);
  int get _minutes => _chosenItems.fold(0, (int sum, SalonMenuItem i) => sum + i.durationMinutes);

  @override
  void initState() {
    super.initState();
    _bot('Hi! Welcome to ${widget.shop.shopName}. Say hi to start booking.');
    _loadMenu();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    try {
      final SalonMenu menu = await _api.salonMenu(widget.shop.shopId);
      if (mounted) setState(() => _menu = menu);
    } on Object catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  void _bot(String text) {
    _bubbles.add(_Bubble(text, fromBot: true));
    _scrollDown();
  }

  void _me(String text) {
    _bubbles.add(_Bubble(text, fromBot: false));
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── steps ─────────────────────────────────────────────────────────────────

  void _sayHi() {
    final String text = _input.text.trim().isEmpty ? 'Hi' : _input.text.trim();
    _input.clear();
    final SalonMenu? menu = _menu;
    if (menu == null) {
      context.showConsumerToast(_loadError == null ? 'One moment, loading the menu…' : 'Could not load the menu');
      return;
    }
    setState(() {
      _me(text);
      if (!menu.configured) {
        _bot('${widget.shop.shopName} has not opened online booking yet. Please call the salon to book.');
        return;
      }
      _bot('Great! Which services would you like? You can pick more than one.');
      _step = _Step.services;
    });
  }

  void _servicesDone() {
    if (_chosen.isEmpty) {
      context.showConsumerToast('Pick at least one service');
      return;
    }
    setState(() {
      _me(_chosenItems.map((SalonMenuItem i) => i.name).join(', '));
      _bot('Total ${rupees(_total)}, about ${durationText(_minutes)}. Which day suits you?');
      _step = _Step.date;
    });
  }

  Future<void> _pickDate(DateTime date) async {
    setState(() {
      _date = date;
      _slot = null;
      _slots = null;
      _loadingSlots = true;
      _me(context.formatDay(date));
      _step = _Step.slot;
    });
    try {
      final SalonSlots slots = await _api.salonSlots(widget.shop.shopId, _dateKey(date), _chosen.toList());
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
        _bot(
          slots.closed
              ? 'The salon is closed that day. Pick another day.'
              : 'Here are the times. Green is free, yellow is waiting for the salon to reply, grey is booked.',
        );
        if (slots.closed) _step = _Step.date;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSlots = false;
        _step = _Step.date;
      });
      await context.showConsumerError(error);
    }
  }

  Future<void> _pickSlot(SalonSlot slot) async {
    setState(() {
      _slot = slot;
      _me('${context.formatClock(slot.start)} – ${context.formatClock(slot.end)}');
      if (_modes.length > 1) {
        _bot('Would you like to come to the salon or have us come to you?');
        _step = _Step.mode;
      }
    });
    if (_modes.length == 1) await _modePicked(_modes.first, announce: false);
  }

  Future<void> _modePicked(ServiceMode mode, {bool announce = true}) async {
    setState(() {
      _mode = mode;
      if (announce) _me(mode == ServiceMode.homeService ? 'Come to my home' : 'I will visit the salon');
    });
    if (!mode.needsAddress) {
      setState(_toConfirm);
      return;
    }
    try {
      final List<ConsumerAddress> addresses = await _api.listAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _addressId = addresses.isEmpty
            ? null
            : addresses.firstWhere((ConsumerAddress a) => a.isDefault, orElse: () => addresses.first).addressId;
        _bot('Which address should we come to?');
        _step = _Step.address;
      });
    } on Object catch (error) {
      if (mounted) await context.showConsumerError(error);
    }
  }

  void _addressDone() {
    final ConsumerAddress? address = _addresses.where((ConsumerAddress a) => a.addressId == _addressId).firstOrNull;
    if (address == null) {
      context.showConsumerToast(context.l10n.consumerChooseAddress);
      return;
    }
    setState(() {
      _me(address.formatted);
      _toConfirm();
    });
  }

  void _toConfirm() {
    _bot('Almost done. Please check your booking and confirm.');
    _step = _Step.confirm;
  }

  Future<void> _confirm() async {
    final SalonSlot? slot = _slot;
    final DateTime? date = _date;
    if (slot == null || date == null) return;
    setState(() {
      _me('Confirm');
      _step = _Step.sending;
    });
    try {
      final ServiceRequest request = await _api.createRequest(
        ServiceRequestDraft(
          shopId: widget.shop.shopId,
          category: ShopCategory.salon,
          requestType: _mode,
          description: 'Salon: ${_chosenItems.map((SalonMenuItem i) => i.name).join(', ')}',
          preferredDate: _dateKey(date),
          slotStart: slot.start,
          slotEnd: slot.end,
          addressId: _mode.needsAddress ? _addressId : null,
          salonServiceIds: _chosen.toList(),
        ),
      );
      if (!mounted) return;
      setState(() => _step = _Step.confirm);
      await AppAlertDialog.show(
        context,
        title: 'Booking sent',
        message: '${widget.shop.shopName} will confirm your appointment soon. Pay at the salon after the service.',
        isError: false,
      );
      if (!mounted) return;
      context.goNamed(AppRouteNames.consumerHome, extra: 1);
      context.pushNamed(
        AppRouteNames.consumerRequest,
        pathParameters: <String, String>{'requestId': request.requestId},
      );
    } on Object catch (error) {
      if (!mounted) return;
      // A taken slot is the common failure: go back to the times so they can pick another.
      setState(() {
        _bot('That did not go through. Please pick a time again.');
        _step = _Step.date;
      });
      await context.showConsumerError(error);
    }
  }

  void _startOver() {
    setState(() {
      _chosen.clear();
      _date = null;
      _slots = null;
      _slot = null;
      _bubbles.add(const _Bubble('No problem, let us start again. Which services would you like?', fromBot: true));
      _step = _Step.services;
    });
    _scrollDown();
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.shop.shopName)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: <Widget>[
                for (final _Bubble bubble in _bubbles) _bubbleView(bubble),
                if (_loadError != null && _menu == null)
                  AppErrorView(message: context.consumerError(_loadError!), onRetry: _loadMenu),
                const SizedBox(height: AppSpacing.md),
                _stepPanel(context),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
          if (_step == _Step.greeting) _inputBar(),
        ],
      ),
    );
  }

  Widget _bubbleView(_Bubble bubble) {
    return Align(
      alignment: bubble.fromBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: bubble.fromBot ? AppColors.primarySurface : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          bubble.text,
          style: AppTextStyles.bodyMedium.copyWith(color: bubble.fromBot ? AppColors.textPrimary : Colors.white),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            ActionChip(label: const Text('Hi'), onPressed: _sayHi),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                key: const Key('salon.chat.input'),
                controller: _input,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sayHi(),
                decoration: const InputDecoration(hintText: 'Type hi…', isDense: true),
              ),
            ),
            IconButton(key: const Key('salon.chat.send'), onPressed: _sayHi, icon: const Icon(Icons.send_rounded)),
          ],
        ),
      ),
    );
  }

  Widget _stepPanel(BuildContext context) {
    switch (_step) {
      case _Step.greeting:
        return const SizedBox.shrink();
      case _Step.services:
        return _servicesPanel();
      case _Step.date:
        return _datePanel(context);
      case _Step.slot:
        return _slotPanel(context);
      case _Step.mode:
        return Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            for (final ServiceMode mode in _modes)
              ActionChip(
                avatar: Icon(modeIcon(mode), size: 18),
                label: Text(mode == ServiceMode.homeService ? 'Come to my home' : 'I will visit the salon'),
                onPressed: () => _modePicked(mode),
              ),
          ],
        );
      case _Step.address:
        return _addressPanel(context);
      case _Step.confirm:
      case _Step.sending:
        return _confirmPanel();
    }
  }

  Widget _servicesPanel() {
    final List<SalonMenuItem> menu = _menu?.menu ?? <SalonMenuItem>[];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (final SalonMenuItem item in menu)
            CheckboxListTile(
              key: Key('salon.service.${item.serviceId}'),
              contentPadding: EdgeInsets.zero,
              value: _chosen.contains(item.serviceId),
              onChanged: (bool? on) =>
                  setState(() => on == true ? _chosen.add(item.serviceId) : _chosen.remove(item.serviceId)),
              title: Text(item.name, style: AppTextStyles.title),
              subtitle: Text('${rupees(item.price)} · ${durationText(item.durationMinutes)} · ${item.role}'),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (_chosen.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text('${rupees(_total)} · ${durationText(_minutes)}', style: AppTextStyles.labelBold),
            ),
          ConsumerPrimaryButton(key: const Key('salon.services.next'), label: 'Continue', onPressed: _servicesDone),
        ],
      ),
    );
  }

  Widget _datePanel(BuildContext context) {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final List<DateTime> days = <DateTime>[for (int i = 0; i < _daysShown; i++) today.add(Duration(days: i))].where((
      DateTime d,
    ) {
      final OpeningHoursDay? hours = widget.shop.hoursFor(d.weekday % 7);
      return hours != null && !hours.closed;
    }).toList();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final DateTime day in days)
          ActionChip(
            key: Key('salon.day.${_dateKey(day)}'),
            label: Text(context.formatDay(day)),
            onPressed: () => _pickDate(day),
          ),
      ],
    );
  }

  Widget _slotPanel(BuildContext context) {
    if (_loadingSlots) return const Center(child: CircularProgressIndicator());
    final SalonSlots? slots = _slots;
    if (slots == null || slots.closed) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        for (final SalonSlot slot in slots.slots) _slotChip(context, slot),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: TextButton(onPressed: () => setState(() => _step = _Step.date), child: const Text('Change day')),
        ),
      ],
    );
  }

  Widget _slotChip(BuildContext context, SalonSlot slot) {
    final (Color fill, Color text, String note) = switch (slot.state) {
      SalonSlotState.available => (AppColors.successSubtle, AppColors.successDarker, ''),
      SalonSlotState.pending => (AppColors.warningSurface, AppColors.warningText, 'Pending'),
      SalonSlotState.booked => (AppColors.surfaceMuted, AppColors.textMuted, 'Booked'),
      SalonSlotState.unavailable => (AppColors.surfaceMuted, AppColors.textDisabled, ''),
    };
    final bool open = slot.state == SalonSlotState.available;
    return InkWell(
      key: Key('salon.slot.${slot.start}'),
      borderRadius: BorderRadius.circular(12),
      onTap: open ? () => _pickSlot(slot) : null,
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: <Widget>[
            Text(context.formatClock(slot.start), style: AppTextStyles.labelBold.copyWith(color: text)),
            Text(note.isEmpty ? (open ? 'Free' : '–') : note, style: AppTextStyles.caption.copyWith(color: text)),
          ],
        ),
      ),
    );
  }

  Widget _addressPanel(BuildContext context) {
    return AppCard(
      child: Column(
        children: <Widget>[
          RadioGroup<String>(
            groupValue: _addressId,
            onChanged: (String? id) => setState(() => _addressId = id),
            child: Column(
              children: <Widget>[
                for (final ConsumerAddress address in _addresses)
                  RadioListTile<String>(
                    contentPadding: EdgeInsets.zero,
                    value: address.addressId,
                    title: Text(context.addressLabel(address.label)),
                    subtitle: Text(address.formatted),
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () async {
              final Object? added = await context.pushNamed<Object>(AppRouteNames.consumerAddressNew);
              if (added is ConsumerAddress) {
                final List<ConsumerAddress> addresses = await _api.listAddresses();
                if (mounted) {
                  setState(() {
                    _addresses = addresses;
                    _addressId = added.addressId;
                  });
                }
              }
            },
            icon: const Icon(AppIcons.add),
            label: Text(context.l10n.consumerAddAddress),
          ),
          ConsumerPrimaryButton(label: 'Continue', onPressed: _addressDone),
        ],
      ),
    );
  }

  Widget _confirmPanel() {
    final SalonSlot? slot = _slot;
    final DateTime? date = _date;
    if (slot == null || date == null) return const SizedBox.shrink();
    final bool sending = _step == _Step.sending;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Your appointment', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final SalonMenuItem item in _chosenItems)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: <Widget>[
                  Expanded(child: Text(item.name)),
                  Text(rupees(item.price)),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: <Widget>[
              Expanded(child: Text('Total', style: AppTextStyles.labelBold)),
              Text(rupees(_total), style: AppTextStyles.labelBold),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${context.formatDay(date)} · ${context.formatClock(slot.start)} – ${context.formatClock(slot.end)}'),
          Text(_mode == ServiceMode.homeService ? 'At your home' : 'At the salon'),
          const SizedBox(height: AppSpacing.sm),
          Text('Pay at the salon after the service. No advance payment.', style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.md),
          ConsumerPrimaryButton(
            key: const Key('salon.confirm'),
            label: 'Confirm booking',
            busy: sending,
            onPressed: sending ? null : _confirm,
          ),
          TextButton(onPressed: sending ? null : _startOver, child: const Text('Start over')),
        ],
      ),
    );
  }
}
