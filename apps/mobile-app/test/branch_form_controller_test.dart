import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/features/branch/branch_models.dart';
import 'package:nexoraa_mobile/features/branch/controllers/branch_form_controller.dart';
import 'package:nexoraa_mobile/features/branch/services/branch_api_service.dart';

void main() {
  group('UpdateBranchInput manager patch', () {
    test('omits managerId when it is unchanged', () {
      final Map<String, dynamic> json = const UpdateBranchInput(
        branchName: 'Main Branch',
        managerId: 'manager-1',
      ).toJson();

      expect(json, isNot(contains('managerId')));
    });

    test('includes managerId when it changes', () {
      final Map<String, dynamic> json = const UpdateBranchInput(
        managerId: 'manager-2',
        managerIdChanged: true,
      ).toJson();

      expect(json['managerId'], 'manager-2');
    });

    test('includes null managerId when it is removed', () {
      final Map<String, dynamic> json = const UpdateBranchInput(
        managerIdChanged: true,
      ).toJson();

      expect(json, containsPair('managerId', null));
    });
  });

  test(
    'controller resets submitting state after an unexpected error',
    () async {
      final BranchFormController controller = BranchFormController(
        service: _ThrowingBranchApiService(),
      );

      final Branch? result = await controller.update(
        'branch-1',
        const UpdateBranchInput(branchName: 'Updated Branch'),
      );

      expect(result, isNull);
      expect(controller.isSubmitting, isFalse);
      expect(
        controller.errorMessage,
        'Unable to save branch. Please try again.',
      );
      controller.dispose();
    },
  );
}

final class _ThrowingBranchApiService extends BranchApiService {
  _ThrowingBranchApiService() : super(baseUrl: 'http://branch.test');

  @override
  Future<Branch> updateBranch(String branchId, UpdateBranchInput input) {
    throw UnsupportedError('serialization failed');
  }
}
