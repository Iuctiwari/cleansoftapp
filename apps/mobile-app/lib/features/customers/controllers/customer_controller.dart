import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';

class CustomerController extends ChangeNotifier {
  CustomerController({
    required CustomerApiService service,
    OrderApiService? orderService,
  }) : _service = service,
       _orderService =
           orderService ??
           OrderApiService(
             tokenStorage: AuthenticationDependencies.tokenStorage,
           );

  final CustomerApiService _service;
  final OrderApiService _orderService;

  /// The Orders API instance backing [orderCountFor], kept branch-scoped in
  /// [selectBranch]. Exposed so the Customer Profile screen can reuse it for
  /// its order-history/outstanding-balance sections instead of standing up a
  /// second, independently-configured instance.
  OrderApiService get orderService => _orderService;
  final Map<String, Future<OrderStatistics>> _orderStatistics =
      <String, Future<OrderStatistics>>{};
  final List<Customer> _customers = <Customer>[];
  int _page = 1;
  int _total = 0;
  int _listTotal = 0;
  int _active = 0;
  double _outstanding = 0;
  String _search = '';
  String? _error;
  bool _loading = false;
  bool _loadingMore = false;

  List<Customer> get customers => List<Customer>.unmodifiable(_customers);
  int get total => _total;
  int get active => _active;
  double get outstanding => _outstanding;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _customers.length < _listTotal;
  String? get error => _error;

  Future<void> selectBranch(String branchId) async {
    _service.selectBranch(branchId);
    _orderService.selectBranch(branchId);
    await load(search: _search);
  }

  Future<void> load({String search = ''}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _search = search;
    _page = 1;
    _orderStatistics.clear();
    notifyListeners();
    try {
      final CustomerPage result = await _service.list(page: 1, search: search);
      final CustomerStatistics statistics = await _service.statistics();
      _customers
        ..clear()
        ..addAll(result.items);
      _listTotal = result.total;
      _total = statistics.total;
      _active = statistics.active;
      _outstanding = statistics.outstanding;
    } on CustomerApiException catch (error) {
      _error = error.message;
      _customers.clear();
      _total = 0;
      _listTotal = 0;
      _active = 0;
      _outstanding = 0;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || _loading || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final CustomerPage result = await _service.list(
        page: _page + 1,
        search: _search,
      );
      _page = result.page;
      _listTotal = result.total;
      _customers.addAll(result.items);
    } on CustomerApiException catch (error) {
      _error = error.message;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<Customer> create(CustomerDraft draft) => _service.create(draft);
  Future<Customer> update(String id, CustomerDraft draft) async {
    final Customer updated = await _service.update(id, draft);
    final int index = _customers.indexWhere((Customer item) => item.id == id);
    if (index >= 0) {
      _customers[index] = updated;
      notifyListeners();
    }
    return updated;
  }

  Future<Customer> details(String id) => _service.getById(id);

  /// Returns the customer's server-aggregated order count. The aggregate is
  /// cached per customer so count and outstanding widgets share one request.
  Future<int> orderCountFor(String customerId) async =>
      (await _statisticsFor(customerId)).totalOrders;

  /// Returns the customer's server-aggregated outstanding balance.
  Future<double> outstandingBalanceFor(String customerId) async =>
      (await _statisticsFor(customerId)).outstandingTotal;

  Future<OrderStatistics> _statisticsFor(String customerId) =>
      _orderStatistics.putIfAbsent(
        customerId,
        () => _orderService.statistics(customerId: customerId),
      );

  Future<void> delete(String id) async {
    final Customer? removed = _customers.cast<Customer?>().firstWhere(
      (Customer? item) => item?.id == id,
      orElse: () => null,
    );
    await _service.delete(id);
    _customers.removeWhere((Customer item) => item.id == id);
    if (_total > 0) _total -= 1;
    if (_listTotal > 0) _listTotal -= 1;
    if (_active > 0) _active -= 1;
    if (removed != null) {
      _outstanding = (_outstanding - removed.outstandingBalance).clamp(
        0,
        double.infinity,
      );
    }
    notifyListeners();
  }
}
