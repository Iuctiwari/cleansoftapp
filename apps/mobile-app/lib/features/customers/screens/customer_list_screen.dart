import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_details_screen.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_form_screen.dart';
import 'package:nexoraa_mobile/features/customers/widgets/customer_widgets.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({required this.controller, super.key});
  final CustomerController controller;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _scrollController.addListener(_onScroll);
    unawaited(widget.controller.load());
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

  Future<void> _addCustomer() async {
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CustomerFormScreen(controller: widget.controller),
      ),
    );
    if (created == true) {
      await widget.controller.load(search: _searchController.text);
      if (mounted) _message('Customer created successfully.');
    }
  }

  Future<void> _openCustomer(String id) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CustomerDetailsScreen(
          customerId: id,
          controller: widget.controller,
        ),
      ),
    );
    if (changed == true)
      await widget.controller.load(search: _searchController.text);
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
                child: Text('Customers', style: AppTextStyles.headingSmall),
              ),
              ElevatedButton.icon(
                onPressed: _addCustomer,
                icon: const Icon(AppIcons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                widget.controller.load(search: _searchController.text),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.pageHorizontal,
                  ),
                  sliver: SliverToBoxAdapter(child: _summary()),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.lg,
                    AppSpacing.pageHorizontal,
                    AppSpacing.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _search,
                      decoration: const InputDecoration(
                        hintText: 'Search by name or phone...',
                        prefixIcon: Icon(AppIcons.search),
                      ),
                    ),
                  ),
                ),
                ..._content(),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _summary() => Row(
    children: <Widget>[
      Expanded(
        child: CustomerSummaryCard(
          value: '${widget.controller.total}',
          label: 'Total',
          color: AppColors.primary,
          background: AppColors.primarySurface,
        ),
      ),
      const SizedBox(width: AppGrid.columns3Gap),
      Expanded(
        child: CustomerSummaryCard(
          value: formatMoney(widget.controller.outstanding),
          label: 'Outstanding',
          color: AppColors.error,
          background: AppColors.errorSurface,
        ),
      ),
      const SizedBox(width: AppGrid.columns3Gap),
      Expanded(
        child: CustomerSummaryCard(
          value: '${widget.controller.active}',
          label: 'Active',
          color: AppColors.success,
          background: AppColors.successSurface,
        ),
      ),
    ],
  );

  List<Widget> _content() {
    if (widget.controller.isLoading) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (widget.controller.error != null) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: CustomerEmptyState(
            title: 'Unable to load customers',
            message: widget.controller.error!,
            action: OutlinedButton.icon(
              onPressed: () =>
                  widget.controller.load(search: _searchController.text),
              icon: const Icon(AppIcons.refresh),
              label: const Text('Try again'),
            ),
          ),
        ),
      ];
    }
    if (widget.controller.customers.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: CustomerEmptyState(
            title: _searchController.text.isEmpty
                ? 'No customers yet'
                : 'No customers found',
            message: _searchController.text.isEmpty
                ? 'Create your first customer to get started.'
                : 'Try searching with another name or mobile number.',
          ),
        ),
      ];
    }
    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          0,
          AppSpacing.pageHorizontal,
          AppSpacing.pageBottom,
        ),
        sliver: SliverList.separated(
          itemCount: widget.controller.customers.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: AppSpacing.listGap),
          itemBuilder: (_, int index) {
            final customer = widget.controller.customers[index];
            return CustomerListCard(
              customer: customer,
              onTap: () => _openCustomer(customer.id),
            );
          },
        ),
      ),
      if (widget.controller.isLoadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }
}
