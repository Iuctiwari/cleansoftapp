import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_models.dart';

void main() {
  test(
    'branch performance follows dropdown creation order and puts a new branch last',
    () {
      const List<String> dropdownBranchIds = <String>[
        'branch-oldest',
        'branch-middle',
        'branch-new',
      ];
      const List<DashboardBranchPerformance> reportOrder =
          <DashboardBranchPerformance>[
            DashboardBranchPerformance(
              branchId: 'branch-middle',
              name: 'Alpha Branch',
              ordersLabel: '9 orders',
              revenueLabel: 'Rs. 900',
              progress: 0.6,
            ),
            DashboardBranchPerformance(
              branchId: 'branch-new',
              name: 'Newest Branch',
              ordersLabel: '5 orders',
              revenueLabel: 'Rs. 500',
              progress: 0.33,
            ),
            DashboardBranchPerformance(
              branchId: 'branch-oldest',
              name: 'Zulu Branch',
              ordersLabel: '1 order',
              revenueLabel: 'Rs. 100',
              progress: 0.07,
            ),
          ];

      final List<String> cardOrder = alignBranchPerformanceToBranchOrder(
        branchIds: dropdownBranchIds,
        performances: reportOrder,
      ).map((performance) => performance.branchId).toList(growable: false);

      expect(cardOrder, dropdownBranchIds);
      expect(cardOrder.last, 'branch-new');
    },
  );
}
