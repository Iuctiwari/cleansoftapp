import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_form_screen.dart';
import 'package:nexoraa_mobile/features/orders/controllers/new_order_controller.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/models/order_catalog.dart';
import 'package:nexoraa_mobile/features/orders/screens/order_details_screen.dart';
import 'package:nexoraa_mobile/features/orders/widgets/new_order_widgets.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';
import 'package:nexoraa_mobile/features/receipt/screens/receipt_preview_screen.dart';
import 'package:nexoraa_mobile/features/salon/models/salon_models.dart';

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({
    required this.controller,
    required this.orderController,
    required this.customerController,
    required this.businessName,
    required this.branchName,
    this.takePhoto,
    super.key,
  });

  /// Opens the camera for the pickup photos; tests pass a fake. Null = the phone camera.
  final Future<XFile?> Function()? takePhoto;

  final NewOrderController controller;
  final OrderController orderController;
  final CustomerController customerController;
  final String businessName;
  final String branchName;

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final TextEditingController _customerSearch = TextEditingController();
  final TextEditingController _discount = TextEditingController();
  final TextEditingController _advancePayment = TextEditingController();
  final TextEditingController _totalItems = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    widget.customerController.addListener(_refresh);
    _discount.addListener(_discountChanged);
    _advancePayment.addListener(_advancePaymentChanged);
    _totalItems.addListener(
      () => widget.controller.setTotalItems(_totalItems.text),
    );
    if (widget.customerController.customers.isEmpty &&
        !widget.customerController.isLoading) {
      unawaited(widget.customerController.load());
    }
    unawaited(widget.controller.loadCatalog());
    unawaited(widget.controller.loadSalon());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _customerSearch.dispose();
    _totalItems.dispose();
    _discount.removeListener(_discountChanged);
    _discount.dispose();
    _advancePayment
      ..removeListener(_advancePaymentChanged)
      ..dispose();
    widget.controller.removeListener(_refresh);
    widget.customerController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _discountChanged() {
    widget.controller.setDiscount(_discount.text);
  }

  void _advancePaymentChanged() {
    widget.controller.setAdvancePayment(_advancePayment.text);
  }

  void _closeOrBack() {
    if (widget.controller.stage == NewOrderStage.customer ||
        widget.controller.stage == NewOrderStage.receipt) {
      Navigator.of(context).pop(widget.controller.createdOrder != null);
      return;
    }
    widget.controller.back();
  }

  void _next() {
    final NewOrderStage current = widget.controller.stage;
    if (!widget.controller.next()) {
      _showError();
      return;
    }
    if (current == NewOrderStage.customer)
      unawaited(widget.controller.loadCatalog());
  }

  Future<void> _confirmSalonServices() async {
    if (!await widget.controller.confirmSalonServices()) _showError();
  }

  Future<void> _save() async {
    final Order? order = await widget.controller.save();
    if (order == null && mounted) _showError();
  }

  void _showError() {
    final String? error = widget.controller.error;
    if (error == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error)));
  }

  void _searchCustomers(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(widget.customerController.load(search: value));
    });
  }

  Future<void> _addCustomer() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            CustomerFormScreen(controller: widget.customerController),
      ),
    );
    if (created == true) {
      _customerSearch.clear();
      await widget.customerController.load();
    }
  }

  Future<void> _editAmount(OrderItemCategory category, double amount) async {
    final TextEditingController field = TextEditingController(
      text: amount == 0 ? '' : newOrderAmount(amount),
    );
    final double? result = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: Text(
          category.unitType == CatalogUnitType.kg
              ? 'Enter weight'
              : 'Enter quantity',
        ),
        content: TextField(
          controller: field,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: category.unitType == CatalogUnitType.kg
                ? 'Weight (kg)'
                : 'Quantity',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(double.tryParse(field.text.trim())),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    field.dispose();
    if (result != null) widget.controller.changeAmount(category, result);
  }

  Future<void> _done() async {
    final Order? order = widget.controller.createdOrder;
    if (order == null) return;
    await Navigator.of(context).pushReplacement<void, bool>(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsScreen(
          orderId: order.id,
          controller: widget.orderController,
        ),
      ),
    );
  }

  Future<void> _openReceipt(Order order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReceiptPreviewScreen(
          orderId: order.id,
          branchId: order.branchId,
          orderNumber: order.orderNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => NewOrderStepScaffold(
    step: widget.controller.step,
    stepCount: widget.controller.stepCount,
    onClose: _closeOrBack,
    body: AnimatedSwitcher(
      duration: AppDurations.fast,
      child: KeyedSubtree(
        key: ValueKey<int>(widget.controller.step),
        child: _body(),
      ),
    ),
    footer: _footer(),
  );

  Widget _body() => switch (widget.controller.stage) {
    NewOrderStage.customer => _customerStep(),
    NewOrderStage.items => _itemsStep(),
    NewOrderStage.services => _servicesStep(),
    NewOrderStage.salonServices => _salonServicesStep(),
    NewOrderStage.pricing => _pricingStep(),
    NewOrderStage.photos => _photosStep(),
    NewOrderStage.payment => _paymentStep(),
    NewOrderStage.receipt => _receiptStep(),
  };

  Widget _footer() {
    final NewOrderStage step = widget.controller.stage;
    if (step == NewOrderStage.payment) {
      return NewOrderFooter(
        secondaryLabel: 'Back',
        primaryLabel: 'Save Order',
        onSecondary: widget.controller.createdOrder == null
            ? widget.controller.back
            : null,
        onPrimary: _save,
        busy: widget.controller.isSaving,
      );
    }
    if (step == NewOrderStage.receipt) {
      return NewOrderFooter(
        secondaryLabel: 'Orders',
        primaryLabel: 'Done',
        onSecondary: () => Navigator.of(context).pop(true),
        onPrimary: _done,
      );
    }
    final bool first =
        step == NewOrderStage.customer || widget.controller.step == 0;
    return NewOrderFooter(
      secondaryLabel: first ? 'Cancel' : 'Back',
      primaryLabel: 'Next',
      onSecondary: first
          ? () => Navigator.of(context).pop(false)
          : widget.controller.back,
      onPrimary:
          step == NewOrderStage.items && widget.controller.selections.isEmpty
          ? null
          : step == NewOrderStage.salonServices
          ? (widget.controller.salonChosenItems.isEmpty ||
                    widget.controller.isQuoting
                ? null
                : _confirmSalonServices)
          : _next,
    );
  }

  Widget _customerStep() => NotificationListener<ScrollNotification>(
    onNotification: (ScrollNotification notification) {
      if (notification.metrics.extentAfter < 180) {
        unawaited(widget.customerController.loadMore());
      }
      return false;
    },
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xl,
        AppSpacing.pageHorizontal,
        AppSpacing.pageBottom,
      ),
      children: <Widget>[
        Text('Customer', style: AppTextStyles.headingSmall),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _customerSearch,
          onChanged: _searchCustomers,
          decoration: const InputDecoration(
            hintText: 'Search by name or phone...',
            prefixIcon: Icon(AppIcons.search),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ..._customerContent(),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
              color: AppColors.primary,
              style: BorderStyle.solid,
            ),
            foregroundColor: AppColors.primary,
          ),
          onPressed: _addCustomer,
          icon: const Icon(AppIcons.addUser),
          label: const Text('Add New Customer'),
        ),
      ],
    ),
  );

  List<Widget> _customerContent() {
    final CustomerController controller = widget.customerController;
    if (controller.isLoading) {
      return const <Widget>[SizedBox(height: 180, child: AppLoadingView())];
    }
    if (controller.error != null) {
      return <Widget>[
        AppErrorView(
          message: controller.error!,
          onRetry: () => controller.load(search: _customerSearch.text),
        ),
      ];
    }
    if (controller.customers.isEmpty) {
      return const <Widget>[
        SizedBox(
          height: 180,
          child: AppEmptyState(
            icon: AppIcons.users,
            title: 'No customers found',
            message: 'Try another search or add a customer.',
          ),
        ),
      ];
    }
    return <Widget>[
      ...controller.customers.map(
        (Customer customer) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: FutureBuilder<int>(
            future: widget.customerController.orderCountFor(customer.id),
            builder: (BuildContext context, AsyncSnapshot<int> snapshot) =>
                NewOrderCustomerCard(
                  customer: customer,
                  orderCount: snapshot.data,
                  selected: widget.controller.customer?.id == customer.id,
                  onTap: () => widget.controller.selectCustomer(customer),
                ),
          ),
        ),
      ),
      if (controller.isLoadingMore)
        const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
    ];
  }

  Widget _itemsStep() {
    if (widget.controller.isLoadingCatalog) return const AppLoadingView();
    if (widget.controller.error != null &&
        widget.controller.categories.isEmpty) {
      return AppErrorView(
        message: widget.controller.error!,
        onRetry: widget.controller.loadCatalog,
      );
    }
    if (widget.controller.uniqueItems.isEmpty) {
      return const AppEmptyState(
        icon: AppIcons.package,
        title: 'No item categories available',
        message: 'Configure active item categories for this branch first.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xl,
        AppSpacing.pageHorizontal,
        AppSpacing.pageBottom,
      ),
      children: <Widget>[
        Text('Items', style: AppTextStyles.headingSmall),
        const SizedBox(height: AppSpacing.xl),
        ...widget.controller.uniqueItems.map((OrderItemCategory category) {
          final double amount =
              widget.controller.selectionFor(category.id)?.amount ?? 0;
          final double increment = category.unitType == CatalogUnitType.kg
              ? 0.5
              : 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: NewOrderItemCard(
              category: category,
              prices: widget.controller.pricesFor(category),
              amount: amount,
              onDecrease: amount <= 0
                  ? null
                  : () => widget.controller.changeAmount(
                      category,
                      (amount - increment).clamp(0, double.infinity),
                    ),
              onIncrease: () =>
                  widget.controller.changeAmount(category, amount + increment),
              onEdit: () => _editAmount(category, amount),
            ),
          );
        }),
      ],
    );
  }

  Widget _servicesStep() => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      AppSpacing.xl,
      AppSpacing.pageHorizontal,
      AppSpacing.pageBottom,
    ),
    children: <Widget>[
      Text('Services', style: AppTextStyles.headingSmall),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Choose one or more available services for each selected item.',
        style: AppTextStyles.bodySmall,
      ),
      if (widget.controller.error != null) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        NewOrderErrorBanner(message: widget.controller.error!),
      ],
      const SizedBox(height: AppSpacing.xl),
      ...widget.controller.selections.map(_serviceCard),
      if (widget.controller.isQuoting)
        const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
    ],
  );

  Widget _serviceCard(NewOrderLineSelection line) {
    final List<OrderCatalogService> services = widget.controller.servicesFor(
      line.category,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '${line.category.name} × ${newOrderAmount(line.amount)}',
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
                if (line.quotes.isNotEmpty)
                  Text(
                    formatOrderMoney(
                      line.services.keys.fold<double>(
                        0,
                        (double total, String serviceId) =>
                            total +
                            widget.controller.serviceBaseAmount(
                              line,
                              serviceId,
                            ),
                      ),
                    ),
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (services.isEmpty)
              Text(
                'No active service mapping is available for this item.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              )
            else
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: services
                    .map(
                      (OrderCatalogService service) => FilterChip(
                        showCheckmark: true,
                        selected: line.hasService(service.id),
                        onSelected: widget.controller.isQuoting
                            ? null
                            : (_) async {
                                final bool selected = await widget.controller
                                    .toggleService(line, service);
                                if (!selected) _showError();
                              },
                        label: Text(service.name),
                      ),
                    )
                    .toList(growable: false),
              ),
            if (line.quotes.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              ...line.services.values.map((OrderCatalogService service) {
                final OrderCatalogQuote quote = line.quoteFor(service.id)!;
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '${service.name}: ${quote.pricingType.unitLabel} · '
                    '${formatOrderMoney(widget.controller.serviceUnitPrice(line, service.id))} · '
                    'Tax ${newOrderAmount(quote.taxPercent)}%',
                    style: AppTextStyles.caption,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _pricingStep() => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      AppSpacing.xl,
      AppSpacing.pageHorizontal,
      AppSpacing.pageBottom,
    ),
    children: <Widget>[
      Text('Pricing', style: AppTextStyles.headingSmall),
      const SizedBox(height: AppSpacing.xl),
      ...widget.controller.selections.expand(
        (NewOrderLineSelection line) => line.services.values.map(
          (OrderCatalogService service) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: AppCard(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '${line.category.name} × ${newOrderAmount(line.amount)}',
                          style: AppTextStyles.bodyMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(service.name, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Text(
                    formatOrderMoney(
                      widget.controller.serviceBaseAmount(line, service.id),
                    ),
                    style: AppTextStyles.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      AppTextField(
        controller: _discount,
        label: 'Order discount (%)',
        hintText: 'Enter 0–100',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        child: Column(
          children: <Widget>[
            _priceRow('Items', widget.controller.previewBaseSubtotal),
            _priceRow('Discount', -widget.controller.discountAmount),
            _priceRow('Taxable amount', widget.controller.previewTaxableAmount),
            _priceRow('Tax preview', widget.controller.previewTax),
            const AppDivider(),
            _priceRow(
              'Estimated total',
              widget.controller.previewGrandTotal,
              total: true,
            ),
          ],
        ),
      ),
      if (widget.controller.error != null) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        NewOrderErrorBanner(message: widget.controller.error!),
      ],
    ],
  );

  Widget _priceRow(String label, double value, {bool total = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: total ? AppTextStyles.bodyLarge : AppTextStyles.bodySmall,
          ),
        ),
        Text(
          formatOrderMoney(value),
          style: (total ? AppTextStyles.bodyLarge : AppTextStyles.bodyMedium)
              .copyWith(
                color: value < 0
                    ? AppColors.error
                    : total
                    ? AppColors.primary
                    : null,
              ),
        ),
      ],
    ),
  );

  Widget _paymentStep() => ListView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      AppSpacing.xl,
      AppSpacing.pageHorizontal,
      AppSpacing.pageBottom,
    ),
    children: <Widget>[
      Text('Payment', style: AppTextStyles.headingSmall),
      const SizedBox(height: AppSpacing.md),
      Text(
        'Record an optional advance payment with the order.',
        style: AppTextStyles.bodySmall,
      ),
      const SizedBox(height: AppSpacing.xl),
      AppTextField(
        controller: _advancePayment,
        label: 'Advance Payment (₹)',
        hintText: 'Enter advance amount',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
      ),
      const SizedBox(height: AppSpacing.xl),
      Text('Payment method', style: AppTextStyles.inputLabel),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: PaymentMethod.values
            .map(
              (PaymentMethod method) => ChoiceChip(
                label: Text(method.apiValue),
                selected: widget.controller.paymentMethod == method,
                onSelected: (_) =>
                    widget.controller.selectPaymentMethod(method),
              ),
            )
            .toList(growable: false),
      ),
      const SizedBox(height: AppSpacing.xl),
      AppCard(
        child: Column(
          children: <Widget>[
            _priceRow('Grand Total', widget.controller.previewGrandTotal),
            _priceRow('Advance Paid', widget.controller.advancePayment),
            const AppDivider(),
            _priceRow(
              'Remaining / Outstanding',
              widget.controller.previewOutstanding,
              total: true,
            ),
          ],
        ),
      ),
      if (widget.controller.error != null) ...<Widget>[
        const SizedBox(height: AppSpacing.lg),
        NewOrderErrorBanner(message: widget.controller.error!),
      ],
    ],
  );

  Future<void> _takePhoto() async {
    try {
      final XFile? shot =
          await (widget.takePhoto ??
              () => ImagePicker().pickImage(
                source: ImageSource.camera,
                maxWidth: 1600,
                imageQuality: 70,
              ))();
      if (shot == null) return;
      final Uint8List bytes = await shot.readAsBytes();
      widget.controller.addPhoto(bytes);
    } on Object {
      // Camera unavailable or permission refused: photos are optional.
    }
  }

  String _dayLabel(String yyyyMmDd) {
    final DateTime? day = DateTime.tryParse(yyyyMmDd);
    if (day == null) return yyyyMmDd;
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const List<String> days = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return '${days[day.weekday - 1]}, ${day.day} ${months[day.month - 1]}';
  }

  Future<void> _pickDeliveryDate() async {
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime initial =
        DateTime.tryParse(widget.controller.deliveryDate ?? '') ?? today;
    final DateTime? day = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );
    if (day == null) return;
    widget.controller.setCustomDeliveryDate(
      '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
    );
  }

  /// Salon walk-in: pick from the salon's service menu; staff are assigned automatically when the order is saved.
  Widget _salonServicesStep() {
    final NewOrderController c = widget.controller;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: <Widget>[
        Text('Services', style: AppTextStyles.headingSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Pick what the customer wants. Each service goes to a free person with the right role when you save.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSpacing.md),
        for (final SalonMenuItem item in c.salonMenu)
          CheckboxListTile(
            key: Key('order.salon.${item.serviceId}'),
            contentPadding: EdgeInsets.zero,
            value: c.isSalonChosen(item.serviceId),
            onChanged: (_) => c.toggleSalonItem(item.serviceId),
            title: Text(item.name, style: AppTextStyles.title),
            subtitle: Text(
              '${rupees(item.price)} · ${durationText(item.durationMinutes)} · ${item.role}',
            ),
          ),
      ],
    );
  }

  /// Pickup only: photos of the items, an optional total count and the delivery date.
  Widget _photosStep() {
    final NewOrderController c = widget.controller;
    final List<Uint8List> photos = c.photos;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xl,
        AppSpacing.pageHorizontal,
        AppSpacing.pageBottom,
      ),
      children: <Widget>[
        Text('Photos & delivery', style: AppTextStyles.headingSmall),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Take photos of the items you are collecting. The customer can see them on their order.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: <Widget>[
            for (int i = 0; i < photos.length; i++)
              Stack(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      photos[i],
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: InkWell(
                      key: Key('order.photo.remove.$i'),
                      onTap: () => c.removePhotoAt(i),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            if (photos.length < 6)
              OutlinedButton.icon(
                key: const Key('order.photo.add'),
                onPressed: _takePhoto,
                icon: const Icon(Icons.photo_camera_outlined, size: 18),
                label: const Text('Take photo'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 88)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Up to 6 photos', style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          controller: _totalItems,
          label: 'Total items (optional)',
          hintText: 'e.g. 12',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Delivery date', style: AppTextStyles.inputLabel),
        const SizedBox(height: AppSpacing.xs),
        Text(
          c.deliveryDate == null
              ? '…'
              : c.deliveryIsCustom
              ? _dayLabel(c.deliveryDate!)
              : 'Automatic: ${_dayLabel(c.deliveryDate!)}',
          key: const Key('order.delivery.date'),
          style: AppTextStyles.labelBold,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          children: <Widget>[
            TextButton(
              key: const Key('order.delivery.pick'),
              onPressed: _pickDeliveryDate,
              child: const Text('Pick another date'),
            ),
            if (c.deliveryIsCustom)
              TextButton(
                onPressed: () => c.setCustomDeliveryDate(null),
                child: const Text('Use the automatic date'),
              ),
          ],
        ),
        if (c.error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          NewOrderErrorBanner(message: c.error!),
        ],
      ],
    );
  }

  Widget _receiptStep() {
    final Order? order = widget.controller.createdOrder;
    if (order == null) {
      return const AppErrorView(
        message: 'The saved order response is unavailable.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xl,
        AppSpacing.pageHorizontal,
        AppSpacing.pageBottom,
      ),
      children: <Widget>[
        Text('Receipt', style: AppTextStyles.headingSmall),
        const SizedBox(height: AppSpacing.xl),
        AppCard(
          child: Column(
            children: <Widget>[
              Text(widget.businessName, style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(widget.branchName, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.lg),
              Text(
                compactOrderNumber(order.orderNumber),
                style: AppTextStyles.title.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(order.orderNumber, style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.sm),
              const AppStatusBadge(label: 'Saved', tone: AppBadgeTone.success),
              const SizedBox(height: AppSpacing.xl),
              const AppDivider(),
              _receiptRow('Customer', order.customer.name),
              ...order.items.map(_receiptServiceRow),
              _receiptRow('Date', formatOrderDate(context, order.createdAt)),
              const SizedBox(height: AppSpacing.lg),
              const AppDivider(),
              const SizedBox(height: AppSpacing.lg),
              _receiptRow(
                'Grand total',
                formatOrderMoney(order.grandTotal),
                strong: true,
              ),
              _receiptRow(
                'Paid',
                formatOrderMoney(order.paidAmount),
                strong: true,
                color: AppColors.primary,
              ),
              _receiptRow(
                'Remaining',
                formatOrderMoney(order.outstandingAmount),
                strong: true,
                color: order.outstandingAmount > 0
                    ? AppColors.error
                    : AppColors.success,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: AppSizes.buttonLargeHeight,
                      child: OutlinedButton.icon(
                        onPressed: () => unawaited(_openReceipt(order)),
                        icon: const Icon(AppIcons.print),
                        label: const Text('Print'),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SizedBox(
                      height: AppSizes.buttonLargeHeight,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await copyOrderShareText(order);
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Order summary copied for WhatsApp sharing.',
                                  ),
                                ),
                              );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          backgroundColor: AppColors.successSurface,
                          side: AppBorders.successSide,
                        ),
                        icon: const Icon(AppIcons.share),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _receiptServiceRow(OrderItem item) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            item.measurement.isEmpty
                ? item.itemCategoryName
                : '${item.itemCategoryName} × ${item.measurement}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            item.serviceName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    ),
  );

  Widget _receiptRow(
    String label,
    String value, {
    bool strong = false,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: (strong ? AppTextStyles.bodyLarge : AppTextStyles.bodyMedium)
                .copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}
