import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';
import 'package:nexoraa_mobile/features/payments/models/payment.dart';

const List<OrderPaymentStatus> _outstandingStatuses = <OrderPaymentStatus>[
  OrderPaymentStatus.unpaid,
  OrderPaymentStatus.partiallyPaid,
];

class PaymentsController extends ChangeNotifier {
  PaymentsController({
    required PaymentApiService paymentService,
    required OrderController orderController,
    String? customerId,
  }) : _paymentService = paymentService,
       _orderController = orderController,
       _customerId = customerId;

  final PaymentApiService _paymentService;
  final OrderController _orderController;
  final String? _customerId;

  double _todayCollected = 0;
  double _yesterdayCollected = 0;
  int _todayCollectedCount = 0;
  double _outstandingTotal = 0;
  int _outstandingCustomerCount = 0;
  int _totalBillsCount = 0;
  int _paidBillsCount = 0;
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

  final Set<String> _collectingOrderIds = <String>{};
  String? _collectError;
  bool _disposed = false;

  double get todayCollected => _todayCollected;
  double get yesterdayCollected => _yesterdayCollected;

  /// Count of successful payments collected today, from the same real
  /// payment-list scan backing [todayCollected].
  int get todayCollectedCount => _todayCollectedCount;

  /// Real percentage change of today's collected total versus yesterday's,
  /// computed from persisted payment data. Null when yesterday had no
  /// collected payments, since a percentage against a zero baseline would be
  /// undefined/misleading rather than a real comparison.
  double? get todayVsYesterdayPercentChange => _yesterdayCollected == 0
      ? null
      : ((_todayCollected - _yesterdayCollected) / _yesterdayCollected) * 100;

  double get outstandingTotal => _outstandingTotal;
  int get outstandingCustomerCount => _outstandingCustomerCount;

  /// Real total count of payment/bill records for the selected branch, from
  /// the Payment Service's own pagination total (no dedicated count/
  /// aggregate endpoint exists).
  int get totalBillsCount => _totalBillsCount;

  /// Real count of successful ("paid") payment/bill records, from the same
  /// source as [totalBillsCount].
  int get paidBillsCount => _paidBillsCount;
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

  /// Whether a collect request is in flight for [orderId] specifically, so
  /// only that order's Collect button reflects the pending state instead of
  /// disabling every outstanding order's button at once.
  bool isCollectingOrder(String orderId) =>
      _collectingOrderIds.contains(orderId);
  String? get collectError => _collectError;

  bool get _isActive => !_disposed;

  void _notifyIfActive() {
    if (_isActive) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    if (!_isActive) return;
    await Future.wait<void>(<Future<void>>[
      _loadHistory(),
      _loadOutstanding(),
      _loadSummary(),
    ]);
  }

  Future<void> refresh() => load();

  Future<void> loadMoreHistory() async {
    if (!_isActive) return;
    if (!_historyHasMore || _isLoadingHistory || _isLoadingMoreHistory) return;
    _isLoadingMoreHistory = true;
    _notifyIfActive();
    try {
      final PaymentPage page = await _paymentService.list(
        page: _historyPage + 1,
        customerId: _customerId,
      );
      if (!_isActive) return;
      _history.addAll(page.items);
      _historyPage = page.page;
      _historyHasMore = page.page < page.totalPages;
      _historyError = null;
    } on OrderApiException catch (error) {
      if (!_isActive) return;
      _historyError = error.message;
    } finally {
      if (!_isActive) return;
      _isLoadingMoreHistory = false;
      _notifyIfActive();
    }
  }

  Future<void> loadMoreOutstanding() async {
    if (!_isActive) return;
    if (!_outstandingHasMore ||
        _isLoadingOutstanding ||
        _isLoadingMoreOutstanding) {
      return;
    }
    _isLoadingMoreOutstanding = true;
    _notifyIfActive();
    try {
      final _MergedOrderPage merged = await _fetchOutstandingPage(
        _outstandingPage + 1,
      );
      if (!_isActive) return;
      _outstanding.addAll(merged.items);
      _outstandingPage += 1;
      _outstandingHasMore = merged.hasMore;
      _outstandingError = null;
    } on OrderApiException catch (error) {
      if (!_isActive) return;
      _outstandingError = error.message;
    } finally {
      if (!_isActive) return;
      _isLoadingMoreOutstanding = false;
      _notifyIfActive();
    }
  }

