enum DashboardMetricType {
  orders,
  payments,
  expenses,
  outstanding,
  ready,
  delayed,
  bills,
  customers,
  deliveries,
}

enum DashboardStatus {
  ready,
  processing,
  pending,
  completed,
  overdue,
  cancelled,
}

enum DashboardQuickActionType { newOrder, payment, report, assign }

enum DashboardActivityType { order, payment, customer, delivery, bill }

class DashboardMetric {
  const DashboardMetric({
    required this.type,
    required this.label,
    required this.value,
    required this.supportingText,
  });

  final String label;
  final String supportingText;
  final DashboardMetricType type;
  final String value;
}

class DashboardOrder {
  const DashboardOrder({
    required this.customerName,
    required this.orderNumber,
    required this.description,
    required this.amount,
    required this.timeLabel,
    required this.status,
  });

  final String amount;
  final String customerName;
  final String description;
  final String orderNumber;
  final DashboardStatus status;
  final String timeLabel;

  String get initials => _initials(customerName);
}

class DashboardBill {
  const DashboardBill({
    required this.customerName,
    required this.billNumber,
    required this.amount,
    required this.dueLabel,
    required this.status,
  });

  final String amount;
  final String billNumber;
  final String customerName;
  final String dueLabel;
  final DashboardStatus status;
}

class DashboardCustomer {
  const DashboardCustomer({
    required this.name,
    required this.phone,
    required this.ordersLabel,
    required this.totalSpent,
  });

  final String name;
  final String ordersLabel;
  final String phone;
  final String totalSpent;

  String get initials => _initials(name);
}

class DashboardActivity {
  const DashboardActivity({
    required this.type,
    required this.title,
    required this.description,
    required this.timeLabel,
  });

  final String description;
  final String timeLabel;
  final String title;
  final DashboardActivityType type;
}

class DashboardQuickAction {
  const DashboardQuickAction({required this.type, required this.label});

  final String label;
  final DashboardQuickActionType type;
}

class DashboardRevenuePoint {
  const DashboardRevenuePoint({required this.label, required this.value});

  final String label;
  final double value;
}

class DashboardBranchPerformance {
  const DashboardBranchPerformance({
    required this.branchId,
    required this.name,
    required this.ordersLabel,
    required this.revenueLabel,
    required this.progress,
    this.branchCode,
  });

  final String? branchCode;
  final String branchId;
  final String name;
  final String ordersLabel;
  final double progress;
  final String revenueLabel;
}

List<DashboardBranchPerformance> alignBranchPerformanceToBranchOrder({
  required Iterable<String> branchIds,
  required Iterable<DashboardBranchPerformance> performances,
}) {
  final Map<String, DashboardBranchPerformance> performanceByBranchId = {
    for (final DashboardBranchPerformance performance in performances)
      performance.branchId: performance,
  };
  final List<DashboardBranchPerformance> orderedPerformances =
      <DashboardBranchPerformance>[];
  for (final String branchId in branchIds) {
    final DashboardBranchPerformance? performance = performanceByBranchId
        .remove(branchId);
    if (performance != null) orderedPerformances.add(performance);
  }
  // A transient API mismatch must not hide otherwise valid report data.
  orderedPerformances.addAll(performanceByBranchId.values);
  return List<DashboardBranchPerformance>.unmodifiable(orderedPerformances);
}

class DashboardBranchSummary {
  const DashboardBranchSummary({
    required this.manager,
    required this.teamSize,
    required this.openOrders,
    required this.completedToday,
  });

  final String completedToday;
  final String manager;
  final String openOrders;
  final String teamSize;
}

class DashboardData {
  const DashboardData({
    required this.branchId,
    required this.branchName,
    required this.ownerName,
    this.ownerEmail = 'Unavailable',
    required this.businessName,
    required this.revenue,
    required this.revenueChange,
    required this.revenueComparison,
    required this.kpis,
    required this.summaryMetrics,
    required this.orders,
    required this.bills,
    required this.customers,
    required this.activities,
    required this.quickActions,
    required this.revenuePoints,
    required this.branchPerformance,
    required this.branchSummary,
  });

  final List<DashboardActivity> activities;
  final List<DashboardBill> bills;
  final String branchId;
  final String branchName;
  final List<DashboardBranchPerformance> branchPerformance;
  final DashboardBranchSummary branchSummary;
  final String businessName;
  final List<DashboardCustomer> customers;
  final List<DashboardMetric> kpis;
  final List<DashboardOrder> orders;
  final String ownerName;
  final String ownerEmail;
  final List<DashboardQuickAction> quickActions;
  final String revenue;
  final String revenueChange;
  final String revenueComparison;
  final List<DashboardRevenuePoint> revenuePoints;
  final List<DashboardMetric> summaryMetrics;

