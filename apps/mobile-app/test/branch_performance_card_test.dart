import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_models.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_widgets.dart';

void main() {
  testWidgets(
    'branch performance card matches real metric labels and revenue share',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: BranchPerformanceCard(
              performance: DashboardBranchPerformance(
                branchCode: 'MAIN',
                branchId: 'branch-a',
                name: 'Main Branch',
                ordersLabel: '18 orders',
                progress: 0.72,
                revenueLabel: 'Rs. 13,200',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Main Branch'), findsOneWidget);
      expect(find.text('18 orders · Rs. 13,200'), findsOneWidget);
      expect(find.text('72% of total revenue'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.72,
      );
    },
  );
}
