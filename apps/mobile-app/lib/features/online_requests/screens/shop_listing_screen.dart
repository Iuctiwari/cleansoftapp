import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/services/location_service.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';
import 'package:nexoraa_mobile/features/online_requests/models/shop_marketplace_models.dart';
import 'package:nexoraa_mobile/features/online_requests/services/shop_marketplace_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';

/// "Shop listing": what customers see about this branch.
class ShopListingScreen extends StatefulWidget {
  const ShopListingScreen({required this.branch, this.service, super.key});

  final ShopBranchArgs branch;
  final ShopMarketplaceApiService? service;

  @override
  State<ShopListingScreen> createState() => _ShopListingScreenState();
}

class _ShopListingScreenState extends State<ShopListingScreen> {
  late final ShopMarketplaceApiService _api =
      widget.service ??
      ShopMarketplaceApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
        branchId: widget.branch.branchId,
      );
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _street = TextEditingController();
  final TextEditingController _area = TextEditingController();
  final TextEditingController _landmark = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final TextEditingController _pincode = TextEditingController();
  final TextEditingController _bookingPhone = TextEditingController();
  final TextEditingController _about = TextEditingController();

  ShopListing? _listing;
  Object? _loadError;
  double? _latitude;
  double? _longitude;
  Set<ServiceMode> _modes = <ServiceMode>{};
  int _radiusKm = 5;
  bool _isListed = true;
  List<OpeningHoursDay> _hours = <OpeningHoursDay>[];
  bool _locating = false;
  bool _saving = false;

  bool get _canEdit => shopAccessPolicy().allows(AppCapability.branchesEdit);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      _street, _area, _landmark, _city, _state, _pincode, _bookingPhone, _about,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final ShopListing listing = await _api.getListing();
      if (!mounted) return;
      _apply(listing);
    } on Object catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  void _apply(ShopListing listing) {
    setState(() {
      _listing = listing;
      _street.text = listing.streetAddress;
      _area.text = listing.area ?? '';
      _landmark.text = listing.landmark ?? '';
      _city.text = listing.city;
      _state.text = listing.state;
      _pincode.text = listing.postalCode;
      _bookingPhone.text = listing.bookingPhone ?? '';
      _about.text = listing.about ?? '';
      _latitude = listing.latitude;
      _longitude = listing.longitude;
      _modes = listing.serviceModes.toSet();
      _radiusKm = listing.serviceRadiusKm;
      _isListed = listing.isListed;
      _hours = List<OpeningHoursDay>.generate(7, (int day) {
        for (final OpeningHoursDay d in listing.openingHours) {
          if (d.day == day) return d;
        }
        return OpeningHoursDay(day: day, closed: day == 0, open: '09:00', close: '20:00');
      });
    });
  }

  Future<void> _pin() async {
    setState(() => _locating = true);
    final LocationService location = ConsumerDependencies.location;
    final LocationResult result = await location.currentPosition();
    if (!mounted) return;
    if (!result.ok) {
      setState(() => _locating = false);
      context.showConsumerToast(
        result.failure == LocationFailure.serviceOff
            ? context.l10n.consumerLocationOff
            : result.failure == LocationFailure.unavailable
            ? context.l10n.consumerLocationUnavailable
            : context.l10n.consumerLocationDenied,
      );
      if (result.failure == LocationFailure.deniedForever || result.failure == LocationFailure.serviceOff) {
        await location.openSettings(result.failure!);
      }
      return;
    }
    final AddressGuess guess = await location.guessAddress(result.latitude!, result.longitude!);
    if (!mounted) return;
    setState(() {
      _latitude = result.latitude;
      _longitude = result.longitude;
      _locating = false;
      if (_area.text.trim().isEmpty) _area.text = guess.streetArea;
      if (_city.text.trim().isEmpty) _city.text = guess.city;
      if (_state.text.trim().isEmpty) _state.text = guess.state;
      if (_pincode.text.trim().isEmpty) _pincode.text = guess.pincode;
    });
  }

  Future<void> _pickTime(int day, bool opening) async {
    final OpeningHoursDay current = _hours[day];
    final String value = (opening ? current.open : current.close) ?? (opening ? '09:00' : '20:00');
    final List<String> parts = value.split(':');
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked == null) return;
    final String clock = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      _hours[day] = OpeningHoursDay(
        day: day,
        closed: false,
        open: opening ? clock : current.open ?? '09:00',
        close: opening ? current.close ?? '20:00' : clock,
      );
    });
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_latitude == null || _longitude == null) {
      context.showConsumerToast(context.l10n.shopListingNeedPin);
      return;
    }
    if (_modes.isEmpty) {
      context.showConsumerToast(context.l10n.shopListingChooseMode);
      return;
    }
    if (_hours.every((OpeningHoursDay d) => d.closed)) {
      context.showConsumerToast(context.l10n.shopListingNeedOpenDay);
      return;
    }
    setState(() => _saving = true);
    try {
      final ShopListing saved = await _api.saveListing(
        ShopListingDraft(
          streetAddress: _street.text,
          area: _area.text,
          landmark: _landmark.text,
          city: _city.text,
          state: _state.text,
          postalCode: _pincode.text,
          latitude: _latitude!,
          longitude: _longitude!,
          bookingPhone: _bookingPhone.text,
          serviceModes: ServiceMode.values.where(_modes.contains).toList(),
          serviceRadiusKm: _radiusKm,
          openingHours: _hours,
          about: _about.text,
          isListed: _isListed,
        ),
      );
      if (!mounted) return;
      _apply(saved);
      setState(() => _saving = false);
      context.showConsumerToast(context.l10n.shopListingSaved);
    } on Object catch (error) {
      if (mounted) setState(() => _saving = false);
      if (mounted) await context.showShopError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShopListing? listing = _listing;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.shopListingTitle)),
      bottomNavigationBar: listing == null || !_canEdit
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: ConsumerPrimaryButton(
                  key: const Key('listing.save'),
                  label: context.l10n.shopListingSave,
                  busy: _saving,
                  onPressed: _save,
                ),
              ),
            ),
      body: _loadError != null
          ? AppErrorView(message: context.consumerError(_loadError!), onRetry: _load)
          : listing == null
          ? const AppLoadingView()
          : _buildForm(context, listing),
    );
  }

  Widget _buildForm(BuildContext context, ShopListing listing) {
    final bool pinned = _latitude != null && _longitude != null;
    final bool editable = _canEdit;
    return Form(
      key: _form,
      child: AbsorbPointer(
        absorbing: !editable,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: <Widget>[
            if (!editable) ...<Widget>[
              _banner(context.l10n.shopListingNoPermission, AppColors.warningText, AppColors.warningSurface),
              const SizedBox(height: AppSpacing.lg),
            ],
            _statusBanner(context, listing),
            const SizedBox(height: AppSpacing.lg),
            Text('${listing.shopName}${listing.branchName.isEmpty ? '' : ' · ${listing.branchName}'}', style: AppTextStyles.headingMedium),
            if (listing.categories.isNotEmpty)
              Text(listing.categories.map(context.categoryLabel).join(', '), style: AppTextStyles.bodySmall),
            SwitchListTile(
              key: const Key('listing.listed'),
              contentPadding: EdgeInsets.zero,
              value: _isListed,
              onChanged: (bool v) => setState(() => _isListed = v),
              title: Text(context.l10n.shopListingShowToCustomers, style: AppTextStyles.title),
            ),
            const Divider(),
            ConsumerSectionTitle(context.l10n.shopListingAddressSection),
            OutlinedButton.icon(
              key: const Key('listing.pin'),
              onPressed: _locating ? null : _pin,
              icon: _locating
                  ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded),
              label: Text(_locating ? context.l10n.consumerLocating : context.l10n.shopListingPinShop),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        : context.l10n.shopListingPinHint,
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _field(_street, context.l10n.shopListingStreet, required: true),
            _field(_area, context.l10n.shopListingArea),
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
            _field(
              _bookingPhone,
              context.l10n.shopListingBookingPhone,
              keyboard: TextInputType.phone,
              hint: context.l10n.shopListingBookingPhoneHint(listing.ownerPhone),
              validator: (String? v) {
                final String digits = (v ?? '').replaceAll(RegExp(r'[\s()-]'), '');
                if (digits.isEmpty) return null;
                final bool mobile = RegExp(r'^(\+?91|0)?[6-9]\d{9}$').hasMatch(digits);
                final bool landline = RegExp(r'^(\+91|0)[1-9]\d{8,9}$').hasMatch(digits);
                return mobile || landline ? null : context.l10n.shopListingInvalidPhone;
              },
            ),
            const Divider(),
            ConsumerSectionTitle(context.l10n.shopListingHowServe),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: ServiceMode.values
                  .map(
                    (ServiceMode mode) => FilterChip(
                      avatar: Icon(modeIcon(mode), size: 18),
                      label: Text(context.modeLabel(mode)),
                      selected: _modes.contains(mode),
                      onSelected: (bool on) => setState(() => on ? _modes.add(mode) : _modes.remove(mode)),
                    ),
                  )
                  .toList(),
            ),
            if (_modes.any((ServiceMode m) => m.needsAddress)) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Text(context.l10n.shopListingRadius(_radiusKm), style: AppTextStyles.bodyMedium),
              Slider(
                value: _radiusKm.toDouble(),
                min: 1,
                max: 50,
                divisions: 49,
                label: '$_radiusKm km',
                onChanged: (double v) => setState(() => _radiusKm = v.round()),
              ),
            ],
            const Divider(),
            ConsumerSectionTitle(context.l10n.shopListingHours),
            for (final int day in <int>[1, 2, 3, 4, 5, 6, 0]) _dayRow(day),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _about,
              minLines: 2,
              maxLines: 4,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: context.l10n.shopListingAbout,
                hintText: context.l10n.shopListingAboutHint,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _dayRow(int day) {
    final OpeningHoursDay hours = _hours[day];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          SizedBox(width: 96, child: Text(context.weekdayName(day), style: AppTextStyles.bodyMedium)),
          Switch(
            value: !hours.closed,
            onChanged: (bool open) => setState(
              () => _hours[day] = OpeningHoursDay(
                day: day,
                closed: !open,
                open: hours.open ?? '09:00',
                close: hours.close ?? '20:00',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (hours.closed)
            Text(context.l10n.shopListingClosed, style: AppTextStyles.caption)
          else ...<Widget>[
            TextButton(onPressed: () => _pickTime(day, true), child: Text(context.formatClock(hours.open ?? '09:00'))),
            const Text('–'),
            TextButton(onPressed: () => _pickTime(day, false), child: Text(context.formatClock(hours.close ?? '20:00'))),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(BuildContext context, ShopListing listing) {
    if (listing.isVisibleToCustomers) {
      return _banner(context.l10n.shopListingVisible, AppColors.successDark, AppColors.successSurface);
    }
    final String text = switch (listing.hiddenReason) {
      'unlisted' => context.l10n.shopListingHiddenUnlisted,
      'business_inactive' => context.l10n.shopListingHiddenInactive,
      _ => context.l10n.shopListingHiddenIncomplete,
    };
    return _banner(text, AppColors.warningText, AppColors.warningSurface);
  }

  Widget _banner(String text, Color color, Color surface) => DecoratedBox(
    decoration: BoxDecoration(color: surface, borderRadius: AppRadius.cardRadius),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Text(text, style: AppTextStyles.labelBold.copyWith(color: color)),
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    String? hint,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppTextField(
        controller: controller,
        label: label,
        hintText: hint,
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        validator: validator ??
            (required ? (String? v) => (v?.trim().isEmpty ?? true) ? context.l10n.fieldRequired(label) : null : null),
      ),
    );
  }
}
