import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/branch/services/branch_api_service.dart';

final class BranchFormController extends ChangeNotifier {
  BranchFormController({required BranchApiService service})
    : _service = service;

  final BranchApiService _service;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<Branch?> create(CreateBranchInput input) async {
    return _submit(() => _service.createBranch(input));
  }

  Future<Branch?> update(String branchId, UpdateBranchInput input) async {
    return _submit(() => _service.updateBranch(branchId, input));
  }

  Future<Branch?> _submit(Future<Branch> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Branch branch = await action();
      _isSubmitting = false;
      notifyListeners();
      return branch;
    } on BranchApiException catch (error) {
      _errorMessage = error.userMessage;
    } on BranchApiNetworkException catch (error) {
      _errorMessage = error.message;
    } on StateError catch (error) {
      _errorMessage = error.message;
    }

    _isSubmitting = false;
    notifyListeners();
    return null;
  }
}
