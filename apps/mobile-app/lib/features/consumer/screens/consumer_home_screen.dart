import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/core/push/push_dependencies.dart';
import 'package:nexoraa_mobile/core/push/push_platform.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/services/location_service.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/shop_card.dart';

/// The customer's home: Shops, My requests and Account tabs.
class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({this.initialTab = 0, this.pushes, super.key});

  final int initialTab;

  /// Pushes that arrive while the app is open; defaults to the app's own.
  final Stream<PushPayload>? pushes;

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  late int _tab = widget.initialTab;
  final GlobalKey<_RequestsTabState> _requestsKey = GlobalKey<_RequestsTabState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: <Widget>[
            const _ShopsTab(),
            _RequestsTab(key: _requestsKey, pushes: widget.pushes),
            const _AccountTab(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (int index) {
          setState(() => _tab = index);
          if (index == 1) _requestsKey.currentState?.reload();
        },
        destinations: <NavigationDestination>[
          NavigationDestination(icon: const Icon(Icons.storefront_outlined), label: context.l10n.consumerTabShops),
          NavigationDestination(icon: const Icon(AppIcons.orders), label: context.l10n.consumerTabRequests),
          NavigationDestination(icon: const Icon(AppIcons.user), label: context.l10n.consumerTabAccount),
        ],
      ),
    );
  }
}

// ── Shops ────────────────────────────────────────────────────────────────────

class _ShopsTab extends StatefulWidget {
  const _ShopsTab();

  @override
  State<_ShopsTab> createState() => _ShopsTabState();
}

class _ShopsTabState extends State<_ShopsTab> {
  static const List<int> _radiusOptions = <int>[3, 5, 10, 20, 50];