  Future<bool> collect({
    required Order order,
    required double amount,
    required PaymentMethod method,
  }) async {
    if (!_isActive) return false;
    if (_collectingOrderIds.contains(order.id)) return false;
    _collectingOrderIds.add(order.id);
    _collectError = null;
    _notifyIfActive();
    try {
      await _paymentService.createAdvance(
        idempotencyKey:
            'collect-${order.id}-${DateTime.now().microsecondsSinceEpoch}',
        orderId: order.id,
        customerId: order.customerId,
        amount: amount,
        method: method,
      );
      if (!_isActive) return false;
      await Future.wait<void>(<Future<void>>[
        _loadOutstanding(),
        _loadSummary(),
      ]);
      if (!_isActive) return false;
      return true;
    } on OrderApiException catch (error) {
      if (!_isActive) return false;
      _collectError = error.message;
      return false;
    } finally {
      if (_isActive) {
        _collectingOrderIds.remove(order.id);
        _notifyIfActive();
      }
    }
  }

  Future<void> _loadHistory() async {
    if (!_isActive) return;
    if (_isLoadingHistory) return;
    _isLoadingHistory = true;
    _historyError = null;
    _notifyIfActive();
    try {
      final PaymentPage page = await _paymentService.list(
        page: 1,
        customerId: _customerId,
      );
      if (!_isActive) return;
      _history
        ..clear()
        ..addAll(page.items);
      _historyPage = page.page;
      _historyHasMore = page.page < page.totalPages;
    } on OrderApiException catch (error) {
      if (!_isActive) return;
      _historyError = error.message;
      _history.clear();
      _historyHasMore = false;
    } finally {
      if (!_isActive) return;
      _isLoadingHistory = false;
      _notifyIfActive();
    }
  }

  Future<void> _loadOutstanding() async {
    if (!_isActive) return;
    if (_isLoadingOutstanding) return;
    _isLoadingOutstanding = true;
    _outstandingError = null;
    _notifyIfActive();
    try {
      final _MergedOrderPage merged = await _fetchOutstandingPage(1);
      if (!_isActive) return;
      _outstanding
        ..clear()
        ..addAll(merged.items);
      _outstandingPage = 1;
      _outstandingHasMore = merged.hasMore;
    } on OrderApiException catch (error) {
      if (!_isActive) return;
      _outstandingError = error.message;
      _outstanding.clear();
      _outstandingHasMore = false;
    } finally {
      if (!_isActive) return;
      _isLoadingOutstanding = false;
      _notifyIfActive();
    }
  }

  Future<_MergedOrderPage> _fetchOutstandingPage(
    int page, {
    int limit = 20,
  }) async {
    final List<OrderPage> results = await Future.wait<OrderPage>(
      _outstandingStatuses.map(
        (OrderPaymentStatus status) => _orderController.byPaymentStatus(
          status,
          page: page,
          limit: limit,
          customerId: _customerId,
        ),
      ),
    );
    final List<Order> merged =
        results
            .expand((OrderPage result) => result.items)
            .toList(growable: false)
          ..sort((Order a, Order b) => b.createdAt.compareTo(a.createdAt));
    final bool hasMore = results.any(
      (OrderPage result) => page < result.totalPages,
    );
    return _MergedOrderPage(items: merged, hasMore: hasMore);
  }

  Future<void> _loadSummary() async {
    if (!_isActive) return;
    if (_isLoadingSummary) return;
    _isLoadingSummary = true;
    _notifyIfActive();
    try {
      final Future<PaymentStatistics> paymentStatisticsFuture = _paymentService
          .statistics(customerId: _customerId);
      final Future<OrderStatistics> outstandingFuture = _orderController
          .statistics(customerId: _customerId);
      final List<Object> summaries = await Future.wait<Object>(<Future<Object>>[
        paymentStatisticsFuture,
        outstandingFuture,
      ]);
      final PaymentStatistics paymentStatistics =
          summaries[0] as PaymentStatistics;
      if (!_isActive) return;
      _todayCollected = paymentStatistics.todayCollected;
      _yesterdayCollected = paymentStatistics.yesterdayCollected;
      _todayCollectedCount = paymentStatistics.todayCollectedCount;
      _totalBillsCount = paymentStatistics.totalBills;
      _paidBillsCount = paymentStatistics.successfulBills;
      final OrderStatistics orderStatistics = summaries[1] as OrderStatistics;
      if (!_isActive) return;
      _outstandingTotal = orderStatistics.outstandingTotal;
      _outstandingCustomerCount = orderStatistics.outstandingCustomerCount;
    } on OrderApiException {
      // Summary is best-effort; the History/Outstanding tabs surface real
      // errors directly, so leave the last-known summary values in place.
    } finally {
      if (!_isActive) return;
      _isLoadingSummary = false;
      _notifyIfActive();
    }
  }
}

class _MergedOrderPage {
  const _MergedOrderPage({required this.items, required this.hasMore});

  final List<Order> items;
  final bool hasMore;
}
