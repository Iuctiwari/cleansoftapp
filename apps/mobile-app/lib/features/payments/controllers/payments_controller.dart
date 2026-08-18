import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';
import 'package:nexoraa_mobile/features/payments/models/payment.dart';

/// Number of pages fetched (per outstanding payment status) when computing
/// the outstanding summary total/customer count and the "today collected"
/// total. Bounds the work done for these aggregates since neither backend
/// exposes a dedicated aggregate endpoint; real branch volumes stay well
/// within this bound.
const int _summaryMaxPages = 5;
const int _summaryPageLimit = 100;

const List<OrderPaymentStatus> _outstandingStatuses = <OrderPaymentStatus>[
  OrderPaymentStatus.unpaid,
  OrderPaymentStatus.partiallyPaid,
];

class PaymentsController extends ChangeNotifier {
  PaymentsController({
    required PaymentApiService paymentService,
    required OrderController orderController,
  }) : _paymentService = paymentService,
       _orderController = orderController;

  final PaymentApiService _paymentService;
  final OrderController _orderController;

  double _todayCollected = 0;
  double _outstandingTotal = 0;
  int _outstandingCustomerCount = 0;
  bool _isLoadingSummary = false;

  final List<PaymentRecord> _history = <PaymentRecord>[];
  int _historyPage = 0;
  bool _historyHasMore = true;
  bool _isLoadingHistory = false;
  bool _isLoadingMoreHistory = false;
  String? _historyError;

  final List<Order> _outstanding = <Order>[];
  int _outstandingPage = 0;
  bool _outstandingHasMore = true;
  bool _isLoadingOutstanding = false;
  bool _isLoadingMoreOutstanding = false;
  String? _outstandingError;

  bool _isCollecting = false;
  String? _collectError;

  double get todayCollected => _todayCollected;
  double get outstandingTotal => _outstandingTotal;
  int get outstandingCustomerCount => _outstandingCustomerCount;
  bool get isLoadingSummary => _isLoadingSummary;

  List<PaymentRecord> get history => List<PaymentRecord>.unmodifiable(_history);
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isLoadingMoreHistory => _isLoadingMoreHistory;
  bool get historyHasMore => _historyHasMore;
  String? get historyError => _historyError;

  List<Order> get outstandingOrders => List<Order>.unmodifiable(_outstanding);
  bool get isLoadingOutstanding => _isLoadingOutstanding;
  bool get isLoadingMoreOutstanding => _isLoadingMoreOutstanding;
  bool get outstandingHasMore => _outstandingHasMore;
  String? get outstandingError => _outstandingError;

  bool get isCollecting => _isCollecting;
  String? get collectError => _collectError;

  Future<void> load() async {
    await Future.wait<void>(<Future<void>>[
      _loadHistory(),
      _loadOutstanding(),
      _loadSummary(),
    ]);
  }

  Future<void> refresh() => load();

