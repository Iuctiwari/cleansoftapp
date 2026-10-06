import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/consumer/services/location_service.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';

// ── Add / edit address ───────────────────────────────────────────────────────

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({this.existing, this.isFirstAddress = false, super.key});

  final ConsumerAddress? existing;

  /// The compulsory first address: no back button, home opens afterwards.
  final bool isFirstAddress;

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _house;
  late final TextEditingController _street;
  late final TextEditingController _landmark;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _pincode;
  late final TextEditingController _contactName;
  late final TextEditingController _contactPhone;
  late AddressLabel _label;
  late bool _makeDefault;
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ConsumerAddress? a = widget.existing;
    final session = ConsumerDependencies.controller.session;
    _house = TextEditingController(text: a?.houseFlat ?? '');
    _street = TextEditingController(text: a?.streetArea ?? '');
    _landmark = TextEditingController(text: a?.landmark ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _state = TextEditingController(text: a?.state ?? '');
    _pincode = TextEditingController(text: a?.pincode ?? '');
    _contactName = TextEditingController(text: a?.contactName ?? session?.displayName ?? '');
    _contactPhone = TextEditingController(text: a?.contactPhone ?? session?.mobileNumber ?? '');
    _label = a?.label ?? AddressLabel.home;
    _makeDefault = a?.isDefault ?? false;
    _latitude = a?.latitude;
    _longitude = a?.longitude;
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _house, _street, _landmark, _city, _state, _pincode, _contactName, _contactPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() => _locating = true);
    final LocationService location = ConsumerDependencies.location;
    final LocationResult result = await location.currentPosition();
    if (!mounted) return;
    if (!result.ok) {
      setState(() => _locating = false);
      final LocationFailure failure = result.failure!;
      final String message = switch (failure) {
        LocationFailure.serviceOff => context.l10n.consumerLocationOff,
        LocationFailure.denied || LocationFailure.deniedForever => context.l10n.consumerLocationDenied,
        LocationFailure.unavailable => context.l10n.consumerLocationUnavailable,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            action: failure == LocationFailure.unavailable || failure == LocationFailure.denied
                ? null
                : SnackBarAction(
                    label: context.l10n.consumerOpenSettings,
                    onPressed: () => location.openSettings(failure),
                  ),
          ),
        );
      return;
    }

    final AddressGuess guess = await location.guessAddress(result.latitude!, result.longitude!);
    if (!mounted) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _locating = false;
      // Only fill what the customer has not typed yet.
      if (_street.text.trim().isEmpty) _street.text = guess.streetArea;
      if (_city.text.trim().isEmpty) _city.text = guess.city;
      if (_state.text.trim().isEmpty) _state.text = guess.state;
      if (_pincode.text.trim().isEmpty) _pincode.text = guess.pincode;
    });
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_latitude == null || _longitude == null) {
      context.showConsumerToast(context.l10n.consumerLocationNeeded);
      return;
    }
    setState(() => _saving = true);
    final AddressDraft draft = AddressDraft(
      label: _label,
      houseFlat: _house.text,
      streetArea: _street.text,
      landmark: _landmark.text,
      city: _city.text,
      state: _state.text,
      pincode: _pincode.text,
      latitude: _latitude!,
      longitude: _longitude!,
      contactName: _contactName.text,
      contactPhone: _contactPhone.text,
      isDefault: _makeDefault,
    );
    try {
      final ConsumerAddress saved = widget.existing == null
          ? await ConsumerDependencies.api.createAddress(draft)
          : await ConsumerDependencies.api.updateAddress(widget.existing!.addressId, draft);
      if (!mounted) return;
      if (widget.isFirstAddress) {
        context.goNamed(AppRouteNames.consumerHome);
      } else {
        context.pop(saved);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _saving = false);
      if (mounted) await context.showConsumerError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool pinned = _latitude != null && _longitude != null;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isFirstAddress,
        title: Text(widget.existing == null ? context.l10n.consumerAddressTitleNew : context.l10n.consumerAddressTitleEdit),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: <Widget>[
              if (widget.isFirstAddress) ...<Widget>[
                Text(context.l10n.consumerAddressRequiredNote, style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.xl),
              ],
              OutlinedButton.icon(
                key: const Key('address.locate'),
                onPressed: _locating ? null : _locate,
                icon: _locating
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location_rounded),
                label: Text(_locating ? context.l10n.consumerLocating : context.l10n.consumerUseCurrentLocation),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Icon(
                    pinned ? Icons.check_circle_rounded : AppIcons.location,
                    size: 18,
                    color: pinned ? AppColors.success : AppColors.textSubtle,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      pinned
                          ? '${context.l10n.consumerLocationPinned} (${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)})'
                          : context.l10n.consumerLocationNeeded,
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(context.l10n.consumerSaveAs, style: AppTextStyles.inputLabel),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: AddressLabel.values
                    .map(
                      (AddressLabel label) => ChoiceChip(
                        label: Text(context.addressLabel(label)),
                        selected: _label == label,
                        onSelected: (_) => setState(() => _label = label),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xl),
              _field(_house, context.l10n.consumerHouseFlat, required: true),
              _field(_street, context.l10n.consumerStreetArea, required: true),
              _field(_landmark, context.l10n.consumerLandmark),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: _field(_city, context.l10n.city, required: true)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _field(
                      _pincode,
                      context.l10n.consumerPincode,
                      keyboard: TextInputType.number,
                      validator: (String? v) =>
                          RegExp(r'^[1-9]\d{5}$').hasMatch(v?.trim() ?? '') ? null : context.l10n.consumerInvalidPincode,
                    ),
                  ),
                ],
              ),
              _field(_state, context.l10n.consumerState, required: true),
              _field(_contactName, context.l10n.consumerContactName, required: true),
              _field(
                _contactPhone,
                context.l10n.consumerContactPhone,
                keyboard: TextInputType.phone,
                validator: (String? v) =>
                    RegExp(r'^(\+?91|0)?[6-9]\d{9}$').hasMatch((v ?? '').replaceAll(RegExp(r'[\s-]'), ''))
                    ? null
                    : context.l10n.invalidMobile,
              ),
              if (!widget.isFirstAddress && !(widget.existing?.isDefault ?? false))
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _makeDefault,
                  onChanged: (bool? v) => setState(() => _makeDefault = v ?? false),
                  title: Text(context.l10n.consumerMakeDefault, style: AppTextStyles.bodyMedium),
                ),
              const SizedBox(height: AppSpacing.xl),
              ConsumerPrimaryButton(
                key: const Key('address.save'),
                label: context.l10n.consumerSaveAddress,
                busy: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppTextField(
        controller: controller,
        label: label,
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        validator: validator ??
            (required ? (String? v) => (v?.trim().isEmpty ?? true) ? context.l10n.fieldRequired(label) : null : null),
      ),
    );
  }
}