  DashboardData copyWith({
    String? revenue,
    String? revenueChange,
    String? revenueComparison,
    List<DashboardMetric>? kpis,
    List<DashboardMetric>? summaryMetrics,
    List<DashboardOrder>? orders,
    List<DashboardBill>? bills,
    List<DashboardBranchPerformance>? branchPerformance,
    List<DashboardRevenuePoint>? revenuePoints,
  }) => DashboardData(
    branchId: branchId,
    branchName: branchName,
    ownerName: ownerName,
    ownerEmail: ownerEmail,
    businessName: businessName,
    revenue: revenue ?? this.revenue,
    revenueChange: revenueChange ?? this.revenueChange,
    revenueComparison: revenueComparison ?? this.revenueComparison,
    kpis: kpis ?? this.kpis,
    summaryMetrics: summaryMetrics ?? this.summaryMetrics,
    orders: orders ?? this.orders,
    bills: bills ?? this.bills,
    customers: customers,
    activities: activities,
    quickActions: quickActions,
    revenuePoints: revenuePoints ?? this.revenuePoints,
    branchPerformance: branchPerformance ?? this.branchPerformance,
    branchSummary: branchSummary,
  );

  factory DashboardData.empty({
    required String branchId,
    required String branchName,
    required String ownerName,
    required String ownerEmail,
    required String businessName,
  }) {
    const zeroKpis = <DashboardMetric>[
      DashboardMetric(
        type: DashboardMetricType.orders,
        label: "Today's Orders",
        value: '—',
        supportingText: 'Unavailable',
      ),
      DashboardMetric(
        type: DashboardMetricType.payments,
        label: 'Payments',
        value: '—',
        supportingText: 'Unavailable',
      ),
      DashboardMetric(
        type: DashboardMetricType.expenses,
        label: 'Expenses',
        value: '—',
        supportingText: 'Unavailable',
      ),
      DashboardMetric(
        type: DashboardMetricType.outstanding,
        label: 'Outstanding',
        value: '—',
        supportingText: 'Unavailable',
      ),
      DashboardMetric(
        type: DashboardMetricType.ready,
        label: 'Ready Orders',
        value: '—',
        supportingText: 'Unavailable',
      ),
      DashboardMetric(
        type: DashboardMetricType.delayed,
        label: 'Delayed Orders',
        value: '—',
        supportingText: 'Unavailable',
      ),
    ];
    const summary = <DashboardMetric>[
      DashboardMetric(
        type: DashboardMetricType.bills,
        label: 'Bills',
        value: '—',
        supportingText: 'Unavailable',
      ),
      DashboardMetric(
        type: DashboardMetricType.customers,
        label: 'Customers',
        value: '—',
        supportingText: 'Unavailable',
      ),
      DashboardMetric(
        type: DashboardMetricType.deliveries,
        label: 'Deliveries',
        value: '—',
        supportingText: 'Unavailable',
      ),
    ];
    const actions = <DashboardQuickAction>[
      DashboardQuickAction(
        type: DashboardQuickActionType.newOrder,
        label: 'New Order',
      ),
      DashboardQuickAction(
        type: DashboardQuickActionType.payment,
        label: 'Payments',
      ),
      DashboardQuickAction(
        type: DashboardQuickActionType.report,
        label: 'Reports',
      ),
      DashboardQuickAction(
        type: DashboardQuickActionType.assign,
        label: 'Assign',
      ),
    ];
    return DashboardData(
      branchId: branchId,
      branchName: branchName,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      businessName: businessName,
      revenue: '—',
      revenueChange: '—',
      revenueComparison: 'Unavailable',
      kpis: zeroKpis,
      summaryMetrics: summary,
      orders: const <DashboardOrder>[],
      bills: const <DashboardBill>[],
      customers: const <DashboardCustomer>[],
      activities: const <DashboardActivity>[],
      quickActions: actions,
      revenuePoints: const <DashboardRevenuePoint>[],
      branchPerformance: const <DashboardBranchPerformance>[],
      branchSummary: const DashboardBranchSummary(
        manager: 'Unavailable',
        teamSize: 'Unavailable',
        openOrders: 'Unavailable',
        completedToday: 'Unavailable',
      ),
    );
  }
}

String _initials(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .take(2)
      .map((String part) => part[0].toUpperCase())
      .join();
}
