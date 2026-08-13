import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_form_screen.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/customers/widgets/customer_widgets.dart';

class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({
    required this.customerId,
    required this.controller,
    super.key,
  });
  final String customerId;
  final CustomerController controller;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  Customer? _customer;
  String? _error;
  bool _loading = true;
  bool _deleting = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
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
      if (mounted) setState(() => _customer = customer);
    } on CustomerApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        IconButton(
          onPressed: _customer == null ? null : _edit,
          icon: const Icon(AppIcons.edit),
        ),
        PopupMenuButton<String>(
          enabled: _customer != null && !_deleting,
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
        Row(
          children: <Widget>[
            Expanded(
              child: CustomerSummaryCard(
                value: '${customer.totalOrders}',
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
                value: formatMoney(customer.outstandingBalance),
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
                    Text(
                      formatMoney(customer.outstandingBalance),
                      style: AppTextStyles.headingMedium,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _comingSoon('Collect payment'),
                child: const Text('Collect'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Order History', style: AppTextStyles.subtitle),
        const CustomerEmptyState(
          title: 'Order history coming soon',
          message:
              'Orders will appear here when Order Management is available.',
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _comingSoon('Payment history'),
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
