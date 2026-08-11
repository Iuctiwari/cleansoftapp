import 'package:nexoraa_mobile/features/dashboard/dashboard_models.dart';

abstract final class DashboardDummyData {
  static const String defaultBranchId = 'main';

  static const Map<String, DashboardData> branches = <String, DashboardData>{
    'main': DashboardData(
      branchId: 'main',
      branchName: 'Main Branch',
      ownerName: 'User',
      businessName: 'Nexoraa Laundry & Cleaners',
      revenue: 'Rs. 18,450',
      revenueChange: '+12.5%',
      revenueComparison: 'vs yesterday',
      kpis: <DashboardMetric>[
        DashboardMetric(
          type: DashboardMetricType.orders,
          label: "Today's Orders",
          value: '24',
          supportingText: '+3 from yesterday',
        ),
        DashboardMetric(
          type: DashboardMetricType.payments,
          label: 'Payments',
          value: 'Rs. 14.2K',
          supportingText: '6 collected',
        ),
        DashboardMetric(
          type: DashboardMetricType.expenses,
          label: 'Expenses',
          value: 'Rs. 4,500',
          supportingText: '3 entries today',
        ),
        DashboardMetric(
          type: DashboardMetricType.outstanding,
          label: 'Outstanding',
          value: 'Rs. 2,300',
          supportingText: '3 customers',
        ),
        DashboardMetric(
          type: DashboardMetricType.ready,
          label: 'Ready Orders',
          value: '8',
          supportingText: 'Awaiting pickup',
        ),
        DashboardMetric(
          type: DashboardMetricType.delayed,
          label: 'Delayed Orders',
          value: '2',
          supportingText: 'Needs attention',
        ),
      ],
      summaryMetrics: <DashboardMetric>[
        DashboardMetric(
          type: DashboardMetricType.bills,
          label: 'Bills',
          value: '17',
          supportingText: '14 paid',
        ),
        DashboardMetric(
          type: DashboardMetricType.customers,
          label: 'Customers',
          value: '38',
          supportingText: '5 new today',
        ),
        DashboardMetric(
          type: DashboardMetricType.deliveries,
          label: 'Deliveries',
          value: '11',
          supportingText: '7 completed',
        ),
      ],
      orders: <DashboardOrder>[
        DashboardOrder(
          customerName: 'Hassan Ali',
          orderNumber: 'ORD-1042',
          description: '3 shirts, 2 pants',
          amount: 'Rs. 850',
          timeLabel: '10 min ago',
          status: DashboardStatus.ready,
        ),
        DashboardOrder(
          customerName: 'Fatima Malik',
          orderNumber: 'ORD-1041',
          description: 'Carpet cleaning',
          amount: 'Rs. 2,200',
          timeLabel: '45 min ago',
          status: DashboardStatus.processing,
        ),
        DashboardOrder(
          customerName: 'Bilal Raza',
          orderNumber: 'ORD-1040',
          description: '5 dry-clean items',
          amount: 'Rs. 1,400',
          timeLabel: '2 hrs ago',
          status: DashboardStatus.pending,
        ),
      ],
      bills: <DashboardBill>[
        DashboardBill(
          customerName: 'Hassan Ali',
          billNumber: 'BILL-884',
          amount: 'Rs. 850',
          dueLabel: 'Paid today',
          status: DashboardStatus.completed,
        ),
        DashboardBill(
          customerName: 'Ayesha Noor',
          billNumber: 'BILL-881',
          amount: 'Rs. 1,650',
          dueLabel: 'Due tomorrow',
          status: DashboardStatus.pending,
        ),
      ],
      customers: <DashboardCustomer>[
        DashboardCustomer(
          name: 'Meera Kapoor',
          phone: '+91 98765 40021',
          ordersLabel: '12 orders',
          totalSpent: 'Rs. 18,400',
        ),
        DashboardCustomer(
          name: 'Hassan Ali',
          phone: '+91 98765 40318',
          ordersLabel: '8 orders',
          totalSpent: 'Rs. 10,250',
        ),
      ],
      activities: <DashboardActivity>[
        DashboardActivity(
          type: DashboardActivityType.order,
          title: 'Order ORD-1042 is ready',
          description: 'Pickup notification queued for Hassan Ali',
          timeLabel: '10 min ago',
        ),
        DashboardActivity(
          type: DashboardActivityType.payment,
          title: 'Payment received',
          description: 'Rs. 2,200 received for BILL-882',
          timeLabel: '32 min ago',
        ),
        DashboardActivity(
          type: DashboardActivityType.customer,
          title: 'New customer added',
          description: 'Meera Kapoor joined Main Branch',
          timeLabel: '1 hr ago',
        ),
      ],
      quickActions: <DashboardQuickAction>[
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
      ],
      revenuePoints: <DashboardRevenuePoint>[
        DashboardRevenuePoint(label: 'Mon', value: .52),
        DashboardRevenuePoint(label: 'Tue', value: .68),
        DashboardRevenuePoint(label: 'Wed', value: .61),
        DashboardRevenuePoint(label: 'Thu', value: .82),
        DashboardRevenuePoint(label: 'Fri', value: .74),
        DashboardRevenuePoint(label: 'Sat', value: 1),
        DashboardRevenuePoint(label: 'Sun', value: .86),
      ],
      branchPerformance: <DashboardBranchPerformance>[
        DashboardBranchPerformance(
          name: 'Retail Counter',
          ordersLabel: '18 orders',
          revenueLabel: 'Rs. 13,200',
          progress: .72,
        ),
        DashboardBranchPerformance(
          name: 'Pickup & Delivery',
          ordersLabel: '6 orders',
          revenueLabel: 'Rs. 5,250',
          progress: .28,
        ),
      ],
      branchSummary: DashboardBranchSummary(
        manager: 'Priya Sharma',
        teamSize: '12 members',
        openOrders: '16 open',
        completedToday: '19 completed',
      ),
    ),
    'branch-a': DashboardData(
      branchId: 'branch-a',
      branchName: 'Branch A',
      ownerName: 'User',
      businessName: 'Nexoraa Laundry & Cleaners',
      revenue: 'Rs. 12,780',
      revenueChange: '+8.4%',
      revenueComparison: 'vs yesterday',
      kpis: <DashboardMetric>[
        DashboardMetric(
          type: DashboardMetricType.orders,
          label: "Today's Orders",
          value: '17',
          supportingText: '+2 from yesterday',
        ),
        DashboardMetric(
          type: DashboardMetricType.payments,
          label: 'Payments',
          value: 'Rs. 10.1K',
          supportingText: '9 collected',
        ),
        DashboardMetric(
          type: DashboardMetricType.expenses,
          label: 'Expenses',
          value: 'Rs. 2,850',
          supportingText: '2 entries today',
        ),
        DashboardMetric(
          type: DashboardMetricType.outstanding,
          label: 'Outstanding',
          value: 'Rs. 1,480',
          supportingText: '2 customers',
        ),
        DashboardMetric(
          type: DashboardMetricType.ready,
          label: 'Ready Orders',
          value: '5',
          supportingText: 'Awaiting pickup',
        ),
        DashboardMetric(
          type: DashboardMetricType.delayed,
          label: 'Delayed Orders',
          value: '1',
          supportingText: 'Needs attention',
        ),
      ],
      summaryMetrics: <DashboardMetric>[
        DashboardMetric(
          type: DashboardMetricType.bills,
          label: 'Bills',
          value: '13',
          supportingText: '11 paid',
        ),
        DashboardMetric(
          type: DashboardMetricType.customers,
          label: 'Customers',
          value: '29',
          supportingText: '3 new today',
        ),
        DashboardMetric(
          type: DashboardMetricType.deliveries,
          label: 'Deliveries',
          value: '8',
          supportingText: '6 completed',
        ),
      ],
      orders: <DashboardOrder>[
        DashboardOrder(
          customerName: 'Ananya Rao',
          orderNumber: 'A-703',
          description: '4 premium garments',
          amount: 'Rs. 1,280',
          timeLabel: '18 min ago',
          status: DashboardStatus.processing,
        ),
        DashboardOrder(
          customerName: 'Rohan Mehta',
          orderNumber: 'A-702',
          description: 'Wash and fold',
          amount: 'Rs. 620',
          timeLabel: '1 hr ago',
          status: DashboardStatus.ready,
        ),
      ],
      bills: <DashboardBill>[
        DashboardBill(
          customerName: 'Ananya Rao',
          billNumber: 'A-BILL-312',
          amount: 'Rs. 1,280',
          dueLabel: 'Paid today',
          status: DashboardStatus.completed,
        ),
        DashboardBill(
          customerName: 'Kabir Singh',
          billNumber: 'A-BILL-309',
          amount: 'Rs. 940',
          dueLabel: 'Overdue by 1 day',
          status: DashboardStatus.overdue,
        ),
      ],
      customers: <DashboardCustomer>[
        DashboardCustomer(
          name: 'Ananya Rao',
          phone: '+91 98210 77102',
          ordersLabel: '9 orders',
          totalSpent: 'Rs. 12,880',
        ),
        DashboardCustomer(
          name: 'Rohan Mehta',
          phone: '+91 98210 77445',
          ordersLabel: '6 orders',
          totalSpent: 'Rs. 7,420',
        ),
      ],
      activities: <DashboardActivity>[
        DashboardActivity(
          type: DashboardActivityType.delivery,
          title: 'Delivery completed',
          description: 'A-698 delivered to Kabir Singh',
          timeLabel: '15 min ago',
        ),
        DashboardActivity(
          type: DashboardActivityType.order,
          title: 'New express order',
          description: 'A-703 accepted for Ananya Rao',
          timeLabel: '18 min ago',
        ),
        DashboardActivity(
          type: DashboardActivityType.bill,
          title: 'Bill requires attention',
          description: 'A-BILL-309 is overdue',
          timeLabel: '42 min ago',
        ),
      ],
      quickActions: <DashboardQuickAction>[
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
      ],
      revenuePoints: <DashboardRevenuePoint>[
        DashboardRevenuePoint(label: 'Mon', value: .45),
        DashboardRevenuePoint(label: 'Tue', value: .58),
        DashboardRevenuePoint(label: 'Wed', value: .72),
        DashboardRevenuePoint(label: 'Thu', value: .66),
        DashboardRevenuePoint(label: 'Fri', value: .83),
        DashboardRevenuePoint(label: 'Sat', value: .91),
        DashboardRevenuePoint(label: 'Sun', value: .78),
      ],
      branchPerformance: <DashboardBranchPerformance>[
        DashboardBranchPerformance(
          name: 'Walk-in Orders',
          ordersLabel: '12 orders',
          revenueLabel: 'Rs. 8,920',
          progress: .7,
        ),
        DashboardBranchPerformance(
          name: 'Delivery Orders',
          ordersLabel: '5 orders',
          revenueLabel: 'Rs. 3,860',
          progress: .3,
        ),
      ],
      branchSummary: DashboardBranchSummary(
        manager: 'Neha Joshi',
        teamSize: '8 members',
        openOrders: '11 open',
        completedToday: '14 completed',
      ),
    ),
    'branch-b': DashboardData(
      branchId: 'branch-b',
      branchName: 'Branch B',
      ownerName: 'User',
      businessName: 'Nexoraa Laundry & Cleaners',
      revenue: 'Rs. 9,640',
      revenueChange: '-2.1%',
      revenueComparison: 'vs yesterday',
      kpis: <DashboardMetric>[
        DashboardMetric(
          type: DashboardMetricType.orders,
          label: "Today's Orders",
          value: '13',
          supportingText: '-1 from yesterday',
        ),
        DashboardMetric(
          type: DashboardMetricType.payments,
          label: 'Payments',
          value: 'Rs. 7.8K',
          supportingText: '7 collected',
        ),
        DashboardMetric(
          type: DashboardMetricType.expenses,
          label: 'Expenses',
          value: 'Rs. 3,100',
          supportingText: '4 entries today',
        ),
        DashboardMetric(
          type: DashboardMetricType.outstanding,
          label: 'Outstanding',
          value: 'Rs. 3,260',
          supportingText: '5 customers',
        ),
        DashboardMetric(
          type: DashboardMetricType.ready,
          label: 'Ready Orders',
          value: '4',
          supportingText: 'Awaiting pickup',
        ),
        DashboardMetric(
          type: DashboardMetricType.delayed,
          label: 'Delayed Orders',
          value: '3',
          supportingText: 'Needs attention',
        ),
      ],
      summaryMetrics: <DashboardMetric>[
        DashboardMetric(
          type: DashboardMetricType.bills,
          label: 'Bills',
          value: '10',
          supportingText: '6 paid',
        ),
        DashboardMetric(
          type: DashboardMetricType.customers,
          label: 'Customers',
          value: '21',
          supportingText: '2 new today',
        ),
        DashboardMetric(
          type: DashboardMetricType.deliveries,
          label: 'Deliveries',
          value: '6',
          supportingText: '3 completed',
        ),
      ],
      orders: <DashboardOrder>[
        DashboardOrder(
          customerName: 'Vikram Das',
          orderNumber: 'B-411',
          description: 'Curtain cleaning',
          amount: 'Rs. 1,900',
          timeLabel: '12 min ago',
          status: DashboardStatus.pending,
        ),
        DashboardOrder(
          customerName: 'Isha Patel',
          orderNumber: 'B-410',
          description: '2 dresses, 1 jacket',
          amount: 'Rs. 1,150',
          timeLabel: '50 min ago',
          status: DashboardStatus.processing,
        ),
      ],
      bills: <DashboardBill>[
        DashboardBill(
          customerName: 'Vikram Das',
          billNumber: 'B-BILL-205',
          amount: 'Rs. 1,900',
          dueLabel: 'Due today',
          status: DashboardStatus.pending,
        ),
        DashboardBill(
          customerName: 'Isha Patel',
          billNumber: 'B-BILL-204',
          amount: 'Rs. 1,150',
          dueLabel: 'Paid today',
          status: DashboardStatus.completed,
        ),
      ],
      customers: <DashboardCustomer>[
        DashboardCustomer(
          name: 'Isha Patel',
          phone: '+91 97644 10288',
          ordersLabel: '7 orders',
          totalSpent: 'Rs. 8,950',
        ),
        DashboardCustomer(
          name: 'Vikram Das',
          phone: '+91 97644 10901',
          ordersLabel: '4 orders',
          totalSpent: 'Rs. 6,700',
        ),
      ],
      activities: <DashboardActivity>[
        DashboardActivity(
          type: DashboardActivityType.order,
          title: 'Order awaiting assignment',
          description: 'B-411 needs a cleaning specialist',
          timeLabel: '12 min ago',
        ),
        DashboardActivity(
          type: DashboardActivityType.payment,
          title: 'Payment received',
          description: 'Rs. 1,150 received for B-BILL-204',
          timeLabel: '26 min ago',
        ),
        DashboardActivity(
          type: DashboardActivityType.delivery,
          title: 'Delivery delayed',
          description: 'Traffic delay reported for B-407',
          timeLabel: '1 hr ago',
        ),
      ],
      quickActions: <DashboardQuickAction>[
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
      ],
      revenuePoints: <DashboardRevenuePoint>[
        DashboardRevenuePoint(label: 'Mon', value: .72),
        DashboardRevenuePoint(label: 'Tue', value: .64),
        DashboardRevenuePoint(label: 'Wed', value: .79),
        DashboardRevenuePoint(label: 'Thu', value: .58),
        DashboardRevenuePoint(label: 'Fri', value: .62),
        DashboardRevenuePoint(label: 'Sat', value: .88),
        DashboardRevenuePoint(label: 'Sun', value: .69),
      ],
      branchPerformance: <DashboardBranchPerformance>[
        DashboardBranchPerformance(
          name: 'Walk-in Orders',
          ordersLabel: '9 orders',
          revenueLabel: 'Rs. 6,520',
          progress: .68,
        ),
        DashboardBranchPerformance(
          name: 'Delivery Orders',
          ordersLabel: '4 orders',
          revenueLabel: 'Rs. 3,120',
          progress: .32,
        ),
      ],
      branchSummary: DashboardBranchSummary(
        manager: 'Arjun Nair',
        teamSize: '7 members',
        openOrders: '12 open',
        completedToday: '8 completed',
      ),
    ),
    'branch-c': DashboardData(
      branchId: 'branch-c',
      branchName: 'Branch C',
      ownerName: 'User',
      businessName: 'Nexoraa Laundry & Cleaners',
      revenue: 'Rs. 15,920',
      revenueChange: '+18.7%',
      revenueComparison: 'vs yesterday',
      kpis: <DashboardMetric>[
        DashboardMetric(
          type: DashboardMetricType.orders,
          label: "Today's Orders",
          value: '21',
          supportingText: '+6 from yesterday',
        ),
        DashboardMetric(
          type: DashboardMetricType.payments,
          label: 'Payments',
          value: 'Rs. 13.5K',
          supportingText: '15 collected',
        ),
        DashboardMetric(
          type: DashboardMetricType.expenses,
          label: 'Expenses',
          value: 'Rs. 2,980',
          supportingText: '2 entries today',
        ),
        DashboardMetric(
          type: DashboardMetricType.outstanding,
          label: 'Outstanding',
          value: 'Rs. 1,120',
          supportingText: '2 customers',
        ),
        DashboardMetric(
          type: DashboardMetricType.ready,
          label: 'Ready Orders',
          value: '9',
          supportingText: 'Awaiting pickup',
        ),
        DashboardMetric(
          type: DashboardMetricType.delayed,
          label: 'Delayed Orders',
          value: '0',
          supportingText: 'All on schedule',
        ),
      ],
      summaryMetrics: <DashboardMetric>[
        DashboardMetric(
          type: DashboardMetricType.bills,
          label: 'Bills',
          value: '19',
          supportingText: '17 paid',
        ),
        DashboardMetric(
          type: DashboardMetricType.customers,
          label: 'Customers',
          value: '34',
          supportingText: '7 new today',
        ),
        DashboardMetric(
          type: DashboardMetricType.deliveries,
          label: 'Deliveries',
          value: '14',
          supportingText: '12 completed',
        ),
      ],
      orders: <DashboardOrder>[
        DashboardOrder(
          customerName: 'Zoya Khan',
          orderNumber: 'C-829',
          description: 'Wedding wear care',
          amount: 'Rs. 3,400',
          timeLabel: '8 min ago',
          status: DashboardStatus.processing,
        ),
        DashboardOrder(
          customerName: 'Dev Malhotra',
          orderNumber: 'C-828',
          description: 'Express wash',
          amount: 'Rs. 760',
          timeLabel: '22 min ago',
          status: DashboardStatus.ready,
        ),
      ],
      bills: <DashboardBill>[
        DashboardBill(
          customerName: 'Zoya Khan',
          billNumber: 'C-BILL-441',
          amount: 'Rs. 3,400',
          dueLabel: 'Paid today',
          status: DashboardStatus.completed,
        ),
        DashboardBill(
          customerName: 'Dev Malhotra',
          billNumber: 'C-BILL-440',
          amount: 'Rs. 760',
          dueLabel: 'Paid today',
          status: DashboardStatus.completed,
        ),
      ],
      customers: <DashboardCustomer>[
        DashboardCustomer(
          name: 'Zoya Khan',
          phone: '+91 99021 88144',
          ordersLabel: '14 orders',
          totalSpent: 'Rs. 24,600',
        ),
        DashboardCustomer(
          name: 'Dev Malhotra',
          phone: '+91 99021 88663',
          ordersLabel: '10 orders',
          totalSpent: 'Rs. 13,250',
        ),
      ],
      activities: <DashboardActivity>[
        DashboardActivity(
          type: DashboardActivityType.customer,
          title: 'New customer added',
          description: 'Zoya Khan joined Branch C',
          timeLabel: '8 min ago',
        ),
        DashboardActivity(
          type: DashboardActivityType.order,
          title: 'Priority care started',
          description: 'C-829 moved to processing',
          timeLabel: '14 min ago',
        ),
        DashboardActivity(
          type: DashboardActivityType.delivery,
          title: 'Delivery route completed',
          description: 'All morning deliveries completed',
          timeLabel: '35 min ago',
        ),
      ],
      quickActions: <DashboardQuickAction>[
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
      ],
      revenuePoints: <DashboardRevenuePoint>[
        DashboardRevenuePoint(label: 'Mon', value: .48),
        DashboardRevenuePoint(label: 'Tue', value: .63),
        DashboardRevenuePoint(label: 'Wed', value: .76),
        DashboardRevenuePoint(label: 'Thu', value: .81),
        DashboardRevenuePoint(label: 'Fri', value: .9),
        DashboardRevenuePoint(label: 'Sat', value: 1),
        DashboardRevenuePoint(label: 'Sun', value: .94),
      ],
      branchPerformance: <DashboardBranchPerformance>[
        DashboardBranchPerformance(
          name: 'Walk-in Orders',
          ordersLabel: '14 orders',
          revenueLabel: 'Rs. 10,780',
          progress: .68,
        ),
        DashboardBranchPerformance(
          name: 'Delivery Orders',
          ordersLabel: '7 orders',
          revenueLabel: 'Rs. 5,140',
          progress: .32,
        ),
      ],
      branchSummary: DashboardBranchSummary(
        manager: 'Sana Mirza',
        teamSize: '10 members',
        openOrders: '12 open',
        completedToday: '22 completed',
      ),
    ),
  };

  static List<DashboardData> get allBranches =>
      branches.values.toList(growable: false);

  static DashboardData branch(String id) =>
      branches[id] ?? branches[defaultBranchId]!;
}
