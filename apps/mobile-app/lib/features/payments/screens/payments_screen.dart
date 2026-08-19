import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/payments/controllers/payments_controller.dart';
import 'package:nexoraa_mobile/features/payments/widgets/payments_widgets.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({
    required this.controller,
    this.title = 'Payments',
    super.key,
  });

  final PaymentsController controller;
  final String title;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final ScrollController _scrollController = ScrollController();
  PaymentsTab _tab = PaymentsTab.history;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _scrollController.addListener(_onScroll);
    unawaited(widget.controller.load());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    // Only paginate while the user is actively scrolling toward the bottom
    // (ScrollDirection.reverse = content moving up). Scrolling back toward
    // the top, or programmatic scroll-metric changes with no active drag,
    // must never trigger a reload.
    if (_scrollController.position.userScrollDirection !=
        ScrollDirection.reverse) {
      return;
    }
    if (_scrollController.position.extentAfter > 240) return;
    if (_tab == PaymentsTab.history) {
      unawaited(widget.controller.loadMoreHistory());
    } else {
      unawaited(widget.controller.loadMoreOutstanding());
    }
  }

  void _selectTab(PaymentsTab tab) => setState(() => _tab = tab);

  Future<void> _reload() => widget.controller.refresh();

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _collect(Order order) async {
    final ({double amount, PaymentMethod method})? result =
        await showCollectPaymentDialog(context, order: order);
    if (result == null) return;
    final bool success = await widget.controller.collect(
      order: order,
      amount: result.amount,
      method: result.method,
    );
    if (success) {
      _message('Payment collected.');
    } else {
      _message(widget.controller.collectError ?? 'Unable to collect payment.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      bottom: false,
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
              AppSpacing.pageHorizontal,
              AppSpacing.lg,
            ),
            child: PaymentsSummaryCards(
              todayCollected: widget.controller.todayCollected,
              todayVsYesterdayPercentChange:
                  widget.controller.todayVsYesterdayPercentChange,
              outstandingTotal: widget.controller.outstandingTotal,
              outstandingCustomerCount:
                  widget.controller.outstandingCustomerCount,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.none,
              AppSpacing.pageHorizontal,
              AppSpacing.mdPlus,
            ),
            child: PaymentsTabBar(selected: _tab, onSelected: _selectTab),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child: CustomScrollView(
                key: PageStorageKey<String>('payments-${_tab.name}'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: _tab == PaymentsTab.history
                    ? _historyContent()
                    : _outstandingContent(),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _historyContent() {
    final PaymentsController controller = widget.controller;
    // Only replace the whole list with a spinner on the true first load
    // (nothing to show yet). A refresh relies on RefreshIndicator's own
    // spinner as the single loading indicator.
    if (controller.isLoadingHistory && controller.history.isEmpty) {
      return const <Widget>[SliverFillRemaining(child: AppLoadingView())];
    }
    if (controller.historyError != null && controller.history.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(
            message: controller.historyError!,
            onRetry: _reload,
          ),
        ),
      ];
    }
    if (controller.history.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: AppIcons.payment,
            title: 'No payments yet',
            message: 'Payments recorded for this branch will appear here.',
          ),
        ),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.none,
          AppSpacing.pageHorizontal,
          AppSpacing.pageBottom,
        ),
        sliver: SliverList.separated(
          itemCount:
              controller.history.length +
              (controller.isLoadingMoreHistory ? 1 : 0),
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.listGap),
          itemBuilder: (BuildContext context, int index) {
            if (index == controller.history.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return PaymentHistoryCard(payment: controller.history[index]);
          },
        ),
      ),
    ];
  }

  List<Widget> _outstandingContent() {
    final PaymentsController controller = widget.controller;
    // Only replace the whole list with a spinner on the true first load
    // (nothing to show yet). A refresh relies on RefreshIndicator's own
    // spinner as the single loading indicator.
    if (controller.isLoadingOutstanding && controller.outstandingOrders.isEmpty) {
      return const <Widget>[SliverFillRemaining(child: AppLoadingView())];
    }
    if (controller.outstandingError != null &&
        controller.outstandingOrders.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(
            message: controller.outstandingError!,
            onRetry: _reload,
          ),
        ),
      ];
    }
    if (controller.outstandingOrders.isEmpty) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: AppIcons.success,
            title: 'No outstanding balances',
            message: 'Orders with an unpaid balance will appear here.',
          ),
        ),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.none,
          AppSpacing.pageHorizontal,
          AppSpacing.pageBottom,
        ),
        sliver: SliverList.separated(
          itemCount:
              controller.outstandingOrders.length +
              (controller.isLoadingMoreOutstanding ? 1 : 0),
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.listGap),
          itemBuilder: (BuildContext context, int index) {
            if (index == controller.outstandingOrders.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final Order order = controller.outstandingOrders[index];
            final bool collectingThisOrder = controller.isCollectingOrder(
              order.id,
            );
            return OutstandingOrderCard(
              order: order,
              isCollecting: collectingThisOrder,
              onCollect: collectingThisOrder ? null : () => _collect(order),
            );
          },
        ),
      ),
    ];
  }
}
