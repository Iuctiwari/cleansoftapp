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

enum DashboardStatus { ready, processing, pending, completed, overdue }

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
    required this.name,
    required this.ordersLabel,
    required this.revenueLabel,
    required this.progress,
  });

  final String name;
  final String ordersLabel;
  final double progress;
  final String revenueLabel;
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
  final List<DashboardQuickAction> quickActions;
  final String revenue;
  final String revenueChange;
  final String revenueComparison;
  final List<DashboardRevenuePoint> revenuePoints;
  final List<DashboardMetric> summaryMetrics;
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
