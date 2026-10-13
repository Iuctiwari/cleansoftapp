import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';

/// What the worker recorded at the customer's door.
class CollectResult {
  const CollectResult({required this.items, this.customDeliveryDate});

  final List<RequestItem> items;

  /// YYYY-MM-DD, only when the worker chose their own date; null = automatic.
  final String? customDeliveryDate;
}

/// The worker lists what was collected; the delivery date follows from the
/// count (automatic) unless they pick another day.
class CollectPickupDialog extends StatefulWidget {
  const CollectPickupDialog({required this.initialItems, required this.estimate, super.key});

  final List<RequestItem> initialItems;

  /// Asks the server for the automatic delivery date (YYYY-MM-DD) for a quantity.
  final Future<String> Function(int quantity) estimate;

  @override
  State<CollectPickupDialog> createState() => _CollectPickupDialogState();
}

class _ItemRow {
  _ItemRow(String name, int? quantity)
    : name = TextEditingController(text: name),
      quantity = TextEditingController(text: quantity == null ? '' : '$quantity');

  final TextEditingController name;
  final TextEditingController quantity;

  int get qty => int.tryParse(quantity.text.trim()) ?? 0;

  void dispose() {
    name.dispose();
    quantity.dispose();
  }
}

class _CollectPickupDialogState extends State<CollectPickupDialog> {
  late final List<_ItemRow> _rows = widget.initialItems.isEmpty
      ? <_ItemRow>[_ItemRow('', null)]
      : widget.initialItems.map((RequestItem i) => _ItemRow(i.name, i.quantity)).toList();
  String? _autoDate;
  String? _customDate;
  bool _needItem = false;
  Timer? _debounce;
  int _asked = -1;

  @override
  void initState() {
    super.initState();
    _scheduleEstimate();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final _ItemRow row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  int get _total => _rows.fold<int>(0, (int sum, _ItemRow r) => sum + r.qty);

  void _scheduleEstimate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final int total = _total;
      if (total < 1 || total == _asked) return;
      _asked = total;
      try {
        final String date = await widget.estimate(total);
        if (mounted && date.isNotEmpty) {
          setState(() {
            _autoDate = date;
          });
        }
      } on Object {
        // The date can still be picked by hand.
      }
    });
  }

  String _show(BuildContext context, String yyyyMmDd) {
    final DateTime? day = DateTime.tryParse(yyyyMmDd);
    return day == null ? yyyyMmDd : context.formatDay(day);
  }

  String _iso(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime initial = DateTime.tryParse(_customDate ?? _autoDate ?? '') ?? today;
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );
    if (day == null || !mounted) return;
    setState(() {
      _customDate = _iso(day);
    });
  }

  void _submit() {
    final List<RequestItem> items = <RequestItem>[
      for (final _ItemRow row in _rows)
        if (row.name.text.trim().isNotEmpty && row.qty > 0)
          RequestItem(name: row.name.text.trim(), quantity: row.qty),
    ];
    if (items.isEmpty) {
      setState(() {
        _needItem = true;
      });
      return;
    }
    Navigator.of(context).pop(CollectResult(items: items, customDeliveryDate: _customDate));
  }

  @override
  Widget build(BuildContext context) {
    final String? shown = _customDate ?? _autoDate;
    return AlertDialog(
      title: Text(context.l10n.pickupCollectTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(context.l10n.pickupItemsHeading, style: AppTextStyles.inputLabel),
              const SizedBox(height: AppSpacing.sm),
              for (int i = 0; i < _rows.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: TextField(
                          key: Key('collect.name.$i'),
                          controller: _rows[i].name,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(hintText: context.l10n.pickupItemName, isDense: true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          key: Key('collect.qty.$i'),
                          controller: _rows[i].quantity,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: context.l10n.pickupItemQty, isDense: true),
                          onChanged: (_) {
                            setState(() {
                              _needItem = false;
                            });
                            _scheduleEstimate();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _rows.add(_ItemRow('', null));
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.l10n.pickupAddItem),
              ),
              if (_needItem)
                Text(context.l10n.pickupNeedItem, style: AppTextStyles.caption.copyWith(color: AppColors.errorText)),
              const Divider(),
              Text(context.l10n.pickupDeliveryDate, style: AppTextStyles.inputLabel),
              const SizedBox(height: AppSpacing.xs),
              Text(
                shown == null
                    ? '…'
                    : _customDate != null
                    ? _show(context, _customDate!)
                    : context.l10n.pickupAutoDate(_show(context, _autoDate!)),
                key: const Key('collect.date'),
                style: AppTextStyles.labelBold,
              ),
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  TextButton(
                    key: const Key('collect.pickDate'),
                    onPressed: _pickDate,
                    child: Text(context.l10n.pickupCustomDate),
                  ),
                  if (_customDate != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _customDate = null;
                        });
                      },
                      child: Text(context.l10n.pickupBackToAuto),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('collect.confirm'),
          onPressed: _submit,
          child: Text(context.l10n.pickupCollectAction),
        ),
      ],
    );
  }
}
