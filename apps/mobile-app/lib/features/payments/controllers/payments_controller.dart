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
  bool isCollectingOrder(String orderId) => _collectingOrderIds.contains(orderId);
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
        customerId: _customerId,
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
    if (_collectingOrderIds.contains(order.id)) return false;
    _collectingOrderIds.add(order.id);
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
      _collectingOrderIds.remove(order.id);
      notifyListeners();
    }
  }

  Future<void> _loadHistory() async {
    if (_isLoadingHistory) return;
    _isLoadingHistory = true;
    _historyError = null;
    notifyListeners();
    try {
      final PaymentPage page = await _paymentService.list(
        page: 1,
        customerId: _customerId,
      );
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
    if (_isLoadingOutstanding) return;
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
          customerId: _customerId,
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
    if (_isLoadingSummary) return;
    _isLoadingSummary = true;
    notifyListeners();
    try {
      final Future<(double, double, int)> collectedFuture =
          _computeCollectedSummary();
      final Future<(double, int)> outstandingFuture = _computeOutstandingTotal();
      final Future<(int, int)> billsFuture = _computeBillsCounts();
      final (double today, double yesterday, int todayCount) =
          await collectedFuture;
      _todayCollected = today;
      _yesterdayCollected = yesterday;
      _todayCollectedCount = todayCount;
      final (double outstandingTotal, int outstandingCustomerCount) =
          await outstandingFuture;
      _outstandingTotal = outstandingTotal;
      _outstandingCustomerCount = outstandingCustomerCount;
      final (int totalBills, int paidBills) = await billsFuture;
      _totalBillsCount = totalBills;
      _paidBillsCount = paidBills;
    } on OrderApiException {
      // Summary is best-effort; the History/Outstanding tabs surface real
      // errors directly, so leave the last-known summary values in place.
    } finally {
      _isLoadingSummary = false;
      notifyListeners();
    }
  }

  /// Sums successful payments for today and yesterday from the same
  /// newest-first page scan (no dedicated aggregate endpoint exists on the
  /// Payment Service), so the "today vs yesterday" comparison always reflects
  /// real persisted payment data.
  Future<(double today, double yesterday, int todayCount)>
  _computeCollectedSummary() async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    double todaySum = 0;
    double yesterdaySum = 0;
    int todayCount = 0;
    int page = 1;
    while (page <= _summaryMaxPages) {
      final PaymentPage result = await _paymentService.list(
        page: page,
        limit: _summaryPageLimit,
        status: PaymentTransactionStatus.successful,
        customerId: _customerId,
      );
      bool reachedOlderDay = false;
      for (final PaymentRecord record in result.items) {
        final DateTime local = record.createdAt.toLocal();
        final DateTime day = DateTime(local.year, local.month, local.day);
        if (day.isAtSameMomentAs(today)) {
          todaySum += record.amount;
          todayCount += 1;
        } else if (day.isAtSameMomentAs(yesterday)) {
          yesterdaySum += record.amount;
        } else if (day.isBefore(yesterday)) {
          reachedOlderDay = true;
          break;
        }
      }
      if (reachedOlderDay || page >= result.totalPages) break;
      page += 1;
    }
    return (todaySum, yesterdaySum, todayCount);
  }

  /// Real total and successful ("paid") payment/bill counts for the
  /// selected branch, read from the Payment Service's own pagination
  /// `total` (no dedicated count/aggregate endpoint exists).
  Future<(int total, int paid)> _computeBillsCounts() async {
    final PaymentPage totalPage = await _paymentService.list(
      limit: 1,
      customerId: _customerId,
    );
    final PaymentPage paidPage = await _paymentService.list(
      limit: 1,
      status: PaymentTransactionStatus.successful,
      customerId: _customerId,
    );
    return (totalPage.total, paidPage.total);
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
          customerId: _customerId,
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
