import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_models.dart';
import 'package:nexoraa_mobile/features/company_admin/models/company_admin_status_tone.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_api_service.dart';
import 'package:nexoraa_mobile/features/company_admin/services/company_admin_dependencies.dart';

String _formatRupees(int paise) => '₹${(paise / 100).toStringAsFixed(2)}';

String _formatDate(String? isoDate) {
  if (isoDate == null) return 'Never';
  final DateTime? parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return 'Never';
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

/// Pushed from the Clients tab (and from "tenants on this plan"). One screen
/// per the plan's requirements: subscription history, payment history,
/// branch/staff counts, and suspend/reactivate/change-plan actions.
class TenantDetailScreen extends StatefulWidget {
  const TenantDetailScreen({required this.tenantId, super.key, this.apiService});

  final String tenantId;
  final CompanyAdminApiService? apiService;

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  late final CompanyAdminApiService _apiService;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;

  TenantOverviewEntryModel? _tenant;
  TenantSubscriptionModel? _subscription;
  List<SubscriptionHistoryModel> _subscriptionHistory = <SubscriptionHistoryModel>[];
  List<BillingAttemptModel> _billingHistory = <BillingAttemptModel>[];
  TenantResourceCountsModel? _resourceCounts;
  List<SubscriptionPlanModel> _plans = <SubscriptionPlanModel>[];

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? CompanyAdminDependencies.apiService;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final TenantOverviewPageModel overview = await _apiService.listTenantsOverview(
        tenantId: widget.tenantId,
      );
      final TenantOverviewEntryModel? tenant = overview.items.isEmpty
          ? null
          : overview.items.first;
      final results = await Future.wait(<Future<Object?>>[
        _apiService.getTenantSubscription(widget.tenantId),
        _apiService.getSubscriptionHistory(widget.tenantId),
        _apiService.getBillingHistory(widget.tenantId),
        _apiService.getResourceCounts(widget.tenantId),
        _apiService.listSubscriptionPlans(),
      ]);
      if (!mounted) return;
      setState(() {
        _tenant = tenant;
        _subscription = results[0] as TenantSubscriptionModel?;
        _subscriptionHistory = results[1] as List<SubscriptionHistoryModel>;
        _billingHistory = results[2] as List<BillingAttemptModel>;
        _resourceCounts = results[3] as TenantResourceCountsModel;
        _plans = results[4] as List<SubscriptionPlanModel>;
        _isLoading = false;
      });
    } on CompanyAdminApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus(String status) async {
    String? reason;
    if (status == 'SUSPENDED') {
      reason = await _promptForReason();
      if (reason == null) return; // cancelled
    }
    setState(() => _isBusy = true);
    try {
      await _apiService.updateSubscriptionStatus(widget.tenantId, status: status, reason: reason);
      await _load();
      _showMessage('Status updated to $status.');
    } on CompanyAdminApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<String?> _promptForReason() async {
    final TextEditingController controller = TextEditingController();
    final String? reason = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
          title: const Text('Suspend Tenant'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Reason (required)'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: controller.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Suspend'),
            ),
          ],
        );
      },
    );
    return reason;
  }

  Future<void> _changePlan() async {
    if (_plans.isEmpty) {
      _showMessage('No subscription plans configured yet.');
      return;
    }
    String selectedPlanKey = _subscription?.planKey ?? _plans.first.planKey;
    String billingCycle = _subscription?.billingCycle ?? 'MONTHLY';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
              title: const Text('Change Plan'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AppDropdownField<String>(
                    label: 'Plan',
                    value: selectedPlanKey,
                    items: _plans
                        .map(
                          (p) => AppDropdownOption<String>(
                            value: p.planKey,
                            label: '${p.displayName} (${p.planKey})',
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (String v) => setDialogState(() => selectedPlanKey = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppDropdownField<String>(
                    label: 'Billing Cycle',
                    value: billingCycle,
                    items: const <AppDropdownOption<String>>[
                      AppDropdownOption<String>(value: 'MONTHLY', label: 'MONTHLY'),
                      AppDropdownOption<String>(value: 'ANNUAL', label: 'ANNUAL'),
                    ],
                    onChanged: (String v) => setDialogState(() => billingCycle = v),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true) return;
    setState(() => _isBusy = true);
    try {
      await _apiService.assignPlan(
        widget.tenantId,
        planKey: selectedPlanKey,
        billingCycle: billingCycle,
      );
      await _load();
      _showMessage('Plan updated.');
    } on CompanyAdminApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _createPaymentOrder() async {
    if (_subscription == null) {
      _showMessage('Assign a plan before billing this tenant.');
      return;
    }
    setState(() => _isBusy = true);
    try {
      final Map<String, dynamic> order = await _apiService.createBillingOrder(
        widget.tenantId,
        billingCycle: _subscription!.billingCycle,
      );
      await _load();
      if (mounted) await _showOrderResult(order);
    } on CompanyAdminApiException catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// A dialog, not a SnackBar — the order ID needs to stay on screen long
  /// enough to actually copy/read it, not disappear after a few seconds.
  Future<void> _showOrderResult(Map<String, dynamic> order) {
    final String orderId = order['razorpayOrderId'] as String? ?? 'unknown';
    final int amountInPaise = (order['amountInPaise'] as num?)?.toInt() ?? 0;
    final String currency = order['currency'] as String? ?? 'INR';
    final String billingCycle = order['billingCycle'] as String? ?? '';
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
          title: const Text('Payment Order Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _OrderResultRow(label: 'Order ID', value: orderId),
              _OrderResultRow(
                label: 'Amount',
                value: '${_formatRupees(amountInPaise)} $currency',
              ),
              _OrderResultRow(label: 'Billing Cycle', value: billingCycle),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Status: Awaiting payment. The tenant subscription updates '
                'automatically once Razorpay confirms the payment via webhook.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tenant?.businessName ?? 'Tenant')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const AppLoadingView();
    if (_error != null) return AppErrorView(message: _error!, onRetry: _load);

    final TenantOverviewEntryModel? tenant = _tenant;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          if (tenant != null)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(tenant.businessName, style: AppTextStyles.headingMedium),
                      ),
                      if (tenant.subscriptionStatus != null)
                        AppStatusBadge(
                          label: tenant.subscriptionStatus!,
                          tone: companyAdminStatusTone(tenant.subscriptionStatus!),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${tenant.ownerName} · ${tenant.ownerEmail}', style: AppTextStyles.bodySmall),
                  Text(
                    tenant.businessType,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  const Divider(height: AppSpacing.xl),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Stat(
                          icon: AppIcons.branch,
                          label: 'Branches',
                          value: '${_resourceCounts?.branchCount ?? '—'}',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          icon: AppIcons.users,
                          label: 'Staff',
                          value: '${_resourceCounts?.staffCount ?? '—'}',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          icon: AppIcons.userVerified,
                          label: 'Customers',
                          value: '${_resourceCounts?.customerCount ?? '—'}',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          icon: AppIcons.wallet,
                          label: 'Plan',
                          value: _subscription?.planKey ?? 'None',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _OrderSummaryCard(summary: _resourceCounts?.orderSummary)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _PaymentSummaryCard(summary: _resourceCounts?.paymentSummary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Actions', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              SecondaryButton(
                label: 'Change Plan',
                onPressed: _isBusy ? null : _changePlan,
              ),
              SecondaryButton(
                label: 'Suspend',
                onPressed: _isBusy || _subscription?.status == 'SUSPENDED'
                    ? null
                    : () => _changeStatus('SUSPENDED'),
              ),
              SecondaryButton(
                label: 'Reactivate',
                onPressed: _isBusy || _subscription?.status == 'ACTIVE'
                    ? null
                    : () => _changeStatus('ACTIVE'),
              ),
              SecondaryButton(
                label: 'Create Payment Order',
                onPressed: _isBusy || _subscription == null ? null : _createPaymentOrder,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: AppCard(
                  onTap: () => context.pushNamed(
                    AppRouteNames.companyAdminTenantModules,
                    pathParameters: <String, String>{'tenantId': widget.tenantId},
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(AppIcons.checklist, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(child: Text('Modules')),
                      const Icon(AppIcons.chevronRight, color: AppColors.textSubtle),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppCard(
                  onTap: () => context.pushNamed(
                    AppRouteNames.companyAdminTenantTheme,
                    pathParameters: <String, String>{'tenantId': widget.tenantId},
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(AppIcons.tag, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      const Expanded(child: Text('Theme')),
                      const Icon(AppIcons.chevronRight, color: AppColors.textSubtle),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Subscription & Payment History', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Every subscription change and payment event, in one timeline.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_subscriptionHistory.isEmpty)
            Text(
              'No history yet.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else
            ..._subscriptionHistory.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SubscriptionHistoryEntryCard(entry: entry),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Payment Transactions', style: AppTextStyles.headingSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Every Razorpay order this tenant's owner was asked to pay, including ones never completed.",
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_billingHistory.isEmpty)
            Text(
              'No payments yet.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            )
          else
            ..._billingHistory.map(
              (attempt) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _formatRupees(attempt.amountInPaise),
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              '${attempt.billingCycle} · ${attempt.createdAt}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSubtle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppStatusBadge(
                        label: attempt.status,
                        tone: attempt.status == 'PAID'
                            ? AppBadgeTone.success
                            : attempt.status == 'FAILED'
                            ? AppBadgeTone.error
                            : AppBadgeTone.neutral,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: AppIconSizes.md, color: AppColors.textSubtle),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.bodyLarge),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle)),
      ],
    );
  }
}

/// order-service's own operational summary for this tenant — a null
/// [summary] means the lookup failed/timed out/order-service is down, shown
/// as "Unavailable" rather than crashing or showing a blank/zero card.
class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.summary});

  final TenantOrderSummaryModel? summary;

  @override
  Widget build(BuildContext context) {
    final TenantOrderSummaryModel? s = summary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.orders, size: AppIconSizes.md, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Orders', style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (s == null)
            Text(
              'Unavailable',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSubtle),
            )
          else ...<Widget>[
            Text('${s.totalOrders} total', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${s.ordersThisMonth} this month',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Last: ${_formatDate(s.lastOrderDate)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_formatRupees(s.outstandingMinor)} outstanding',
              style: AppTextStyles.caption.copyWith(
                color: s.outstandingMinor > 0 ? AppColors.error : AppColors.textSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// payment-service's own operational summary for this tenant — a null
/// [summary] means the lookup failed/timed out/payment-service is down,
/// shown as "Unavailable" rather than crashing or showing a blank/zero card.
/// The true accounts-receivable "outstanding" figure is shown on the Orders
/// card instead (order-service owns that balance) — this card's "pending
/// confirmation" row is just payments recorded but not yet confirmed.
class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.summary});

  final TenantPaymentSummaryModel? summary;

  @override
  Widget build(BuildContext context) {
    final TenantPaymentSummaryModel? s = summary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(AppIcons.payment, size: AppIconSizes.md, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Payments', style: AppTextStyles.headingSmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (s == null)
            Text(
              'Unavailable',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSubtle),
            )
          else ...<Widget>[
            Text(_formatRupees(s.totalRevenueMinor), style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_formatRupees(s.revenueThisMonthMinor)} this month',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${_formatRupees(s.pendingPaymentsMinor)} pending confirmation',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
            ),
          ],
        ],
      ),
    );
  }
}

const Map<String, String> _kHistoryActionLabels = <String, String>{
  'PLAN_ASSIGNED': 'Plan Assigned',
  'PLAN_CHANGED': 'Plan Changed',
  'STATUS_CHANGED': 'Status Changed',
  'EXTENDED': 'Subscription Extended',
  'PAYMENT_SUCCESS': 'Payment Received',
  'PAYMENT_FAILED': 'Payment Failed',
};

/// Renders one SubscriptionHistory entry. PAYMENT_SUCCESS/PAYMENT_FAILED
/// entries (written by BillingWebhookService — see that class's
/// handlePaymentCaptured/handlePaymentFailed) carry real payment detail in
/// `newValue` (amount, Razorpay IDs, failure reason) that earlier only the
/// backend response carried — this surfaces it instead of just the bare
/// action name every other entry type shows.
class _SubscriptionHistoryEntryCard extends StatelessWidget {
  const _SubscriptionHistoryEntryCard({required this.entry});

  final SubscriptionHistoryModel entry;

  @override
  Widget build(BuildContext context) {
    final String label = _kHistoryActionLabels[entry.action] ?? entry.action;
    final Map<String, dynamic>? data = entry.newValue;

    if (entry.action == 'PAYMENT_SUCCESS') {
      final int? amountInPaise = (data?['amountInPaise'] as num?)?.toInt();
      final String? paymentId = data?['razorpayPaymentId'] as String?;
      return AppCard(
        child: Row(
          children: <Widget>[
            const Icon(AppIcons.success, color: AppColors.success),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(entry.timestamp),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                  ),
                  if (paymentId != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(paymentId, style: AppTextStyles.caption),
                  ],
                ],
              ),
            ),
            if (amountInPaise != null)
              Text(
                _formatRupees(amountInPaise),
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success),
              ),
          ],
        ),
      );
    }

    if (entry.action == 'PAYMENT_FAILED') {
      final String? failureReason = data?['failureReason'] as String?;
      return AppCard(
        child: Row(
          children: <Widget>[
            const Icon(AppIcons.alert, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _formatDate(entry.timestamp),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
                  ),
                  if (failureReason != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      failureReason,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatDate(entry.timestamp),
            style: AppTextStyles.caption.copyWith(color: AppColors.textSubtle),
          ),
          if (entry.reason != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(entry.reason!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _OrderResultRow extends StatelessWidget {
  const _OrderResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: SelectableText(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
