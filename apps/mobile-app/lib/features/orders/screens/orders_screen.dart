import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/screens/order_details_screen.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({required this.controller, this.onNewOrder, super.key});

  final OrderController controller;
  final VoidCallback? onNewOrder;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _scrollController.addListener(_onScroll);
    unawaited(widget.controller.ensureLoaded());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    // Only paginate while the user is actively scrolling toward the bottom
    // (ScrollDirection.reverse = content moving up). Scrolling back toward
    // the top must never trigger a reload — pagination is separate from
    // pull-to-refresh.
    if (_scrollController.position.userScrollDirection !=
        ScrollDirection.reverse) {
      return;
    }
    if (_scrollController.position.extentAfter < 240) {
      unawaited(widget.controller.loadMore());
    }
  }

  void _search(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(widget.controller.load(search: value));
    });
  }

  void _filter(OrderListFilter filter) {
    if (filter == widget.controller.filter) return;
    unawaited(
      widget.controller.load(search: _searchController.text, filter: filter),
    );
  }

  Future<void> _openOrder(Order order) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailsScreen(
          orderId: order.id,
          controller: widget.controller,
        ),
      ),
    );
  }

  Future<void> _reload() => widget.controller.load(
    search: _searchController.text,
    filter: widget.controller.filter,
  );

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.xl,
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text('Orders', style: AppTextStyles.headingSmall),
              ),
              ElevatedButton.icon(
                onPressed: widget.onNewOrder,
                icon: const Icon(AppIcons.add, size: AppIconSizes.md2),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.none,
            AppSpacing.pageHorizontal,
            AppSpacing.mdPlus,
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search orders, customers...',
              prefixIcon: Icon(AppIcons.search),
              suffixIcon: Icon(AppIcons.filter),
            ),
          ),
        ),
        OrderFilterBar(selected: widget.controller.filter, onSelected: _filter),
        const SizedBox(height: AppSpacing.mdPlus),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: CustomScrollView(
              key: const PageStorageKey<String>('orders-list'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: _content(),
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _content() {
    // Only replace the whole list with a spinner on the true first load
    // (nothing to show yet). A refresh (pull-to-refresh, search, or filter
    // change) with existing orders already on screen relies on
    // RefreshIndicator's own spinner as the single loading indicator,
    // instead of stacking a second one on top of it.
    if (widget.controller.isLoading && widget.controller.orders.isEmpty) {
      return const <Widget>[SliverFillRemaining(child: AppLoadingView())];
    }
    if (widget.controller.error != null && widget.controller.orders.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(
            message: widget.controller.error!,
            onRetry: _reload,
          ),
        ),
      ];
    }
    if (widget.controller.orders.isEmpty) {
      final bool filtered =
          _searchController.text.trim().isNotEmpty ||
          widget.controller.filter != OrderListFilter.all;
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: AppIcons.orders,
            title: filtered ? 'No matching orders' : 'No orders yet',
            message: filtered
                ? 'Try a different search or status filter.'
                : 'Saved orders for this branch will appear here.',
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
              widget.controller.orders.length +
              (widget.controller.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSpacing.listGap),
          itemBuilder: (BuildContext context, int index) {
            if (index == widget.controller.orders.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final Order order = widget.controller.orders[index];
            return OrderListCard(order: order, onTap: () => _openOrder(order));
          },
        ),
      ),
    ];
  }
}
