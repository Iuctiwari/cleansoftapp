import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';

/// Send a request / appointment to one shop.
class BookingScreen extends StatefulWidget {
  const BookingScreen({required this.shop, super.key});

  final ShopDetail shop;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _ItemRow {
  final TextEditingController name = TextEditingController();
  int quantity = 1;
}

class _BookingScreenState extends State<BookingScreen> {
  static const int _maxDaysAhead = 30;

  late ShopCategory _category = widget.shop.categories.first;
  late ServiceMode _mode = widget.shop.serviceModes.first;
  late DateTime _date = _firstOpenDay();
  TimeOfDay _from = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _to = const TimeOfDay(hour: 12, minute: 0);
  final TextEditingController _description = TextEditingController();
  final List<_ItemRow> _items = <_ItemRow>[];
  List<ConsumerAddress> _addresses = <ConsumerAddress>[];
  String? _addressId;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fitSlotToHours();
    _loadAddresses();
  }

  @override
  void dispose() {
    _description.dispose();
    for (final _ItemRow row in _items) {
      row.name.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    try {
      final List<ConsumerAddress> addresses = await ConsumerDependencies.api.listAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        if (_addressId == null && addresses.isNotEmpty) {
          _addressId = addresses
              .firstWhere((ConsumerAddress a) => a.isDefault, orElse: () => addresses.first)
              .addressId;
        }
      });
    } on Object catch (error) {
      if (mounted) setState(() => _sending = false);
      if (mounted) await context.showConsumerError(error);
    }
  }

  bool _isOpenDay(DateTime date) {
    final OpeningHoursDay? hours = widget.shop.hoursFor(date.weekday % 7);
    return hours != null && !hours.closed;
  }

  DateTime _firstOpenDay() {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    for (int i = 0; i <= _maxDaysAhead; i++) {
      final DateTime day = today.add(Duration(days: i));
      // Today only if the shop is still open long enough for a slot.
      if (i == 0 && DateTime.now().hour >= 18) continue;
      if (_isOpenDay(day)) return day;
    }
    return today.add(const Duration(days: 1));
  }

  /// Default slot: the first two hours the shop is open that day.
  void _fitSlotToHours() {
    final OpeningHoursDay? hours = widget.shop.hoursFor(_date.weekday % 7);
    if (hours?.open == null) return;
    final TimeOfDay open = _parse(hours!.open!);
    final DateTime now = DateTime.now();
    TimeOfDay start = open;
    if (DateUtils.isSameDay(_date, now) && now.hour + 1 > open.hour) {
      start = TimeOfDay(hour: now.hour + 1, minute: 0);
    }
    _from = start;
    _to = TimeOfDay(hour: (start.hour + 2).clamp(0, 23), minute: start.minute);
  }

  TimeOfDay _parse(String clock) {
    final List<String> parts = clock.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _clock(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: _maxDaysAhead)),
      selectableDayPredicate: _isOpenDay,
      helpText: context.l10n.consumerPickDate,
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _fitSlotToHours();
    });
  }

  Future<void> _pickTime(bool start) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: start ? _from : _to);
    if (picked == null) return;
    setState(() => start ? _from = picked : _to = picked);
  }

  Future<void> _send() async {
    final String description = _description.text.trim();
    if (description.length < 5) {
      context.showConsumerToast(context.l10n.consumerDescribeMore);
      return;
    }
    if (_clock(_to).compareTo(_clock(_from)) <= 0) {
      context.showConsumerToast(context.l10n.consumerSlotInvalid);
      return;
    }
    if (!_isOpenDay(_date)) {
      context.showConsumerToast(context.l10n.consumerShopClosedThatDay);
      return;
    }
    if (_mode.needsAddress && _addressId == null) {
      context.showConsumerToast(context.l10n.consumerChooseAddress);
      return;
    }

    setState(() => _sending = true);
    try {
      final ServiceRequest request = await ConsumerDependencies.api.createRequest(
        ServiceRequestDraft(
          shopId: widget.shop.shopId,
          category: _category,
          requestType: _mode,
          description: description,
          preferredDate:
              '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
          slotStart: _clock(_from),
          slotEnd: _clock(_to),
          items: _items
              .where((_ItemRow row) => row.name.text.trim().isNotEmpty)
              .map((_ItemRow row) => RequestItem(name: row.name.text, quantity: row.quantity))
              .toList(),
          addressId: _mode.needsAddress ? _addressId : null,
        ),
      );
      if (!mounted) return;
      setState(() => _sending = false);
      await AppAlertDialog.show(
        context,
        title: context.l10n.consumerRequestSentTitle,
        message: context.l10n.consumerRequestSentMessage(widget.shop.shopName),
        isError: false,
      );
      if (!mounted) return;
      context.goNamed(AppRouteNames.consumerHome, extra: 1);
      context.pushNamed(
        AppRouteNames.consumerRequest,
        pathParameters: <String, String>{'requestId': request.requestId},
      );
    } on Object catch (error) {
      if (mounted) setState(() => _sending = false);
      if (mounted) await context.showConsumerError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.consumerBookTitle(widget.shop.shopName))),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConsumerPrimaryButton(
            key: const Key('booking.send'),
            label: context.l10n.consumerSendRequest,
            busy: _sending,
            onPressed: _send,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: <Widget>[
          ConsumerSectionTitle(context.l10n.consumerWhatService),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: widget.shop.categories
                .map(
                  (ShopCategory c) => ChoiceChip(
                    avatar: Icon(categoryIcon(c), size: 18),
                    label: Text(context.categoryLabel(c)),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          ConsumerSectionTitle(context.l10n.consumerHowServed),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: widget.shop.serviceModes
                .map(
                  (ServiceMode m) => ChoiceChip(
                    avatar: Icon(modeIcon(m), size: 18),
                    label: Text(context.modeLabel(m)),
                    selected: _mode == m,
                    onSelected: (_) => setState(() => _mode = m),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          ConsumerSectionTitle(context.l10n.consumerWhen),
          AppCard(
            onTap: _pickDate,
            child: Row(
              children: <Widget>[
                const Icon(Icons.event_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(context.formatDay(_date), style: AppTextStyles.title)),
                const Icon(AppIcons.chevronDown),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(child: _timeBox(context.l10n.consumerTimeFrom, _from, () => _pickTime(true))),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _timeBox(context.l10n.consumerTimeTo, _to, () => _pickTime(false))),
            ],
          ),
          if (_mode.needsAddress) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            ConsumerSectionTitle(context.l10n.consumerYourAddress),
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
                  _addressId = added.addressId;
                  await _loadAddresses();
                }
              },
              icon: const Icon(AppIcons.add),
              label: Text(context.l10n.consumerAddAddress),
            ),
            Text(context.l10n.consumerTravelsUpTo(widget.shop.serviceRadiusKm), style: AppTextStyles.caption),
          ],
          const SizedBox(height: AppSpacing.xl),
          ConsumerSectionTitle(context.l10n.consumerDescribe),
          TextField(
            key: const Key('booking.description'),
            controller: _description,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            decoration: InputDecoration(hintText: context.l10n.consumerDescribeHint),
          ),
          const SizedBox(height: AppSpacing.md),
          ConsumerSectionTitle(context.l10n.consumerItemsOptional),
          for (final _ItemRow row in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: row.name,
                      maxLength: 80,
                      decoration: InputDecoration(hintText: context.l10n.consumerItemName, counterText: '', isDense: true),
                    ),
                  ),
                  IconButton(
                    onPressed: row.quantity > 1 ? () => setState(() => row.quantity--) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${row.quantity}', style: AppTextStyles.title),
                  IconButton(
                    onPressed: row.quantity < 999 ? () => setState(() => row.quantity++) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      _items.remove(row);
                      row.name.dispose();
                    }),
                    icon: const Icon(AppIcons.close),
                  ),
                ],
              ),
            ),
          if (_items.length < 20)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _items.add(_ItemRow())),
                icon: const Icon(AppIcons.add),
                label: Text(context.l10n.consumerAddItem),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _timeBox(String label, TimeOfDay time, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: AppSpacing.xs),
          Text(context.formatClock(_clock(time)), style: AppTextStyles.title),
        ],
      ),
    );
  }
}