  final TextEditingController _search = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  List<ConsumerAddress> _addresses = <ConsumerAddress>[];
  ShopSearchFilters _filters = const ShopSearchFilters();
  final List<ShopSummary> _shops = <ShopSummary>[];
  int _page = 1;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    unawaited(_start());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      _addresses = await ConsumerDependencies.api.listAddresses();
      if (!mounted) return;
      if (_addresses.isEmpty) {
        // An address is compulsory before browsing.
        context.goNamed(AppRouteNames.consumerAddressNew, extra: true);
        return;
      }
      final ConsumerAddress home = _addresses.firstWhere(
        (ConsumerAddress a) => a.isDefault,
        orElse: () => _addresses.first,
      );
      _filters = _filters.copyWith(addressId: home.addressId, clearLocation: true);
      await _load(reset: true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
      await context.showConsumerError(error);
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final ShopSearchPage page = await ConsumerDependencies.api.searchShops(_filters, page: reset ? 1 : _page + 1);
      if (!mounted) return;
      setState(() {
        if (reset) _shops.clear();
        _shops.addAll(page.items);
        _page = page.page;
        _total = page.total;
        _loading = false;
        _loadingMore = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _error = reset ? error : _error;
        _loading = false;
        _loadingMore = false;
      });
      if (!reset) await context.showConsumerError(error);
    }
  }

  void _onScroll() {
    if (_loadingMore || _loading || _shops.length >= _total) return;
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
      setState(() => _loadingMore = true);
      unawaited(_load());
    }
  }

  void _apply(ShopSearchFilters filters) {
    setState(() => _filters = filters);
    unawaited(_load(reset: true));
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _apply(_filters.copyWith(query: text)));
  }

  String _locationTitle() {
    if (_filters.usesCurrentLocation) return context.l10n.consumerCurrentLocation;
    for (final ConsumerAddress address in _addresses) {
      if (address.addressId == _filters.addressId) {
        return '${context.addressLabel(address.label)} · ${address.streetArea}';
      }
    }
    return context.l10n.consumerChooseLocation;
  }

  Future<void> _chooseLocation() async {
    final Object? choice = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(sheetContext.l10n.consumerChooseLocation, style: AppTextStyles.headingSmall),
            ),
            ListTile(
              leading: const Icon(Icons.my_location_rounded, color: AppColors.primary),
              title: Text(sheetContext.l10n.consumerUseCurrentLocation),
              onTap: () => Navigator.pop(sheetContext, 'gps'),
            ),
            for (final ConsumerAddress address in _addresses)
              ListTile(
                leading: Icon(
                  address.addressId == _filters.addressId && !_filters.usesCurrentLocation
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: AppColors.primary,
                ),
                title: Text(sheetContext.addressLabel(address.label)),
                subtitle: Text(address.formatted, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.pop(sheetContext, address),
              ),
            ListTile(
              leading: const Icon(AppIcons.add, color: AppColors.primary),
              title: Text(sheetContext.l10n.consumerAddAddress),
              onTap: () => Navigator.pop(sheetContext, 'add'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;

    if (choice is ConsumerAddress) {
      _apply(_filters.copyWith(addressId: choice.addressId, clearLocation: true));
    } else if (choice == 'add') {
      final Object? added = await context.pushNamed<Object>(AppRouteNames.consumerAddressNew);
      if (added is ConsumerAddress && mounted) {
        _addresses = await ConsumerDependencies.api.listAddresses();
        _apply(_filters.copyWith(addressId: added.addressId, clearLocation: true));
      }
    } else if (choice == 'gps') {
      final LocationResult result = await ConsumerDependencies.location.currentPosition();
      if (!mounted) return;
      if (!result.ok) {
        context.showConsumerToast(
          result.failure == LocationFailure.serviceOff
              ? context.l10n.consumerLocationOff
              : context.l10n.consumerLocationUnavailable,
        );
        return;
      }
      _apply(_filters.copyWith(latitude: result.latitude, longitude: result.longitude, clearLocation: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _header(),
        _categoryChips(),
        _filterChips(),
        const Divider(height: 1),
        Expanded(child: _results()),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            key: const Key('shops.location'),
            onTap: _chooseLocation,
            borderRadius: AppRadius.cardRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: <Widget>[
                  const Icon(AppIcons.location, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(context.l10n.consumerShowingNear, style: AppTextStyles.caption),
                        Text(
                          _locationTitle(),
                          style: AppTextStyles.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(AppIcons.chevronDown),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: context.l10n.consumerSearchShops,
              prefixIcon: const Icon(AppIcons.search),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(context.l10n.consumerFilterAll),
              selected: _filters.category == null,
              onSelected: (_) => _apply(_filters.copyWith(clearCategory: true)),
            ),
          ),
          for (final ShopCategory category in ShopCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                avatar: Icon(categoryIcon(category), size: 18),
                label: Text(context.categoryLabel(category)),
                selected: _filters.category == category,
                onSelected: (bool on) =>
                    _apply(on ? _filters.copyWith(category: category) : _filters.copyWith(clearCategory: true)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(context.l10n.consumerFilterOpenNow),
              selected: _filters.openNow,
              onSelected: (bool on) => _apply(_filters.copyWith(openNow: on)),
            ),
          ),
          for (final ServiceMode mode in <ServiceMode>[ServiceMode.homeService, ServiceMode.pickupDrop])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                avatar: Icon(modeIcon(mode), size: 18),
                label: Text(context.modeLabel(mode)),
                selected: _filters.mode == mode,
                onSelected: (bool on) =>
                    _apply(on ? _filters.copyWith(mode: mode) : _filters.copyWith(clearMode: true)),
              ),
            ),
          PopupMenuButton<int>(
            initialValue: _filters.radiusKm,
            onSelected: (int km) => _apply(_filters.copyWith(radiusKm: km)),
            itemBuilder: (BuildContext context) => _radiusOptions
                .map((int km) => PopupMenuItem<int>(value: km, child: Text(context.l10n.consumerWithinKm(km))))
                .toList(),
            child: Chip(
              avatar: const Icon(Icons.social_distance_outlined, size: 18),
              label: Text(context.l10n.consumerWithinKm(_filters.radiusKm)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _results() {
    if (_loading) return const AppLoadingView();
    if (_error != null && _shops.isEmpty) {
      return AppErrorView(message: context.consumerError(_error!), onRetry: () => _load(reset: true));
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: _shops.isEmpty
          ? ListView(
              children: <Widget>[
                const SizedBox(height: AppSpacing.section),
                AppEmptyState(
                  icon: Icons.store_mall_directory_outlined,
                  title: context.l10n.consumerNoShopsTitle,
                  message: context.l10n.consumerNoShopsMessage,
                ),
              ],
            )
          : ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: _shops.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (BuildContext context, int index) {
                if (index >= _shops.length) return const AppLoadingView();
                final ShopSummary shop = _shops[index];
                return ShopCard(
                  shop: shop,
                  highlightReach: _filters.mode?.needsAddress ?? false,
                  onOpen: () => context.pushNamed(
                    AppRouteNames.consumerShop,
                    pathParameters: <String, String>{'shopId': shop.shopId},
                    extra: _filters,
                  ),
                );
              },
            ),
    );
  }
}

// ── My requests ──────────────────────────────────────────────────────────────

class _RequestsTab extends StatefulWidget {
  const _RequestsTab({this.pushes, super.key});

  final Stream<PushPayload>? pushes;

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  RequestStatus? _status;
  late Future<ServiceRequestPage> _requests = _fetch();
  StreamSubscription<PushPayload>? _pushSubscription;

  @override
  void initState() {
    super.initState();
    // The shop answered while the list is on screen: show it straight away.
    _pushSubscription = (widget.pushes ?? PushDependencies.registrar.arrivals).listen((
      PushPayload payload,
    ) {
      if ((payload.data['type'] ?? '').startsWith('request_')) reload();
    });
  }

  @override
  void dispose() {
    unawaited(_pushSubscription?.cancel());
    super.dispose();
  }

  Future<ServiceRequestPage> _fetch() => ConsumerDependencies.api.listRequests(status: _status);

  void reload() {
    setState(() {
      _requests = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
          child: Text(context.l10n.consumerTabRequests, style: AppTextStyles.headingMedium),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            children: <Widget>[
              for (final RequestStatus? status in <RequestStatus?>[
                null,
                RequestStatus.pending,
                RequestStatus.accepted,
                RequestStatus.completed,
                RequestStatus.declined,
                RequestStatus.cancelled,
                RequestStatus.expired,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(status == null ? context.l10n.consumerFilterAll : context.statusLabel(status)),
                    selected: _status == status,
                    onSelected: (_) {
                      _status = status;
                      reload();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<ServiceRequestPage>(
            future: _requests,
            builder: (BuildContext context, AsyncSnapshot<ServiceRequestPage> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) return const AppLoadingView();
              if (snapshot.hasError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) unawaited(context.showConsumerError(snapshot.error!));
                });
                return AppErrorView(message: context.consumerError(snapshot.error!), onRetry: reload);
              }
              final List<ServiceRequest> items = snapshot.data!.items;
              return RefreshIndicator(
                onRefresh: () async => reload(),
                child: items.isEmpty
                    ? ListView(
                        children: <Widget>[
                          const SizedBox(height: AppSpacing.section),
                          AppEmptyState(
                            icon: AppIcons.orders,
                            title: context.l10n.consumerNoRequestsTitle,
                            message: context.l10n.consumerNoRequestsMessage,
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (BuildContext context, int index) => _RequestCard(
                          request: items[index],
                          onOpen: () async {
                            await context.pushNamed(
                              AppRouteNames.consumerRequest,
                              pathParameters: <String, String>{'requestId': items[index].requestId},
                            );
                            reload();
                          },
                        ),
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.onOpen});

  final ServiceRequest request;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final DateTime? date = DateTime.tryParse(request.preferredDate);
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(request.shopName, style: AppTextStyles.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
              AppStatusBadge(label: context.statusLabel(request.status), tone: statusTone(request.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${context.categoryLabel(request.category)} · ${context.modeLabel(request.requestType)}',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              const Icon(AppIcons.clock, size: 16, color: AppColors.textSubtle),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  request.confirmedAt != null
                      ? context.formatDateTime(request.confirmedAt!)
                      : '${date == null ? request.preferredDate : context.formatDay(date)}, '
                            '${context.formatClock(request.slotStart)} – ${context.formatClock(request.slotEnd)}',
                  style: AppTextStyles.caption,
                ),
              ),
              Text(request.requestNumber, style: AppTextStyles.micro),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Account ──────────────────────────────────────────────────────────────────

class _AccountTab extends StatelessWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context) {
    final session = ConsumerDependencies.controller.session;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        Text(context.l10n.consumerAccountTitle, style: AppTextStyles.headingMedium),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  (session?.displayName.isNotEmpty ?? false) ? session!.displayName[0].toUpperCase() : '?',
                  style: AppTextStyles.headingMedium.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(session?.displayName ?? '', style: AppTextStyles.title),
                    Text(session?.email ?? '', style: AppTextStyles.bodySmall),
                    Text(session?.mobileNumber ?? '', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ListTile(
          leading: const Icon(AppIcons.location),
          title: Text(context.l10n.consumerAddresses),
          trailing: const Icon(AppIcons.chevronRight),
          onTap: () => context.pushNamed(AppRouteNames.consumerAddresses),
        ),
        ListTile(
          leading: const Icon(Icons.translate_rounded),
          title: Text(context.l10n.language),
          trailing: const Icon(AppIcons.chevronRight),
          onTap: () => showLanguagePicker(context),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(AppIcons.logout, color: AppColors.error),
          title: Text(context.l10n.signOut, style: const TextStyle(color: AppColors.error)),
          onTap: () async {
            final bool ok = await AppConfirmDialog.show(
              context,
              title: context.l10n.signOut,
              message: context.l10n.consumerSignOutConfirm,
              confirmLabel: context.l10n.signOut,
            );
            if (!ok) return;
            await ConsumerDependencies.controller.signOut();
            if (context.mounted) context.goNamed(AppRouteNames.welcome);
          },
        ),
      ],
    );
  }
}