// ── Saved addresses ──────────────────────────────────────────────────────────

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  late Future<List<ConsumerAddress>> _addresses = ConsumerDependencies.api.listAddresses();

  void _reload() => setState(() => _addresses = ConsumerDependencies.api.listAddresses());

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      _reload();
    } on Object catch (error) {
      if (!mounted) return;
      if (error is ConsumerApiException && error.statusCode == 409) {
        await AppAlertDialog.show(context, title: context.l10n.consumerAddresses, message: context.l10n.consumerCannotDeleteLastAddress);
      } else {
        await context.showConsumerError(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.consumerAddresses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.pushNamed(AppRouteNames.consumerAddressNew);
          _reload();
        },
        icon: const Icon(AppIcons.add),
        label: Text(context.l10n.consumerAddAddress),
      ),
      body: FutureBuilder<List<ConsumerAddress>>(
        future: _addresses,
        builder: (BuildContext context, AsyncSnapshot<List<ConsumerAddress>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const AppLoadingView();
          if (snapshot.hasError) {
            return AppErrorView(message: context.consumerError(snapshot.error!), onRetry: _reload);
          }
          final List<ConsumerAddress> addresses = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 96),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (BuildContext context, int index) {
              final ConsumerAddress address = addresses[index];
              return AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(AppIcons.location, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(context.addressLabel(address.label), style: AppTextStyles.title),
                              if (address.isDefault) ...<Widget>[
                                const SizedBox(width: AppSpacing.sm),
                                AppStatusBadge(label: context.l10n.consumerDefault, tone: AppBadgeTone.success),
                              ],
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(address.formatted, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (String value) async {
                        switch (value) {
                          case 'edit':
                            await context.pushNamed(AppRouteNames.consumerAddressEdit, extra: address);
                            _reload();
                          case 'default':
                            await _run(() => ConsumerDependencies.api.setDefaultAddress(address.addressId));
                          case 'delete':
                            final bool ok = await AppConfirmDialog.show(
                              context,
                              title: context.l10n.consumerDeleteAddressConfirm,
                              message: address.formatted,
                              confirmLabel: context.l10n.consumerDelete,
                            );
                            if (ok) await _run(() => ConsumerDependencies.api.deleteAddress(address.addressId));
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(value: 'edit', child: Text(context.l10n.consumerEdit)),
                        if (!address.isDefault)
                          PopupMenuItem<String>(value: 'default', child: Text(context.l10n.consumerSetDefault)),
                        PopupMenuItem<String>(value: 'delete', child: Text(context.l10n.consumerDelete)),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
