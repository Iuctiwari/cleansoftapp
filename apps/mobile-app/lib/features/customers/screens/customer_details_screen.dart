import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_form_screen.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/customers/widgets/customer_widgets.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/screens/order_details_screen.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';
import 'package:nexoraa_mobile/features/payments/controllers/payments_controller.dart';
import 'package:nexoraa_mobile/features/payments/screens/payments_screen.dart';
import 'package:nexoraa_mobile/features/payments/widgets/payments_widgets.dart';

/// Page size used to load the customer's complete order history. Summary
/// values are supplied by the server-side order statistics aggregate.
const int _customerOrdersPageLimit = 50;

class _CustomerOrdersSummary {
  const _CustomerOrdersSummary({
    required this.orders,
    required this.totalCount,
    required this.outstandingBalance,
  });

  final List<Order> orders;
  final int totalCount;
  final double outstandingBalance;
}

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({
    required this.customerId,
    required this.controller,
    this.accessPolicy = const AccessPolicy(roleCode: 'Owner'),
    super.key,
  });
  final String customerId;
  final CustomerController controller;
  final AccessPolicy accessPolicy;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  AccessPolicy get _accessPolicy => widget.accessPolicy;
  Customer? _customer;
  String? _error;
  bool _loading = true;
  bool _deleting = false;
  bool _changed = false;

  OrderController? _orderController;
  Future<_CustomerOrdersSummary>? _ordersFuture;
  bool _isCollectingOutstanding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _orderController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Customer customer = await widget.controller.details(
        widget.customerId,
      );
      if (mounted) {
        setState(() {
          _customer = customer;
          _orderController ??= OrderController(
            service: widget.controller.orderService
              ..selectBranch(customer.branchId),
          );
          _ordersFuture = _loadCustomerOrders(customer.id);
        });
      }
    } on CustomerApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_CustomerOrdersSummary> _loadCustomerOrders(String customerId) async {
    final OrderController orderController = _orderController!;
    final List<Order> orders = <Order>[];
    final Future<OrderStatistics> statisticsFuture = orderController.statistics(
      customerId: customerId,
    );
    int page = 1;
    int totalPages = 1;
    while (page <= totalPages) {
      final OrderPage result = await orderController.byCustomer(
        customerId,
        page: page,
        limit: _customerOrdersPageLimit,
      );
      orders.addAll(result.items);
      totalPages = result.totalPages;
      page += 1;
    }
    final OrderStatistics statistics = await statisticsFuture;
    return _CustomerOrdersSummary(
      orders: orders,
      totalCount: statistics.totalOrders,
      outstandingBalance: statistics.outstandingTotal,
    );
  }

  /// Opens the SAME collect dialog and payment flow used by
  /// Payments → Outstanding (`showCollectPaymentDialog` +
  /// `PaymentsController.collect`), scoped to this customer's largest
  /// outstanding order, then refreshes the profile from the backend.
  Future<void> _collectOutstanding(
    Customer customer,
    _CustomerOrdersSummary summary,
  ) async {
    if (_isCollectingOutstanding) return;
    final List<Order> outstandingOrders =
        summary.orders
            .where((Order order) => order.outstandingAmount > 0)
            .toList()
          ..sort(
            (Order a, Order b) =>
                b.outstandingAmount.compareTo(a.outstandingAmount),
          );
    if (outstandingOrders.isEmpty) {
      _message('No outstanding orders to collect from.');
      return;
    }
    final Order candidate = outstandingOrders.first;
    // Re-fetch the order right before opening the dialog: the customer
    // profile's order list is loaded once per screen visit and can go stale
    // (e.g. the same order was already partially collected elsewhere), which
    // previously caused the dialog to allow an amount the backend would then
    // reject as exceeding the order's *current* outstanding balance.
    final Order target;
    try {
      target = await _orderController!.details(candidate.id);
    } on OrderApiException catch (error) {
      _message(error.message);
      return;
    }
    if (target.outstandingAmount <= 0) {
      _message('This order has already been fully paid.');
      await _load();
      return;
    }
    final ({double amount, PaymentMethod method})? result =
        await showCollectPaymentDialog(context, order: target);
    if (result == null) return;

    setState(() => _isCollectingOutstanding = true);
    final OrderController scopedOrderController = OrderController(
      service: widget.controller.orderService..selectBranch(customer.branchId),
    );
    final PaymentApiService paymentApiService = PaymentApiService(
      tokenStorage: AuthenticationDependencies.tokenStorage,
    )..selectBranch(customer.branchId);
    final PaymentsController paymentsController = PaymentsController(
      paymentService: paymentApiService,
      orderController: scopedOrderController,
    );
    try {
      final bool success = await paymentsController.collect(
        order: target,
        amount: result.amount,
        method: result.method,
      );
      if (!mounted) return;
      if (success) {
        _message('Payment collected.');
        _changed = true;
        await _load();
      } else {
        _message(
          paymentsController.collectError ?? 'Unable to collect payment.',
        );
      }
    } finally {
      paymentsController.dispose();
      scopedOrderController.dispose();
      if (mounted) setState(() => _isCollectingOutstanding = false);
    }
  }

  Future<void> _openPaymentHistory() async {
    final Customer? customer = _customer;
    if (customer == null) return;
    final OrderController scopedOrderController = OrderController(
      service: widget.controller.orderService..selectBranch(customer.branchId),
    );
    final PaymentApiService paymentApiService = PaymentApiService(
      tokenStorage: AuthenticationDependencies.tokenStorage,
    )..selectBranch(customer.branchId);
    final PaymentsController controller = PaymentsController(
      paymentService: paymentApiService,
      orderController: scopedOrderController,
      customerId: customer.id,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentsScreen(
          controller: controller,
          title: '${customer.name} · Payments',
        ),
      ),
    );
    controller.dispose();
    scopedOrderController.dispose();
  }

  Future<void> _openOrder(Order order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsScreen(
          orderId: order.id,
          controller: _orderController!,
        ),
      ),
    );
  }

  Future<void> _edit() async {
    final Customer? customer = _customer;
    if (customer == null) return;
    final bool? updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CustomerFormScreen(
          controller: widget.controller,
          customer: customer,
        ),
      ),
    );
    if (updated == true) {
      _changed = true;
      await _load();
      if (mounted) _message('Customer updated successfully.');
    }
  }

  Future<void> _delete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete customer?'),
        content: const Text('Are you sure you want to delete this customer?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await widget.controller.delete(widget.customerId);
      if (mounted) Navigator.of(context).pop(true);
    } on CustomerApiException catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _message(String value) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(value)));
  }

  void _comingSoon(String feature) => _message('$feature is coming soon.');

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => Navigator.pop(context, _changed),
        icon: const Icon(AppIcons.arrowBack),
      ),
      title: const Text('Customer Profile'),
      actions: <Widget>[
        if (_accessPolicy.allows(AppCapability.customersEdit))
          IconButton(
            onPressed: _customer == null ? null : _edit,
            icon: const Icon(AppIcons.edit),
          ),
        if (_accessPolicy.allows(AppCapability.customersDelete))
          PopupMenuButton<String>(
            enabled: _customer != null && !_deleting,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.buttonRadius,
            ),
            onSelected: (String value) {
              if (value == 'delete') _delete();
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'delete',
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(AppIcons.delete, color: AppColors.error),
                    SizedBox(width: AppSpacing.mdPlus),
                    Text(
                      'Delete customer',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
    body: _body(),
    bottomNavigationBar:
        _customer == null || !_accessPolicy.allows(AppCapability.paymentsView)
        ? null
        : _paymentHistoryBar(),
  );

  /// Pinned footer for "View Payment History" so it stays reachable while
  /// the rest of the profile scrolls, instead of being the last item of the
  /// scrolling `ListView` in [_body].
  Widget _paymentHistoryBar() => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      border: AppBorders.bottomNavigation,
      boxShadow: AppShadows.subtle,
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHorizontal,
          vertical: AppSpacing.lg,
        ),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openPaymentHistory,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              backgroundColor: AppColors.primarySurface,
              side: const BorderSide(color: AppColors.primaryBorder),
              minimumSize: const Size(0, AppSizes.touchTarget),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
            ),
            icon: const Icon(AppIcons.payment, size: AppIconSizes.md),
            label: const Text('View Payment History'),
          ),
        ),
      ),
    ),
  );

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return CustomerEmptyState(
        title: 'Unable to load customer',
        message: _error!,
        action: OutlinedButton.icon(
          onPressed: _load,
          icon: const Icon(AppIcons.refresh),
          label: const Text('Try again'),
        ),
      );
    }
    final Customer customer = _customer!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: <Widget>[
        CustomerSurfaceCard(
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      customerInitials(customer.name),
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(customer.name, style: AppTextStyles.subtitle),
                        Text(
                          'Customer since ${formatDate(customer.joiningDate)}',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.sm,
                          children: <Widget>[
                            OutlinedButton.icon(
                              onPressed: customer.mobile == null
                                  ? null
                                  : () => _comingSoon('Calling'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                backgroundColor: AppColors.primarySurface,
                                side: const BorderSide(
                                  color: AppColors.primaryBorder,
                                ),
                                minimumSize: const Size(
                                  0,
                                  AppSizes.controlMediumLarge,
                                ),
                                padding: AppSpacing.buttonSmallInsets,
                              ),
                              icon: const Icon(AppIcons.phone, size: 16),
                              label: const Text('Call'),
                            ),
                            OutlinedButton.icon(
                              onPressed: customer.mobile == null
                                  ? null
                                  : () => _comingSoon('WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.successDarker,
                                backgroundColor: AppColors.successSurface,
                                side: const BorderSide(
                                  color: AppColors.successBorder,
                                ),
                                minimumSize: const Size(
                                  0,
                                  AppSizes.controlMediumLarge,
                                ),
                                padding: AppSpacing.buttonSmallInsets,
                              ),
                              icon: const Icon(AppIcons.message, size: 16),
                              label: const Text('WhatsApp'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: AppSpacing.section),
              _detail(
                'Phone',
                customer.mobile == null
                    ? 'Not provided'
                    : formatIndianPhone(customer.mobile!),
              ),
              _detail('Address', customer.address ?? 'Not provided'),
              _detail('Email', customer.email ?? 'Not provided'),
              _detail('Type', customer.customerType.apiValue),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FutureBuilder<_CustomerOrdersSummary>(
          future: _ordersFuture,
          builder: (context, snapshot) => _ordersSection(customer, snapshot),
        ),
      ],
    );
  }

  Widget _ordersSection(
    Customer customer,
    AsyncSnapshot<_CustomerOrdersSummary> snapshot,
  ) {
    final _CustomerOrdersSummary? summary = snapshot.data;
    final String ordersValue = summary == null ? '…' : '${summary.totalCount}';
    final String dueValue = summary == null
        ? '…'
        : formatMoney(summary.outstandingBalance);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: CustomerSummaryCard(
                value: ordersValue,
                label: 'Orders',
                color: AppColors.primary,
                background: AppColors.primarySurface,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CustomerSummaryCard(
                value: formatMoney(customer.totalSpent),
                label: 'Spent',
                color: AppColors.secondary,
                background: AppColors.secondarySurface,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CustomerSummaryCard(
                value: dueValue,
                label: 'Due',
                color: AppColors.error,
                background: AppColors.errorSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: AppSpacing.cardInsets,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: AppBorders.errorCard,
            borderRadius: AppRadius.cardRadius,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Outstanding Balance',
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                    Text(dueValue, style: AppTextStyles.headingMedium),
                  ],
                ),
              ),
              // Hide the button once the balance is cleared — there is
              // nothing left to collect for this customer.
              if (_accessPolicy.allows(AppCapability.paymentsRecord) &&
                  ((summary != null && summary.outstandingBalance > 0) ||
                      _isCollectingOutstanding))
                ElevatedButton(
                  onPressed: summary == null || _isCollectingOutstanding
                      ? null
                      : () => _collectOutstanding(customer, summary),
                  child: _isCollectingOutstanding
                      ? const SizedBox(
                          width: AppIconSizes.sm,
                          height: AppIconSizes.sm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : const Text('Collect'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Order History', style: AppTextStyles.subtitle),
        const SizedBox(height: AppSpacing.md),
        _orderHistoryContent(snapshot),
      ],
    );
  }

  Widget _orderHistoryContent(AsyncSnapshot<_CustomerOrdersSummary> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.hasError) {
      return CustomerEmptyState(
        title: 'Unable to load orders',
        message: 'Something went wrong while loading order history.',
        action: OutlinedButton.icon(
          onPressed: () {
            final Customer? customer = _customer;
            if (customer == null) return;
            setState(() => _ordersFuture = _loadCustomerOrders(customer.id));
          },
          icon: const Icon(AppIcons.refresh),
          label: const Text('Try again'),
        ),
      );
    }
    final List<Order> orders = snapshot.data?.orders ?? const <Order>[];
    if (orders.isEmpty) {
      return const CustomerEmptyState(
        title: 'No orders yet',
        message: 'Orders placed by this customer will appear here.',
      );
    }
    return Column(
      children: <Widget>[
        for (final Order order in orders) ...<Widget>[
          OrderListCard(order: order, onTap: () => _openOrder(order)),
          const SizedBox(height: AppSpacing.listGap),
        ],
      ],
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(width: 76, child: Text(label, style: AppTextStyles.caption)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}
