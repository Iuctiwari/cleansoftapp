import 'package:nexoraa_mobile/features/consumer/widgets/text_prompt_dialog.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/consumer_ui.dart';
import 'package:nexoraa_mobile/features/consumer/widgets/pickup_photos.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/models/shop_marketplace_models.dart';
import 'package:nexoraa_mobile/features/online_requests/services/shop_marketplace_api_service.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';
import 'package:nexoraa_mobile/features/orders/controllers/new_order_controller.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/screens/new_order_screen.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/order_catalog_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';

/// One online request: customer, what they want, and the shop's actions.
class ShopRequestDetailScreen extends StatefulWidget {
  const ShopRequestDetailScreen({
    required this.requestId,
    required this.branch,
    required this.service,
    this.staffService,
    super.key,
  });

  final String requestId;
  final ShopBranchArgs branch;
  final ShopMarketplaceApiService service;

  /// Lists the workers an owner/manager can send to collect (tests pass a fake).
  final StaffApiService? staffService;

  @override
  State<ShopRequestDetailScreen> createState() => _ShopRequestDetailScreenState();
}

class _ShopRequestDetailScreenState extends State<ShopRequestDetailScreen> {
  ShopRequest? _request;
  Object? _error;
  bool _busy = false;

  ShopMarketplaceApiService get _api => widget.service;
  AccessPolicy get _policy => shopAccessPolicy();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final ShopRequest request = await _api.getRequest(widget.requestId);
      if (mounted) setState(() => _request = request);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  /// Runs an action, shows [done] on success and the new state of the request.
  Future<void> _act(Future<ShopRequest> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      final ShopRequest updated = await action();
      if (!mounted) return;
      setState(() {
        _request = updated;
        _busy = false;
      });
      context.showConsumerToast(done);
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (mounted) await context.showShopError(error);
      await _load();
    }
  }

  /// Active workers of this branch: not the owner, a manager or a cashier.
  Future<List<StaffMember>> _loadWorkers() async {
    final String tenantId = AuthenticationDependencies.controller.session?.tenantId ?? '';
    final StaffApiService staff =
        widget.staffService ?? StaffApiService(tokenStorage: AuthenticationDependencies.tokenStorage);
    final List<StaffMember> all = await staff.getStaffMembers(tenantId);
    final String branchId = widget.branch.branchId;
    return all.where((StaffMember m) {
      final String role = m.role.toLowerCase();
      final bool isWorker = !role.contains('owner') && !role.contains('manager') && !role.contains('cashier');
      return m.status == 'Active' && isWorker && (m.branches.isEmpty || m.branches.contains(branchId));
    }).toList(growable: false);
  }

  /// Active workers of this branch. Empty is fine: the owner can always go themselves.
  Future<List<StaffMember>?> _workersOrError() async {
    setState(() => _busy = true);
    try {
      final List<StaffMember> workers = await _loadWorkers();
      if (!mounted) return null;
      setState(() => _busy = false);
      return workers;
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (mounted) await context.showShopError(error);
      return null;
    }
  }

  Future<void> _accept(ShopRequest request) async {
    final ServiceRequest r = request.base;
    final ValueNotifier<DateTime> when = ValueNotifier<DateTime>(
      DateTime.tryParse('${r.preferredDate}T${r.slotStart}:00') ?? DateTime.now(),
    );
    final String? note = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => TextPromptDialog(
        title: dialogContext.l10n.onlineRequestAcceptTitle,
        hint: dialogContext.l10n.onlineRequestNoteHint,
        confirmLabel: dialogContext.l10n.onlineRequestAccept,
        cancelLabel: MaterialLocalizations.of(dialogContext).cancelButtonLabel,
        confirmKey: const Key('accept.confirm'),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(dialogContext.l10n.onlineRequestConfirmTime, style: AppTextStyles.inputLabel),
            const SizedBox(height: AppSpacing.sm),
            ValueListenableBuilder<DateTime>(
              valueListenable: when,
              builder: (BuildContext context, DateTime value, _) => OutlinedButton.icon(
                key: const Key('accept.time'),
                icon: const Icon(Icons.event_outlined),
                label: Text(context.formatDateTime(value)),
                onPressed: () async {
                  final DateTime today = DateUtils.dateOnly(DateTime.now());
                  final DateTime? day = await showDatePicker(
                    context: context,
                    initialDate: value.isBefore(today) ? today : value,
                    firstDate: today,
                    lastDate: today.add(const Duration(days: 60)),
                  );
                  if (day == null || !context.mounted) return;
                  final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
                  if (time == null) return;
                  when.value = DateTime(day.year, day.month, day.day, time.hour, time.minute);
                },
              ),
            ),
          ],
        ),
      ),
    );
    final DateTime confirmedAt = when.value;
    when.dispose();
    if (note == null || !mounted) return;
    await _act(
      () => _api.accept(request.requestId, confirmedAt: confirmedAt, note: note),
      context.l10n.onlineRequestAccepted,
    );
    // Pickup or home visit: decide straight away who goes.
    final ShopRequest? after = _request;
    if (mounted && after != null && after.canAssignWorker && after.pickupWorkerId == null) {
      await _assign(after);
    }
  }

  /// Who goes to collect: the owner/manager themselves, or one of the workers.
  Future<void> _assign(ShopRequest request) async {
    final List<StaffMember>? workers = await _workersOrError();
    if (workers == null || !mounted) return;
    final ({String id, String name})? chosen = await showModalBottomSheet<({String id, String name})>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(sheetContext.l10n.pickupAssignTitle, style: AppTextStyles.title),
            ),
            ListTile(
              key: const Key('assign.me'),
              leading: const Icon(Icons.person_outline),
              title: Text(sheetContext.l10n.pickupAssignMe),
              onTap: () => Navigator.of(sheetContext).pop((
                id: 'me',
                name: AuthenticationDependencies.controller.session?.ownerName ?? 'Owner',
              )),
            ),
            for (final StaffMember w in workers)
              ListTile(
                key: Key('assign.worker.${w.id}'),
                leading: const Icon(Icons.directions_walk_outlined),
                title: Text(w.displayName),
                onTap: () => Navigator.of(sheetContext).pop((id: w.id, name: w.displayName)),
              ),
            if (workers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(sheetContext.l10n.pickupAssignNoWorkers, style: AppTextStyles.caption),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    await _act(
      () => _api.assignWorker(request.requestId, workerId: chosen.id, workerName: chosen.name),
      context.l10n.pickupAssignedToast,
    );
  }

  /// The collector is at the door: the New Order wizard opens with the customer chosen
  /// and an extra Photos step; saving it also records the pickup.
  Future<void> _startPickup(ShopRequest request) => _createOrder(request, pickup: true);

  /// Uploads the photos, then marks the pickup collected so the customer is told.
  Future<void> _finishPickup(
    ShopRequest request, {
    List<Uint8List> photos = const <Uint8List>[],
    int? totalItems,
    String? deliveryDate,
  }) async {
    setState(() => _busy = true);
    final List<String> keys = <String>[];
    int failed = 0;
    try {
      if (photos.isNotEmpty) {
        List<PhotoSlot> slots = const <PhotoSlot>[];
        try {
          slots = await _api.photoUploadSlots(request.requestId, count: photos.length);
        } on Object {
          failed = photos.length;
        }
        for (int i = 0; i < slots.length; i++) {
          try {
            await _api.uploadPhoto(slots[i], photos[i]);
            keys.add(slots[i].key);
          } on Object {
            failed++;
          }
        }
      }
      final ShopRequest done = await _api.collect(
        request.requestId,
        totalItems: totalItems,
        deliveryDate: deliveryDate,
        photoKeys: keys,
      );
      if (!mounted) return;
      setState(() {
        _request = done;
        _busy = false;
      });
      context.showConsumerToast(context.l10n.pickupCollectedToast);
      if (failed > 0) {
        await AppAlertDialog.show(
          context,
          title: context.l10n.pickupPhotosHeading,
          message: context.l10n.pickupPhotosFailed(failed),
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (!mounted) return;
      await AppAlertDialog.show(
        context,
        title: context.l10n.pickupStart,
        message: '${context.l10n.pickupNotRecorded}\n\n${context.consumerError(error)}',
      );
    }
  }

  Future<void> _decline(ShopRequest request) async {
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => TextPromptDialog(
        title: dialogContext.l10n.onlineRequestDeclineTitle,
        hint: dialogContext.l10n.onlineRequestDeclineHint,
        confirmLabel: dialogContext.l10n.onlineRequestDecline,
        cancelLabel: MaterialLocalizations.of(dialogContext).cancelButtonLabel,
        minLength: 3,
        tooShortMessage: dialogContext.l10n.onlineRequestDeclineNeedReason,
        destructive: true,
        fieldKey: const Key('decline.reason'),
        confirmKey: const Key('decline.confirm'),
      ),
    );
    if (reason == null || !mounted) return;
    await _act(() => _api.decline(request.requestId, reason: reason), context.l10n.onlineRequestDeclined);
  }

  Future<void> _complete(ShopRequest request) async {
    final bool ok = await AppConfirmDialog.show(
      context,
      title: context.l10n.onlineRequestCompleteTitle,
      message: '${request.base.requestNumber} · ${request.customerName}',
      confirmLabel: context.l10n.onlineRequestComplete,
      destructive: false,
    );
    if (!ok || !mounted) return;
    await _act(() => _api.complete(request.requestId), context.l10n.onlineRequestCompleted);
  }

  /// Opens the normal New Order screen with this customer already chosen,
  /// then links the created order to the request.
  Future<void> _createOrder(ShopRequest request, {bool pickup = false}) async {
    final bool mayCreate = _policy.allows(AppCapability.ordersCreate) || request.pickupWorkerId != null;
    if (!mayCreate) {
      await AppAlertDialog.show(
        context,
        title: context.l10n.onlineRequestCreateOrder,
        message: context.l10n.onlineRequestStaffCannotCreate,
      );
      return;
    }
    final String branchId = widget.branch.branchId;
    final CustomerApiService customerService = CustomerApiService(tokenStorage: AuthenticationDependencies.tokenStorage)
      ..selectBranch(branchId);
    final OrderApiService orderService = OrderApiService(tokenStorage: AuthenticationDependencies.tokenStorage)
      ..selectBranch(branchId);
    final OrderController orderController = OrderController(service: orderService);
    final CustomerController customerController = CustomerController(service: customerService, orderService: orderService);
    final NewOrderController newOrder = NewOrderController(
      catalogService: OrderCatalogApiService(tokenStorage: AuthenticationDependencies.tokenStorage),
      orderController: orderController,
      paymentService: PaymentApiService(tokenStorage: AuthenticationDependencies.tokenStorage),
      branchId: branchId,
      pickup: pickup
          ? PickupOrderContext(
              requestId: request.requestId,
              estimate: (int quantity) => _api.estimateDelivery(request.requestId, quantity: quantity),
            )
          : null,
    );

    setState(() => _busy = true);
    try {
      if (request.shopCustomerId != null) {
        final Customer customer = await customerService.getById(request.shopCustomerId!);
        newOrder.selectCustomer(customer);
      }
    } on Object {
      // The customer can still be picked by hand on the order screen.
    }
    if (!mounted) return;
    setState(() => _busy = false);

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NewOrderScreen(
          controller: newOrder,
          orderController: orderController,
          customerController: customerController,
          businessName: widget.branch.businessName,
          branchName: widget.branch.branchName,
        ),
      ),
    );
    final Order? created = newOrder.createdOrder;
    // Taken before the wizard is disposed: the pickup needs them afterwards.
    final List<Uint8List> photos = newOrder.photos;
    final int? totalItems = newOrder.totalItems;
    final String? deliveryDate = newOrder.deliveryDate;
    newOrder.dispose();
    orderController.dispose();
    customerController.dispose();
    if (created == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final ShopRequest linked = await _api.linkOrder(request.requestId, orderId: created.id);
      if (!mounted) return;
      setState(() {
        _request = linked;
        _busy = false;
      });
      context.showConsumerToast(context.l10n.onlineRequestOrderLinked(created.orderNumber));
      if (pickup && linked.canCollect) {
        await _finishPickup(linked, photos: photos, totalItems: totalItems, deliveryDate: deliveryDate);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _busy = false);
      if (!mounted) return;
      await AppAlertDialog.show(
        context,
        title: context.l10n.onlineRequestCreateOrder,
        message: '${context.l10n.onlineRequestOrderNotLinked}\n\n${context.consumerError(error)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ShopRequest? request = _request;
    return Scaffold(
      appBar: AppBar(title: Text(request?.base.requestNumber ?? context.l10n.onlineRequestsTitle)),
      bottomNavigationBar: request == null ? null : _actions(context, request),
      body: _error != null
          ? AppErrorView(message: context.consumerError(_error!), onRetry: _load)
          : request == null
          ? const AppLoadingView()
          : RefreshIndicator(onRefresh: _load, child: _body(context, request)),
    );
  }

  Widget? _actions(BuildContext context, ShopRequest request) {
    final bool canEdit = _policy.allows(AppCapability.ordersEdit);
    if (!canEdit) return null;
    final List<Widget> buttons = <Widget>[
      if (request.canDecline)
        Expanded(
          child: OutlinedButton(
            key: const Key('request.decline'),
            onPressed: _busy ? null : () => _decline(request),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, minimumSize: const Size.fromHeight(48)),
            child: Text(context.l10n.onlineRequestDecline),
          ),
        ),
      if (request.canAccept)
        Expanded(
          child: FilledButton(
            key: const Key('request.accept'),
            onPressed: _busy ? null : () => _accept(request),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(context.l10n.onlineRequestAccept),
          ),
        ),
      if (request.canAssignWorker && request.pickupWorkerId == null)
        Expanded(
          child: FilledButton(
            key: const Key('request.assign'),
            onPressed: _busy ? null : () => _assign(request),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(context.l10n.pickupAssignButton),
          ),
        ),
      if (request.canCollect && request.orderId == null)
        Expanded(
          child: FilledButton(
            key: const Key('request.startPickup'),
            onPressed: _busy ? null : () => _startPickup(request),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(context.l10n.pickupStart),
          ),
        ),
      if (request.canCollect && request.orderId != null)
        Expanded(
          child: FilledButton(
            key: const Key('request.finishPickup'),
            onPressed: _busy ? null : () => _finishPickup(request),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(context.l10n.pickupFinish),
          ),
        ),
      if (request.canLinkOrder && !request.canCollect && !(request.canAssignWorker && request.pickupWorkerId == null))
        Expanded(
          child: FilledButton(
            key: const Key('request.createOrder'),
            onPressed: _busy ? null : () => _createOrder(request),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(context.l10n.onlineRequestCreateOrder),
          ),
        ),
      if (request.canComplete && !request.canLinkOrder && !request.canCollect)
        Expanded(
          child: FilledButton(
            key: const Key('request.complete'),
            onPressed: _busy ? null : () => _complete(request),
            style: FilledButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size.fromHeight(48)),
            child: Text(context.l10n.onlineRequestComplete),
          ),
        ),
    ];
    if (buttons.isEmpty) return null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < buttons.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              buttons[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ShopRequest request) {
    final ServiceRequest r = request.base;
    final DateTime? date = DateTime.tryParse(r.preferredDate);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(request.customerName, style: AppTextStyles.headingLarge)),
            AppStatusBadge(label: context.statusLabel(r.status), tone: statusTone(r.status)),
          ],
        ),
        Text(context.l10n.onlineRequestReceived(context.formatDateTime(r.createdAt)), style: AppTextStyles.caption),
        if (r.status == RequestStatus.pending && r.expiresAt != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _note(context.l10n.onlineRequestExpiresAt(context.formatDateTime(r.expiresAt!)), AppColors.warningText, AppColors.warningSurface),
        ],
        if (r.orderNumber != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _note(context.l10n.consumerOrderCreated(r.orderNumber!), AppColors.primary, AppColors.primarySurface),
        ],
        if (r.declineReason != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _note('${context.l10n.consumerReason}: ${r.declineReason}', AppColors.errorText, AppColors.errorSurface),
        ],
        if (r.cancelReason != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _note('${context.l10n.consumerReason}: ${r.cancelReason}', AppColors.textSecondary, AppColors.surfaceMuted),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(context.l10n.onlineRequestCustomer, style: AppTextStyles.labelBold),
              const SizedBox(height: AppSpacing.xs),
              _row(AppIcons.user, request.customerName),
              _row(AppIcons.phone, request.customerMobile),
              if (request.customerEmail.isNotEmpty) _row(AppIcons.email, request.customerEmail),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  OutlinedButton.icon(
                    onPressed: () => context.callPhone(request.addressContactPhone ?? request.customerMobile),
                    icon: const Icon(AppIcons.phone, size: 18),
                    label: Text(context.l10n.onlineRequestCallCustomer),
                  ),
                  if (request.addressLatitude != null && request.addressLongitude != null)
                    OutlinedButton.icon(
                      onPressed: () => context.openDirections(request.addressLatitude!, request.addressLongitude!),
                      icon: const Icon(Icons.directions_outlined, size: 18),
                      label: Text(context.l10n.consumerDirections),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _row(categoryIcon(r.category), context.categoryLabel(r.category)),
              _row(modeIcon(r.requestType), context.modeLabel(r.requestType)),
              _row(
                AppIcons.clock,
                r.confirmedAt != null
                    ? '${context.l10n.consumerConfirmedTime}: ${context.formatDateTime(r.confirmedAt!)}'
                    : '${context.l10n.consumerPreferredTime}: '
                          '${date == null ? r.preferredDate : context.formatDay(date)}, '
                          '${context.formatClock(r.slotStart)} – ${context.formatClock(r.slotEnd)}',
              ),
              if (r.pickupWorkerName != null)
                _row(Icons.directions_walk_outlined, context.l10n.pickupBy(r.pickupWorkerName!)),
              if (request.canAssignWorker && request.pickupWorkerId != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    key: const Key('request.changeWorker'),
                    onPressed: _busy ? null : () => _assign(request),
                    child: Text(context.l10n.pickupChangeWorker),
                  ),
                ),
              if (r.deliveryDate != null)
                _row(
                  Icons.local_shipping_outlined,
                  context.l10n.pickupDeliveryOn(
                    DateTime.tryParse(r.deliveryDate!) == null
                        ? r.deliveryDate!
                        : context.formatDay(DateTime.parse(r.deliveryDate!)),
                  ),
                ),
              if (r.addressFormatted != null)
                _row(
                  AppIcons.location,
                  <String?>[
                    r.addressFormatted,
                    request.addressLandmark,
                    if (request.distanceKm != null)
                      context.l10n.onlineRequestDistance(request.distanceKm!.toStringAsFixed(1)),
                  ].whereType<String>().join('\n'),
                ),
              const Divider(),
              Text(r.description, style: AppTextStyles.bodyMedium),
              if (r.items.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(context.l10n.consumerItems, style: AppTextStyles.labelBold),
                for (final RequestItem item in r.items)
                  Text('• ${item.name} × ${item.quantity}', style: AppTextStyles.bodySmall),
              ],
              if (r.collectedTotal != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(context.l10n.pickupTotalItemsLine(r.collectedTotal!), style: AppTextStyles.labelBold),
              ],
              if (r.collectedPhotos.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                PickupPhotos(urls: r.collectedPhotos),
              ],
              if (r.shopNote != null) ...<Widget>[
                const Divider(),
                Text(context.l10n.consumerShopMessage, style: AppTextStyles.labelBold),
                Text(r.shopNote!, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ConsumerSectionTitle(context.l10n.consumerHistory),
        for (final RequestHistoryEntry entry in r.history.reversed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.circle, size: 10, color: AppColors.primary),
            title: Text(
              '${context.statusLabel(entry.status)} · ${switch (entry.by) {
                'customer' => context.l10n.onlineRequestCustomer,
                'shop' => context.l10n.consumerByShop,
                _ => context.l10n.consumerByAutomatic,
              }}',
              style: AppTextStyles.labelBold,
            ),
            subtitle: Text(
              <String>[context.formatDateTime(entry.at), if (entry.note != null) entry.note!].join('\n'),
              style: AppTextStyles.caption,
            ),
          ),
      ],
    );
  }

  Widget _note(String text, Color color, Color surface) => DecoratedBox(
    decoration: BoxDecoration(color: surface, borderRadius: AppRadius.cardRadius),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(text, style: AppTextStyles.labelBold.copyWith(color: color)),
    ),
  );

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: AppColors.textSubtle),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
      ],
    ),
  );
}
