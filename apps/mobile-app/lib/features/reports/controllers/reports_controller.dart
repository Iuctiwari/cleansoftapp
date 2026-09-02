import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/reports/models/report_data.dart';
import 'package:nexoraa_mobile/features/reports/services/report_data_source.dart';

class ReportsController extends ChangeNotifier {
  ReportsController({required ReportDataSource dataSource})
    : _dataSource = dataSource;

  final ReportDataSource _dataSource;
  ExpenseReport? _expenses;
  String? _errorMessage;
  bool _isDisposed = false;
  bool _isEmpty = false;
  bool _isLoading = false;
  int _loadGeneration = 0;
  OrderReport? _orders;
  PaymentReport? _payments;
  ReportPeriod _period = ReportPeriod.sevenDays;
  ReportQuery _query = const ReportQuery.period(ReportPeriod.sevenDays);
  ReportSummary? _summary;
  String? _branchId;

  String? get errorMessage => _errorMessage;
  ExpenseReport? get expenses => _expenses;
  bool get isEmpty => _isEmpty;
  bool get isLoading => _isLoading;
  OrderReport? get orders => _orders;
  PaymentReport? get payments => _payments;
  ReportPeriod get period => _period;
  ReportQuery get query => _query;
  ReportSummary? get summary => _summary;

  Future<void> selectBranch(String? branchId, {bool reload = true}) async {
    final String value = branchId?.trim() ?? '';
    final String? selected = value.isEmpty || value == 'unavailable'
        ? null
        : value;
    if (_branchId == selected) return;
    _branchId = selected;
    _dataSource.selectBranch(selected);
    _clearReports();
    if (reload) await load();
  }

  Future<void> load([ReportPeriod? period]) async {
    if (period != null) {
      _period = period;
      _query = ReportQuery.period(period);
    }
    await _loadQuery(_query);
  }

  Future<void> loadCustomRange(DateTime startDate, DateTime endDate) async {
    if (startDate.isAfter(endDate)) {
      _clearReports();
      _errorMessage = 'Start date must not be after end date.';
      _notify();
      return;
    }
    _query = ReportQuery.custom(startDate: startDate, endDate: endDate);
    await _loadQuery(_query);
  }

  Future<void> _loadQuery(ReportQuery query) async {
    final int generation = ++_loadGeneration;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        _dataSource.loadSummary(query),
        _dataSource.loadOrders(query),
        _dataSource.loadPayments(query),
        _dataSource.loadExpenses(query),
      ]);
      if (generation != _loadGeneration || _isDisposed) return;
      _summary = results[0] as ReportSummary;
      _orders = results[1] as OrderReport;
      _payments = results[2] as PaymentReport;
      _expenses = results[3] as ExpenseReport;
      _isEmpty =
          _summary!.isEmpty &&
          _orders!.metrics.totalOrders == 0 &&
          _payments!.metrics.paymentCount == 0 &&
          _expenses!.metrics.expenseCount == 0;
    } on Object {
      if (generation != _loadGeneration || _isDisposed) return;
      _clearReports(invalidateRequest: false);
      _errorMessage = 'Unable to load reports.';
    } finally {
      if (generation == _loadGeneration && !_isDisposed) {
        _isLoading = false;
        _notify();
      }
    }
  }

  void _clearReports({bool invalidateRequest = true}) {
    if (invalidateRequest) _loadGeneration++;
    _summary = null;
    _orders = null;
    _payments = null;
    _expenses = null;
    _isEmpty = false;
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _loadGeneration++;
    super.dispose();
  }
}
