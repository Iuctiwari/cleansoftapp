import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';

/// What the worker recorded at the customer's door.
class CollectResult {
  const CollectResult({this.totalItems, this.photos = const <Uint8List>[], this.customDeliveryDate});

  /// Number of items counted at pickup; null when the worker left it blank.
  final int? totalItems;

  /// JPEG bytes of the photos taken at the door (may be empty).
  final List<Uint8List> photos;

  /// YYYY-MM-DD, only when the worker chose their own date; null = automatic.
  final String? customDeliveryDate;
}

/// Photos of what was handed over, an optional total item count, and the delivery
/// date (automatic from the count, unless the worker picks another day).
class CollectPickupDialog extends StatefulWidget {
  const CollectPickupDialog({required this.estimate, this.initialTotal, this.takePhoto, super.key});

  /// The count the customer wrote when booking, offered as a starting point.
  final int? initialTotal;

  /// Asks the server for the automatic delivery date (YYYY-MM-DD) for a quantity.
  final Future<String> Function(int quantity) estimate;

  /// Opens the camera; tests pass a fake. Null = the phone's camera.
  final Future<XFile?> Function()? takePhoto;

  @override
  State<CollectPickupDialog> createState() => _CollectPickupDialogState();
}

class _CollectPickupDialogState extends State<CollectPickupDialog> {
  late final TextEditingController _total = TextEditingController(
    text: widget.initialTotal == null ? '' : '${widget.initialTotal}',
  );
  final List<Uint8List> _photos = <Uint8List>[];
  String? _autoDate;
  String? _customDate;
  Timer? _debounce;
  int _asked = -1;

  @override
  void initState() {
    super.initState();
    _scheduleEstimate(immediate: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _total.dispose();
    super.dispose();
  }

  int? get _count {
    final int? value = int.tryParse(_total.text.trim());
    return value != null && value > 0 ? value : null;
  }

  void _scheduleEstimate({bool immediate = false}) {
    _debounce?.cancel();
    _debounce = Timer(immediate ? Duration.zero : const Duration(milliseconds: 400), () async {
      // Without a count the server assumes one batch, which is the shortest turnaround.
      final int quantity = _count ?? 1;
      if (quantity == _asked) return;
      _asked = quantity;
      try {
        final String date = await widget.estimate(quantity);
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

  Future<void> _addPhoto() async {
    try {
      final XFile? shot =
          await (widget.takePhoto ?? () => ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 70))();
      if (shot == null) return;
      final Uint8List bytes = await shot.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photos.add(bytes);
      });
    } on Object {
      // Camera unavailable or permission refused: the pickup can still be recorded without photos.
    }
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
              Text(context.l10n.pickupPhotosHeading, style: AppTextStyles.inputLabel),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: <Widget>[
                  for (int i = 0; i < _photos.length; i++)
                    Stack(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_photos[i], width: 64, height: 64, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            key: Key('collect.photo.remove.$i'),
                            onTap: () {
                              setState(() {
                                _photos.removeAt(i);
                              });
                            },
                            child: const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.black54,
                              child: Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (_photos.length < 6)
                    OutlinedButton.icon(
                      key: const Key('collect.photo.add'),
                      onPressed: _addPhoto,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: Text(context.l10n.pickupTakePhoto),
                    ),
                ],
              ),
              Text(context.l10n.pickupPhotoLimit, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                key: const Key('collect.total'),
                controller: _total,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: context.l10n.pickupTotalItems, isDense: true),
                onChanged: (_) {
                  setState(() {});
                  _scheduleEstimate();
                },
              ),
              const Divider(height: AppSpacing.xl),
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
          onPressed: () => Navigator.of(context).pop(
            CollectResult(totalItems: _count, photos: List<Uint8List>.of(_photos), customDeliveryDate: _customDate),
          ),
          child: Text(context.l10n.pickupCollectAndCreate),
        ),
      ],
    );
  }
}
