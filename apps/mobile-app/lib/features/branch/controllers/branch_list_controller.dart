import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/branch/services/branch_api_service.dart';

enum BranchListStatus { initial, loading, loaded, error }

final class BranchListController extends ChangeNotifier {
  BranchListController({required BranchApiService service}) : _service = service;

  static const int _pageSize = 20;

  final BranchApiService _service;

  BranchListStatus _status = BranchListStatus.initial;
  String? _errorMessage;
  List<Branch> _branches = <Branch>[];
  BranchStatus? _statusFilter;
  int _page = 1;
  int _total = 0;
  bool _isLoadingMore = false;

  BranchListStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<Branch> get branches => _branches;
  BranchStatus? get statusFilter => _statusFilter;
  int get total => _total;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _branches.length < _total;

  Future<void> load({BranchStatus? statusFilter}) async {
    _statusFilter = statusFilter;
    _status = BranchListStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final BranchListResult result = await _service.listBranches(
        status: _statusFilter,
        page: 1,
        pageSize: _pageSize,
      );
      _branches = result.items;
      _page = result.page;
      _total = result.total;
      _status = BranchListStatus.loaded;
    } on BranchApiException catch (error) {
      _status = BranchListStatus.error;
      _errorMessage = error.userMessage;
    } on BranchApiNetworkException catch (error) {
      _status = BranchListStatus.error;
      _errorMessage = error.message;
    } on StateError catch (error) {
      _status = BranchListStatus.error;
      _errorMessage = error.message;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final BranchListResult result = await _service.listBranches(
        status: _statusFilter,
        page: _page + 1,
        pageSize: _pageSize,
      );
      _branches = <Branch>[..._branches, ...result.items];
      _page = result.page;
      _total = result.total;
    } on BranchApiException {
      // Keep the current page; the user can retry via pull-to-refresh.
    } on BranchApiNetworkException {
      // Keep the current page; the user can retry via pull-to-refresh.
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  void replaceBranch(Branch updated) {
    _branches = _branches
        .map((Branch branch) => branch.branchId == updated.branchId ? updated : branch)
        .toList(growable: false);
    notifyListeners();
  }
}
