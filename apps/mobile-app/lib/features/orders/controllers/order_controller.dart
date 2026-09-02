import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';

class OrderController extends ChangeNotifier {
  OrderController({required OrderApiService service}) : _service = service;

  final OrderApiService _service;
  final List<Order> _orders = <Order>[];
  int _page = 1;
  int _total = 0;
  int _totalPages = 0;
  String _search = '';
  OrderListFilter _filter = OrderListFilter.all;
  String? _error;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasLoaded = false;

  List<Order> get orders => List<Order>.unmodifiable(_orders);
  int get total => _total;
  OrderListFilter get filter => _filter;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _page < _totalPages;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  Future<void> selectBranch(String branchId) async {
    _service.selectBranch(branchId);
    await load(search: _search, filter: _filter);
  }

  Future<void> ensureLoaded() async {
    if (!_hasLoaded && !_loading) await load();
  }

  Future<void> load({String? search, OrderListFilter? filter}) async {
    if (_loading) return;
    _search = search ?? _search;
    _filter = filter ?? _filter;
    _loading = true;
    _error = null;
    _page = 1;
    notifyListeners();
    try {
      final OrderPage result = await _service.list(
        search: _search,
        status: _filter.status,
      );
      _orders
        ..clear()
        ..addAll(result.items);
      _page = result.page;
      _total = result.total;
      _totalPages = result.totalPages;
      _hasLoaded = true;
    } on OrderApiException catch (error) {
      _error = error.message;
      _orders.clear();
      _total = 0;
      _totalPages = 0;
      _hasLoaded = true;
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
      final OrderPage result = await _service.list(
        page: _page + 1,
        search: _search,
        status: _filter.status,
      );
      _orders.addAll(result.items);
      _page = result.page;
      _total = result.total;
      _totalPages = result.totalPages;
      _error = null;
    } on OrderApiException catch (error) {
      _error = error.message;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<Order> details(String id) => _service.getById(id);

  Future<List<OrderStatusHistory>> history(String id) =>
      _service.getHistory(id);

  /// Fetches the most recent orders for the selected branch directly from
  /// the backend (newest first), without touching the paginated [orders]
  /// list used by the full Orders screen.
  Future<List<Order>> recent({int limit = 3}) async {
    final OrderPage page = await _service.list(limit: limit);
    return page.items;
  }

  /// Fetches orders with a given payment status directly from the backend,
  /// without touching the paginated [orders] list used by the full Orders
  /// screen. Used to derive outstanding-balance orders since no dedicated
  /// outstanding-balance API exists.
  Future<OrderPage> byPaymentStatus(
    OrderPaymentStatus paymentStatus, {
    int page = 1,
    int limit = OrderApiService.defaultPageSize,
    String? customerId,
  }) => _service.list(
    page: page,
    limit: limit,
    paymentStatus: paymentStatus,
    customerId: customerId,
  );

  /// Fetches orders belonging to a single customer directly from the
  /// backend, without touching the paginated [orders] list used by the full
  /// Orders screen. Used by the Customer Profile screen's order history and
  /// outstanding-balance sections, since customer-service does not keep
  /// per-customer order counts/balances in sync.
  Future<OrderPage> byCustomer(
    String customerId, {
    int page = 1,
    int limit = OrderApiService.defaultPageSize,
  }) => _service.list(page: page, limit: limit, customerId: customerId);

  Future<OrderStatistics> statistics({String? customerId}) =>
      _service.statistics(customerId: customerId);

  Future<Order> changeStatus(
    String id,
    OrderStatus status, {
    String? note,
  }) async {
    final Order order = await _service.changeStatus(id, status, note: note);
    final int index = _orders.indexWhere((Order item) => item.id == order.id);
    if (index >= 0) {
      _orders.removeAt(index);
      _orders.insert(0, order);
    }
    notifyListeners();
    return order;
  }

  Future<Order> assignWorker(
    String id,
    String staffId, {
    DateTime? dueDate,
    String? note,
  }) async {
    final Order order = await _service.assignWorker(
      id,
      staffId,
      dueDate: dueDate,
      note: note,
    );
    final int index = _orders.indexWhere((Order item) => item.id == order.id);
    if (index >= 0) {
      _orders.removeAt(index);
      _orders.insert(0, order);
    }
    notifyListeners();
    return order;
  }

  Future<Order> acceptAssignment(String id) async {
    final Order order = await _service.acceptAssignment(id);
    final int index = _orders.indexWhere((Order item) => item.id == order.id);
    if (index >= 0) _orders[index] = order;
    notifyListeners();
    return order;
  }

  Future<Order> rejectAssignment(String id, {String? reason}) async {
    final Order order = await _service.rejectAssignment(id, reason: reason);
    final int index = _orders.indexWhere((Order item) => item.id == order.id);
    if (index >= 0) _orders[index] = order;
    notifyListeners();
    return order;
  }

  Future<Order> create(CreateOrderInput input) async {
    final Order order = await _service.create(input);
    _orders.removeWhere((Order item) => item.id == order.id);
    _orders.insert(0, order);
    _total += 1;
    _hasLoaded = true;
    notifyListeners();
    return order;
  }
}
