import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';

/// Number of pages fetched (at [_customerOutstandingPageLimit] orders each)
/// when summing a customer's real outstanding balance from their orders.
/// Bounds the work done since neither backend exposes a dedicated
/// per-customer aggregate endpoint; real customers stay well within this
/// bound.
const int _customerOutstandingMaxPages = 5;
const int _customerOutstandingPageLimit = 50;

class CustomerController extends ChangeNotifier {
  CustomerController({required CustomerApiService service, OrderApiService? orderService})
    : _service = service,
      _orderService =
          orderService ??
          OrderApiService(tokenStorage: AuthenticationDependencies.tokenStorage);

  final CustomerApiService _service;
  final OrderApiService _orderService;

  /// The Orders API instance backing [orderCountFor], kept branch-scoped in
  /// [selectBranch]. Exposed so the Customer Profile screen can reuse it for
  /// its order-history/outstanding-balance sections instead of standing up a
  /// second, independently-configured instance.
  OrderApiService get orderService => _orderService;
  final Map<String, Future<int>> _orderCounts = <String, Future<int>>{};
  final Map<String, Future<double>> _outstandingBalances = <String, Future<double>>{};
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
    _orderCounts.clear();
    _outstandingBalances.clear();
    notifyListeners();
    try {
      final CustomerPage result = await _service.list(page: 1, search: search);
      final CustomerStatistics statistics = await _service.statistics();
      final double outstanding = await _computeTotalOutstanding();
      _customers
        ..clear()
        ..addAll(result.items);
      _listTotal = result.total;
      _total = statistics.total;
      _active = statistics.active;
      _outstanding = outstanding;
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

  /// Real branch-wide outstanding total summed from unpaid/partially-paid
  /// orders via the Orders API. The customer-service `/statistics` aggregate
  /// sums the per-customer `outstandingBalance` field, which is never kept
  /// in sync by the backend and always reports 0 — so it can't be trusted.
  /// Mirrors the same computation `PaymentsController` already uses for the
  /// Payments screen's Outstanding card.
  Future<double> _computeTotalOutstanding() async {
    const List<OrderPaymentStatus> statuses = <OrderPaymentStatus>[
      OrderPaymentStatus.unpaid,
      OrderPaymentStatus.partiallyPaid,
    ];
    double total = 0;
    try {
      for (final OrderPaymentStatus status in statuses) {
        int page = 1;
        while (page <= _customerOutstandingMaxPages) {
          final OrderPage result = await _orderService.list(
            paymentStatus: status,
            page: page,
            limit: _customerOutstandingPageLimit,
          );
          for (final Order order in result.items) {
            total += order.outstandingAmount;
          }
          if (page >= result.totalPages) break;
          page += 1;
        }
      }
    } on OrderApiException {
      return 0;
    }
    return total;
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

  /// Returns the customer's real order count fetched from the Orders API,
  /// since the customer record's own `totalOrders` field is never kept in
  /// sync by the backend. Cached per customer for the lifetime of this
  /// controller (cleared on [load]) so scrolling the list doesn't refetch.
  Future<int> orderCountFor(String customerId) => _orderCounts.putIfAbsent(
    customerId,
    () async {
      try {
        final OrderPage page = await _orderService.list(
          customerId: customerId,
          limit: 1,
        );
        return page.total;
      } on OrderApiException {
        return 0;
      }
    },
  );

  /// Returns the customer's real total outstanding balance summed from
  /// their orders via the Orders API, since the customer record's own
  /// `outstandingBalance` field is never kept in sync by the backend.
  /// Cached per customer for the lifetime of this controller (cleared on
  /// [load]) so scrolling the list doesn't refetch.
  Future<double> outstandingBalanceFor(String customerId) =>
      _outstandingBalances.putIfAbsent(customerId, () async {
        try {
          double total = 0;
          int page = 1;
          while (page <= _customerOutstandingMaxPages) {
            final OrderPage result = await _orderService.list(
              customerId: customerId,
              page: page,
              limit: _customerOutstandingPageLimit,
            );
            for (final Order order in result.items) {
              total += order.outstandingAmount;
            }
            if (page >= result.totalPages) break;
            page += 1;
          }
          return total;
        } on OrderApiException {
          return 0;
        }
      });

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