  Future<void> loadMoreHistory() async {
    if (!_historyHasMore || _isLoadingHistory || _isLoadingMoreHistory) return;
    _isLoadingMoreHistory = true;
    notifyListeners();
    try {
      final PaymentPage page = await _paymentService.list(
        page: _historyPage + 1,
      );
      _history.addAll(page.items);
      _historyPage = page.page;
      _historyHasMore = page.page < page.totalPages;
      _historyError = null;
    } on OrderApiException catch (error) {
      _historyError = error.message;
    } finally {
      _isLoadingMoreHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreOutstanding() async {
    if (!_outstandingHasMore || _isLoadingOutstanding || _isLoadingMoreOutstanding) {
      return;
    }
    _isLoadingMoreOutstanding = true;
    notifyListeners();
    try {
      final _MergedOrderPage merged = await _fetchOutstandingPage(
        _outstandingPage + 1,
      );
      _outstanding.addAll(merged.items);
      _outstandingPage += 1;
      _outstandingHasMore = merged.hasMore;
      _outstandingError = null;
    } on OrderApiException catch (error) {
      _outstandingError = error.message;
    } finally {
      _isLoadingMoreOutstanding = false;
      notifyListeners();
    }
  }

  Future<bool> collect({
    required Order order,
    required double amount,
    required PaymentMethod method,
  }) async {
    if (_isCollecting) return false;
    _isCollecting = true;
    _collectError = null;
    notifyListeners();
    try {
      await _paymentService.createAdvance(
        idempotencyKey:
            'collect-${order.id}-${DateTime.now().microsecondsSinceEpoch}',
        orderId: order.id,
        customerId: order.customerId,
        amount: amount,
        method: method,
      );
      await Future.wait<void>(<Future<void>>[_loadOutstanding(), _loadSummary()]);
      return true;
    } on OrderApiException catch (error) {
      _collectError = error.message;
      return false;
    } finally {
      _isCollecting = false;
      notifyListeners();
    }
  }

  Future<void> _loadHistory() async {
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();
    try {
      final PaymentPage page = await _paymentService.list(page: 1);
      _history
        ..clear()
        ..addAll(page.items);
      _historyPage = page.page;
      _historyHasMore = page.page < page.totalPages;
    } on OrderApiException catch (error) {
      _historyError = error.message;
      _history.clear();
      _historyHasMore = false;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> _loadOutstanding() async {
    _isLoadingOutstanding = true;
    _outstandingError = null;
    notifyListeners();
    try {
      final _MergedOrderPage merged = await _fetchOutstandingPage(1);
      _outstanding
        ..clear()
        ..addAll(merged.items);
      _outstandingPage = 1;
      _outstandingHasMore = merged.hasMore;
    } on OrderApiException catch (error) {
      _outstandingError = error.message;
      _outstanding.clear();
      _outstandingHasMore = false;
    } finally {
      _isLoadingOutstanding = false;
      notifyListeners();
    }
  }

  Future<_MergedOrderPage> _fetchOutstandingPage(int page, {int limit = 20}) async {
    final List<OrderPage> results = await Future.wait<OrderPage>(
      _outstandingStatuses.map(
        (OrderPaymentStatus status) => _orderController.byPaymentStatus(
          status,
          page: page,
          limit: limit,
        ),
      ),
    );
    final List<Order> merged = results
        .expand((OrderPage result) => result.items)
        .toList(growable: false)
      ..sort((Order a, Order b) => b.createdAt.compareTo(a.createdAt));
    final bool hasMore = results.any((OrderPage result) => page < result.totalPages);
    return _MergedOrderPage(items: merged, hasMore: hasMore);
  }

  Future<void> _loadSummary() async {
    _isLoadingSummary = true;
    notifyListeners();
    try {
      final Future<double> todayCollectedFuture = _computeTodayCollected();
      final Future<(double, int)> outstandingFuture = _computeOutstandingTotal();
      _todayCollected = await todayCollectedFuture;
      final (double outstandingTotal, int outstandingCustomerCount) =
          await outstandingFuture;
      _outstandingTotal = outstandingTotal;
      _outstandingCustomerCount = outstandingCustomerCount;
    } on OrderApiException {
      // Summary is best-effort; the History/Outstanding tabs surface real
      // errors directly, so leave the last-known summary values in place.
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  Future<double> _computeTodayCollected() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    double sum = 0;
    int page = 1;
    while (page <= _summaryMaxPages) {
      final PaymentPage result = await _paymentService.list(
        page: page,
        limit: _summaryPageLimit,
        status: PaymentTransactionStatus.successful,
      );
      bool reachedPreviousDay = false;
      for (final PaymentRecord record in result.items) {
        final DateTime local = record.createdAt.toLocal();
        final DateTime day = DateTime(local.year, local.month, local.day);
        if (day.isBefore(today)) {
          reachedPreviousDay = true;
          break;
        }
        sum += record.amount;
      }
      if (reachedPreviousDay || page >= result.totalPages) break;
      page += 1;
    }
    return sum;
  }

  Future<(double, int)> _computeOutstandingTotal() async {
    double total = 0;
    final Set<String> customerIds = <String>{};
    for (final OrderPaymentStatus status in _outstandingStatuses) {
      int page = 1;
      while (page <= _summaryMaxPages) {
        final OrderPage result = await _orderController.byPaymentStatus(
          status,
          page: page,
          limit: _summaryPageLimit,
        );
        for (final Order order in result.items) {
          total += order.outstandingAmount;
          customerIds.add(order.customerId);
        }
        if (page >= result.totalPages) break;
        page += 1;
      }
    }
    return (total, customerIds.length);
  }
}

class _MergedOrderPage {
  const _MergedOrderPage({required this.items, required this.hasMore});

  final List<Order> items;
  final bool hasMore;
}
