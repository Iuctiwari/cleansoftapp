import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';
import 'package:nexoraa_mobile/features/payments/models/payment.dart';

const Duration _searchDebounce = Duration(milliseconds: 300);
const int _resultLimit = 5;
const int _paymentScanLimit = 20;

/// Debounced, multi-source Dashboard search across Orders, Customers, and
/// Payments. Owns its own branch-scoped API service instances (matching how
/// [CustomerController] owns its own [OrderApiService]) so searching never
/// disturbs the Orders/Customers tabs' own paginated state.
class DashboardSearchController extends ChangeNotifier {
  DashboardSearchController({
    required OrderApiService orderService,
    required CustomerApiService customerService,
    required PaymentApiService paymentService,
  }) : _orderService = orderService,
       _customerService = customerService,
       _paymentService = paymentService;

  final OrderApiService _orderService;
  final CustomerApiService _customerService;
  final PaymentApiService _paymentService;

  Timer? _debounce;
  int _requestId = 0;
  String _query = '';
  bool _isLoading = false;
  List<Order> _orders = const <Order>[];
  List<Customer> _customers = const <Customer>[];
  List<PaymentRecord> _payments = const <PaymentRecord>[];

  String get query => _query;
  bool get isLoading => _isLoading;
  List<Order> get orders => _orders;
  List<Customer> get customers => _customers;
  List<PaymentRecord> get payments => _payments;
  bool get hasResults => _orders.isNotEmpty || _customers.isNotEmpty || _payments.isNotEmpty;

  void selectBranch(String? branchId) {
    _orderService.selectBranch(branchId);
    _customerService.selectBranch(branchId);
    _paymentService.selectBranch(branchId ?? '');
    clear();
  }

  void search(String query) {
    final String trimmed = query.trim();
    _query = trimmed;
    _debounce?.cancel();
    if (trimmed.isEmpty) {
      _isLoading = false;
      _orders = const <Order>[];
      _customers = const <Customer>[];
      _payments = const <PaymentRecord>[];
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    _debounce = Timer(_searchDebounce, () => unawaited(_run(trimmed)));
  }

  void clear() {
    _debounce?.cancel();
    _query = '';
    _isLoading = false;
    _orders = const <Order>[];
    _customers = const <Customer>[];
    _payments = const <PaymentRecord>[];
    notifyListeners();
  }

  Future<void> _run(String query) async {
    final int requestId = ++_requestId;
    List<Order> orders = const <Order>[];
    List<Customer> customers = const <Customer>[];
    List<PaymentRecord> payments = const <PaymentRecord>[];
    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _orderService.list(search: query, limit: _resultLimit),
        _customerService.list(search: query, limit: _resultLimit),
        _paymentService.list(limit: _paymentScanLimit),
      ]);
      orders = (results[0] as OrderPage).items;
      customers = (results[1] as CustomerPage).items;
      final String needle = query.toLowerCase();
      payments = (results[2] as PaymentPage).items
          .where(
            (PaymentRecord payment) =>
                (payment.customerName?.toLowerCase().contains(needle) ?? false) ||
                (payment.orderNumber?.toLowerCase().contains(needle) ?? false) ||
                payment.paymentNumber.toLowerCase().contains(needle),
          )
          .take(_resultLimit)
          .toList(growable: false);
    } on Object {
      // Best-effort search — leave whichever source(s) failed empty rather
      // than surfacing an error for what is a lightweight, incremental UI.
    }
    if (requestId != _requestId) return;
    _orders = orders;
    _customers = customers;
    _payments = payments;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
