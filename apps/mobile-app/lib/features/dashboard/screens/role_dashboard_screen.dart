import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_models.dart';
import 'package:nexoraa_mobile/features/customers/controllers/customer_controller.dart';
import 'package:nexoraa_mobile/features/customers/models/customer.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_details_screen.dart';
import 'package:nexoraa_mobile/features/customers/screens/customer_list_screen.dart';
import 'package:nexoraa_mobile/features/customers/services/customer_api_service.dart';
import 'package:nexoraa_mobile/features/dashboard/controllers/dashboard_search_controller.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard_widgets.dart';
import 'package:nexoraa_mobile/features/dashboard/screens/more_screen.dart';
import 'package:nexoraa_mobile/features/expenses/screens/expense_list_screen.dart';
import 'package:nexoraa_mobile/features/notifications/controllers/notification_controller.dart';
import 'package:nexoraa_mobile/features/notifications/services/notification_api_service.dart';
import 'package:nexoraa_mobile/features/orders/controllers/new_order_controller.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/screens/new_order_screen.dart';
import 'package:nexoraa_mobile/features/orders/screens/order_details_screen.dart';
import 'package:nexoraa_mobile/features/orders/screens/orders_screen.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/order_catalog_api_service.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';
import 'package:nexoraa_mobile/features/payments/controllers/payments_controller.dart';
import 'package:nexoraa_mobile/features/payments/models/payment.dart';
import 'package:nexoraa_mobile/features/payments/screens/payments_screen.dart';
import 'package:nexoraa_mobile/features/reports/screens/reports_screen.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/services/staff_api_service.dart';
import 'package:nexoraa_mobile/features/tenant/services/tenant_api_service.dart';

enum RoleDashboardKind { branchManager, staff }

class RoleDashboardScreen extends StatefulWidget {
  const RoleDashboardScreen({required this.kind, this.session, super.key});

  final RoleDashboardKind kind;
  final AuthenticationSession? session;

  @override
  State<RoleDashboardScreen> createState() => _RoleDashboardScreenState();
}

class _RoleDashboardScreenState extends State<RoleDashboardScreen> {
  late final CustomerController _customerController;
  late final OrderController _orderController;
  late final PaymentApiService _paymentApiService;
  late final PaymentsController _dashboardPaymentsController;
  late final DashboardSearchController _searchController;
  late final NotificationController _notificationController;
  late final StaffApiService _staffApiService;

  List<Order> _recentBranchOrders = const <Order>[];
  List<StaffMember> _branchStaff = const <StaffMember>[];
  int? _todayOrders;
  int? _inProgressOrders;
  int? _readyOrders;
  int? _deliveriesDue;
  int? _assignedOrders;
  int? _completedOrders;
  bool _branchManagerDashboardLoading = true;

  int _currentNavigationIndex = 0;
  String _selectedBranchId = 'unavailable';
  String _branchName = 'Branch unavailable';
  String _businessName = '';
  String _staffAvailability = 'Available';

  bool get _isStaff => widget.kind == RoleDashboardKind.staff;

  AuthenticationSession? get _session =>
      widget.session ?? AuthenticationDependencies.controller.session;

  String get _roleLabel => _isStaff ? 'Staff' : 'Branch Manager';

  String get _displayName {
    final sessionName = _session?.ownerName?.trim() ?? '';
    if (sessionName.isNotEmpty) return sessionName;
    return 'Signed-in user';
  }

  String get _displayEmail => _session?.ownerEmail ?? '';

  @override
  void initState() {
    super.initState();
    _customerController = CustomerController(
      service: CustomerApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
    );
    _orderController = OrderController(
      service: OrderApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
    )..addListener(_onOrderControllerChanged);
    _paymentApiService = PaymentApiService(
      tokenStorage: AuthenticationDependencies.tokenStorage,
    );
    _dashboardPaymentsController = PaymentsController(
      paymentService: _paymentApiService,
      orderController: _orderController,
    )..addListener(_refreshDashboardData);
    _searchController = DashboardSearchController(
      orderService: OrderApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
      customerService: CustomerApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
      paymentService: PaymentApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
    );
    _notificationController = NotificationController(
      service: NotificationApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
    )..addListener(_refreshNotificationBadge);
    _staffApiService = StaffApiService(
      tokenStorage: AuthenticationDependencies.tokenStorage,
    );
    unawaited(_loadBranchContext());
  }

  @override
  void dispose() {
    _customerController.dispose();
    _orderController
      ..removeListener(_onOrderControllerChanged)
      ..dispose();
    _dashboardPaymentsController
      ..removeListener(_refreshDashboardData)
      ..dispose();
    _searchController.dispose();
    _notificationController
      ..removeListener(_refreshNotificationBadge)
      ..dispose();
    super.dispose();
  }

  void _onOrderControllerChanged() {
    if (mounted && _selectedBranchId != 'unavailable') {
      unawaited(_loadBranchManagerDashboardData());
    }
  }

  void _refreshNotificationBadge() {
    if (mounted) setState(() {});
  }

  void _refreshDashboardData() {
    if (mounted && !_isStaff) setState(() {});
  }

  Future<void> _loadBranchContext() async {
    final session = _session;
    final tenantId = session?.tenantId?.trim() ?? '';
    _businessName = session?.businessName?.trim().isNotEmpty == true
        ? session!.businessName!
        : _businessName;
    final String assignedBranchId = session?.branchId?.trim() ?? '';
    if (assignedBranchId.isNotEmpty) {
      _selectBranchContext(
        assignedBranchId,
        session?.branchName?.trim().isNotEmpty == true
            ? session!.branchName!
            : _branchName,
      );
      return;
    }
    if (tenantId.isEmpty) {
      _selectBranchContext('unavailable', _branchName);
      return;
    }
    // Fallback for sessions without a resolved branch (e.g. legacy tokens):
    // fetch the tenant's branches and use the first one.
    try {
      final TenantApiService service = TenantApiService();
      final profile = await service.getTenantProfile(tenantId);
      final branches = await service.listBranches(tenantId);
      if (!mounted) return;
      _businessName = profile.businessName;
      if (branches.isEmpty) {
        _selectBranchContext('unavailable', _branchName);
      } else {
        _selectBranchContext(
          branches.first.branchId,
          branches.first.branchName,
        );
      }
    } on Object {
      if (!mounted) return;
      _selectBranchContext('unavailable', _branchName);
    }
  }

  void _selectBranchContext(String branchId, String branchName) {
    setState(() {
      _selectedBranchId = branchId;
      _branchName = branchName.trim().isEmpty
          ? 'Branch unavailable'
          : branchName;
    });
    unawaited(_customerController.selectBranch(branchId));
    unawaited(_orderController.selectBranch(branchId));
    _paymentApiService.selectBranch(branchId);
    _searchController.selectBranch(branchId);
    _notificationController.selectBranch(branchId);
    unawaited(_notificationController.connectRealtime());
    unawaited(_notificationController.refreshUnreadCount());
    if (branchId != 'unavailable') {
      unawaited(_loadBranchManagerDashboardData());
    }
  }

  Future<void> _loadBranchManagerDashboardData() async {
    final String requestedBranchId = _selectedBranchId;
    final String tenantId = _session?.tenantId?.trim() ?? '';
    if (requestedBranchId == 'unavailable' || tenantId.isEmpty) {
      return;
    }
    if (mounted) setState(() => _branchManagerDashboardLoading = true);

    List<Order> recent = const <Order>[];
    List<StaffMember> staff = const <StaffMember>[];
    OrderStatistics? statistics;
    String? currentAvailability;
    await Future.wait<void>(<Future<void>>[
      () async {
        try {
          recent = await _orderController.recent(limit: 4);
        } on Object {
          recent = const <Order>[];
        }
      }(),
      () async {
        try {
          statistics = await _orderController.statistics();
        } on Object {
          statistics = null;
        }
      }(),
      if (!_isStaff) _dashboardPaymentsController.load(),
      if (!_isStaff)
        () async {
          try {
            staff = await _staffApiService.getStaffMembers(tenantId);
          } on Object {
            staff = const <StaffMember>[];
          }
        }(),
      if (_isStaff)
        () async {
          try {
            final StaffMember me = await _staffApiService.getMyProfile();
            currentAvailability = me.availability;
          } on Object {
            // Preserve current state
          }
        }(),
    ]);
    if (!mounted || requestedBranchId != _selectedBranchId) return;
    setState(() {
      if (currentAvailability != null && currentAvailability!.isNotEmpty) {
        _staffAvailability = currentAvailability!;
      }
      _recentBranchOrders = recent;
      _branchStaff = staff;
      _todayOrders = statistics?.todayOrders;
      _inProgressOrders = statistics?.count(OrderStatus.inProgress);
      _readyOrders = statistics?.count(OrderStatus.ready);
      _deliveriesDue = statistics?.count(OrderStatus.outForDelivery);
      _assignedOrders = statistics?.totalOrders;
      _completedOrders = statistics?.count(OrderStatus.delivered);
      _branchManagerDashboardLoading = false;
    });
  }

  Future<void> _changeStaffAvailability(String newStatus) async {
    final String previousStatus = _staffAvailability;
    setState(() => _staffAvailability = newStatus);
    try {
      final StaffMember updated = await _staffApiService.updateMyAvailability(
        newStatus,
      );
      if (mounted) {
        setState(() => _staffAvailability = updated.availability);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Availability updated to $newStatus'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _staffAvailability = previousStatus);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Failed to update availability: $e'),
              backgroundColor: AppColors.error,
            ),
          );
      }
    }
  }

  void _openSetAvailabilityBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return _SetAvailabilityBottomSheet(
          currentAvailability: _staffAvailability,
          onSelect: (String newStatus) {
            Navigator.of(sheetContext).pop();
            unawaited(_changeStaffAvailability(newStatus));
          },
        );
      },
    );
  }

  void _showUiOnlyMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openSearchOrder(Order order) async {
    _searchController.clear();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            OrderDetailsScreen(orderId: order.id, controller: _orderController),
      ),
    );
    if (mounted) unawaited(_loadBranchManagerDashboardData());
  }

  Future<void> _openSearchCustomer(Customer customer) async {
    _searchController.clear();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CustomerDetailsScreen(
          customerId: customer.id,
          controller: _customerController,
          accessPolicy: AccessPolicy(
            roleCode: _roleLabel,
            permissions: _session?.permissions ?? const <String>[],
          ),
        ),
      ),
    );
  }

  Future<void> _openSearchPayment(PaymentRecord _) async {
    _searchController.clear();
    await _openPayments();
  }

  Future<void> _openPayments() async {
    if (_selectedBranchId == 'unavailable') {
      _showUiOnlyMessage('Select an active branch before viewing payments.');
      return;
    }
    final PaymentApiService paymentService = PaymentApiService(
      tokenStorage: AuthenticationDependencies.tokenStorage,
    )..selectBranch(_selectedBranchId);
    final PaymentsController controller = PaymentsController(
      paymentService: paymentService,
      orderController: _orderController,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentsScreen(controller: controller),
      ),
    );
    controller.dispose();
  }

  Future<void> _openNewOrder() async {
    if (_isStaff) {
      _showUiOnlyMessage('New Order is not available for staff.');
      return;
    }
    if (_selectedBranchId == 'unavailable') {
      _showUiOnlyMessage('Select an active branch before creating an order.');
      return;
    }
    final NewOrderController controller = NewOrderController(
      catalogService: OrderCatalogApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
      orderController: _orderController,
      paymentService: PaymentApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      ),
      branchId: _selectedBranchId,
    );
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NewOrderScreen(
          controller: controller,
          orderController: _orderController,
          customerController: _customerController,
          businessName: _businessName,
          branchName: _branchName,
        ),
      ),
    );
    controller.dispose();
    if (created == true) await _orderController.load();
  }

  @override
  Widget build(BuildContext context) {
    final bool showingDashboard = _currentNavigationIndex == 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedSwitcher(
        duration: AppDurations.fast,
        child: switch (_currentNavigationIndex) {
          0 => CustomScrollView(
            key: ValueKey<String>('${widget.kind.name}-dashboard'),
            physics: const ClampingScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: _RoleHeader(
                  name: _displayName,
                  roleLabel: _roleLabel,
                  branchName: _branchName,
                  avatarColor: _isStaff
                      ? AppColors.successLight
                      : AppColors.secondaryLight,
                  unreadNotificationsCount: _notificationController.unreadCount,
                  searchController: _searchController,
                  onNotificationsPressed: () => context.pushNamed(
                    AppRouteNames.notifications,
                    extra: _notificationController,
                  ),
                  onProfilePressed: () =>
                      context.pushNamed(AppRouteNames.profile),
                  onOrderTap: (Order order) =>
                      unawaited(_openSearchOrder(order)),
                  onCustomerTap: (Customer customer) =>
                      unawaited(_openSearchCustomer(customer)),
                  onPaymentTap: (PaymentRecord payment) =>
                      unawaited(_openSearchPayment(payment)),
                ),
              ),
              SliverToBoxAdapter(
                child: _isStaff
                    ? _StaffDashboardBody(
                        isLoading: _branchManagerDashboardLoading,
                        availability: _staffAvailability,
                        onChangeAvailability: _openSetAvailabilityBottomSheet,
                        assigned: _assignedOrders,
                        tasksToday: _todayOrders,
                        inProgress: _inProgressOrders,
                        ready: _readyOrders,
                        completed: _completedOrders,
                        recentOrders: _recentBranchOrders,
                        onSeeOrders: () =>
                            setState(() => _currentNavigationIndex = 1),
                        onOrderTap: (Order order) =>
                            unawaited(_openSearchOrder(order)),
                      )
                    : _BranchManagerDashboardBody(
                        isLoading: _branchManagerDashboardLoading,
                        todayOrders: _todayOrders,
                        inProgressOrders: _inProgressOrders,
                        readyOrders: _readyOrders,
                        deliveriesDue: _deliveriesDue,
                        todayCollected:
                            _dashboardPaymentsController.todayCollected,
                        outstandingTotal:
                            _dashboardPaymentsController.outstandingTotal,
                        outstandingCustomerCount: _dashboardPaymentsController
                            .outstandingCustomerCount,
                        recentOrders: _recentBranchOrders,
                        branchStaff: _branchStaff,
                        onNewOrder: _openNewOrder,
                        onPayments: _openPayments,
                        onReports: () =>
                            setState(() => _currentNavigationIndex = 5),
                        onAssign: () =>
                            _showUiOnlyMessage('Assign is not available yet.'),
                        onSeeOrders: () =>
                            setState(() => _currentNavigationIndex = 1),
                      ),
              ),
            ],
          ),
          1 => OrdersScreen(
            key: const ValueKey<String>('orders'),
            controller: _orderController,
            onNewOrder: _isStaff ? null : _openNewOrder,
          ),
          2 => CustomerListScreen(
            key: const ValueKey<String>('customers'),
            controller: _customerController,
            accessPolicy: AccessPolicy(
              roleCode: _roleLabel,
              permissions: _session?.permissions ?? const <String>[],
            ),
          ),
          4 => ExpenseListScreen(
            key: const ValueKey<String>('expenses'),
            branchId: _selectedBranchId,
            onBack: () => setState(() => _currentNavigationIndex = 3),
          ),
          5 => ReportsScreen(
            key: const ValueKey<String>('reports'),
            branchId: _selectedBranchId,
            onBack: () => setState(() => _currentNavigationIndex = 3),
          ),
          _ => MoreScreen(
            key: const ValueKey<String>('more'),
            businessName: _businessName,
            onExpensesTap: () => setState(() => _currentNavigationIndex = 4),
            onReportsTap: () => setState(() => _currentNavigationIndex = 5),
            role: _roleLabel,
            userProfile: MoreUserProfileData(
              name: _displayName,
              email: _displayEmail,
            ),
            branchId: _selectedBranchId,
            orderController: _orderController,
            accessPolicy: AccessPolicy(
              roleCode: _roleLabel,
              permissions: _session?.permissions ?? const <String>[],
            ),
          ),
        },
      ),
      floatingActionButton: showingDashboard && !_isStaff
          ? FloatingActionButton(
              onPressed: _openNewOrder,
              tooltip: 'Create new order',
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: const CircleBorder(),
              child: const Icon(AppIcons.add),
            )
          : null,
      bottomNavigationBar: DashboardBottomNavigation(
        currentIndex:
            _currentNavigationIndex == 4 || _currentNavigationIndex == 5
            ? 3
            : _currentNavigationIndex,
        onTap: (int index) {
          if (index == 0 && _currentNavigationIndex != 0) {
            unawaited(_loadBranchManagerDashboardData());
          }
          setState(() => _currentNavigationIndex = index);
        },
      ),
    );
  }
}

class _RoleHeader extends StatelessWidget {
  const _RoleHeader({
    required this.name,
    required this.roleLabel,
    required this.branchName,
    required this.avatarColor,
    required this.unreadNotificationsCount,
    required this.searchController,
    required this.onNotificationsPressed,
    required this.onProfilePressed,
    required this.onOrderTap,
    required this.onCustomerTap,
    required this.onPaymentTap,
  });

  final String name;
  final String roleLabel;
  final String branchName;
  final Color avatarColor;
  final int unreadNotificationsCount;
  final DashboardSearchController searchController;
  final VoidCallback onNotificationsPressed;
  final VoidCallback onProfilePressed;
  final ValueChanged<Order> onOrderTap;
  final ValueChanged<Customer> onCustomerTap;
  final ValueChanged<PaymentRecord> onPaymentTap;

  String get _initials {
    final words = name
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList(growable: false);
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppGradients.primaryHeader),
      child: Stack(
        children: <Widget>[
          const Positioned(
            right: -60,
            top: -64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.whiteOverlay08,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(dimension: 190),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Good morning',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.whiteOverlay80,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.headingExtraLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '$roleLabel - $branchName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.whiteOverlay80,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _NotificationButton(
                        count: unreadNotificationsCount,
                        onPressed: onNotificationsPressed,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      GestureDetector(
                        onTap: onProfilePressed,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: avatarColor,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox.square(
                            dimension: 44,
                            child: Center(
                              child: Text(
                                _initials,
                                style: AppTextStyles.captionBold.copyWith(
                                  color: AppColors.surface,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  DashboardSearchBar(
                    controller: searchController,
                    onOrderTap: onOrderTap,
                    onCustomerTap: onCustomerTap,
                    onPaymentTap: onPaymentTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DashboardHeaderAction(
      onPressed: onPressed,
      tooltip: 'Notifications',
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Icon(AppIcons.notifications, size: AppIconSizes.lg),
          if (count > 0)
            Positioned(
              right: -AppSpacing.xxs,
              top: -AppSpacing.xxs,
              child: Container(
                width: AppSpacing.md,
                height: AppSpacing.md,
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BranchManagerDashboardBody extends StatelessWidget {
  const _BranchManagerDashboardBody({
    required this.isLoading,
    required this.todayOrders,
    required this.inProgressOrders,
    required this.readyOrders,
    required this.deliveriesDue,
    required this.todayCollected,
    required this.outstandingTotal,
    required this.outstandingCustomerCount,
    required this.recentOrders,
    required this.branchStaff,
    required this.onNewOrder,
    required this.onPayments,
    required this.onReports,
    required this.onAssign,
    required this.onSeeOrders,
  });

  final bool isLoading;
  final int? todayOrders;
  final int? inProgressOrders;
  final int? readyOrders;
  final int? deliveriesDue;
  final double todayCollected;
  final double outstandingTotal;
  final int outstandingCustomerCount;
  final List<Order> recentOrders;
  final List<StaffMember> branchStaff;
  final VoidCallback onNewOrder;
  final VoidCallback onPayments;
  final VoidCallback onReports;
  final VoidCallback onAssign;
  final VoidCallback onSeeOrders;

  String _count(int? value) => isLoading || value == null ? '—' : '$value';

  List<StaffMember> get _workers => branchStaff
      .where((StaffMember member) => member.role == 'Staff')
      .toList(growable: false);

  int get _activeWorkers => _workers
      .where((StaffMember member) => member.status.toLowerCase() == 'active')
      .length;

  int get _offlineWorkers => _workers.length - _activeWorkers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.display,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MetricGrid(
            cards: <_MetricCardData>[
              _MetricCardData(
                icon: AppIcons.receipt,
                iconColor: AppColors.primary,
                iconBackground: AppColors.primarySurface,
                title: 'Branch Orders',
                value: _count(todayOrders),
                subtitle: 'Today',
              ),
              _MetricCardData(
                icon: AppIcons.refresh,
                iconColor: AppColors.secondary,
                iconBackground: AppColors.secondarySurface,
                title: 'In Progress',
                value: _count(inProgressOrders),
                subtitle: 'Active now',
              ),
              _MetricCardData(
                icon: AppIcons.package,
                iconColor: AppColors.successLight,
                iconBackground: AppColors.successSurface,
                title: 'Ready',
                value: _count(readyOrders),
                subtitle: 'Awaiting pickup',
              ),
              _MetricCardData(
                icon: AppIcons.delivery,
                iconColor: AppColors.warning,
                iconBackground: AppColors.warningSurface,
                title: 'Deliveries Due',
                value: _count(deliveriesDue),
                subtitle: 'Active deliveries',
              ),
              _MetricCardData(
                icon: AppIcons.wallet,
                iconColor: AppColors.successLight,
                iconBackground: AppColors.successSurface,
                title: 'Cash Received',
                value: isLoading ? '—' : formatOrderMoney(todayCollected),
                subtitle: 'Today',
              ),
              _MetricCardData(
                icon: AppIcons.alert,
                iconColor: AppColors.errorLight,
                iconBackground: AppColors.errorSurface,
                title: 'Outstanding',
                value: isLoading ? '—' : formatOrderMoney(outstandingTotal),
                subtitle: isLoading
                    ? 'Loading...'
                    : outstandingCustomerCount == 1
                    ? '1 customer'
                    : '$outstandingCustomerCount customers',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle(title: 'Cash Register'),
          const SizedBox(height: AppSpacing.md),
          const _CashRegisterCard(
            status: 'Cash register unavailable',
            detail: 'No cash-register API is configured',
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionHeader(title: 'Team Status', actionLabel: 'Full View'),
          const SizedBox(height: AppSpacing.md),
          _TeamStatusRow(
            available: isLoading ? null : _activeWorkers,
            // The Staff API does not expose live busy/break presence. Keep
            // those slots data-neutral instead of presenting fabricated 0s.
            busy: null,
            onBreak: null,
            offline: isLoading ? null : _offlineWorkers,
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionTitle(title: 'Quick Actions'),
          const SizedBox(height: AppSpacing.md),
          _QuickActionsRow(
            actions: <_QuickActionData>[
              _QuickActionData(
                icon: AppIcons.add,
                label: 'New Order',
                iconColor: AppColors.primary,
                background: AppColors.primarySurface,
                onTap: onNewOrder,
              ),
              _QuickActionData(
                icon: AppIcons.arrowUpRight,
                label: 'Payments',
                iconColor: AppColors.successLight,
                background: AppColors.successSurface,
                onTap: onPayments,
              ),
              _QuickActionData(
                icon: AppIcons.analytics,
                label: 'Reports',
                iconColor: AppColors.secondary,
                background: AppColors.secondarySurface,
                onTap: onReports,
              ),
              _QuickActionData(
                icon: AppIcons.refresh,
                label: 'Assign',
                iconColor: AppColors.warning,
                background: AppColors.warningSurface,
                onTap: onAssign,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
            title: 'Recent Orders',
            actionLabel: 'See all',
            onTap: onSeeOrders,
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const AppLoadingView()
          else if (recentOrders.isEmpty)
            const AppEmptyState(
              icon: AppIcons.receipt,
              title: 'No recent orders',
              message: 'New branch orders will appear here.',
            )
          else
            ...recentOrders.map(_orderCard),
        ],
      ),
    );
  }

  _OrderCard _orderCard(Order order) {
    final String customerName = order.customer.name;
    final List<String> words = customerName
        .split(RegExp(r'\s+'))
        .where((String value) => value.isNotEmpty)
        .toList(growable: false);
    final String initials = words.isEmpty
        ? 'C'
        : words.length == 1
        ? words.first.substring(0, 1).toUpperCase()
        : '${words.first[0]}${words.last[0]}'.toUpperCase();
    final String items = order.items
        .map((OrderItem item) => item.itemCategoryName)
        .take(2)
        .join(', ');
    final (Color statusColor, Color statusBackground) = orderStatusColors(
      order.status,
    );
    return _OrderCard(
      initials: initials,
      customer: customerName,
      order: '${order.orderNumber} · ${items.isEmpty ? 'Order items' : items}',
      meta: _relativeTime(order.createdAt),
      trailing: formatOrderMoney(order.grandTotal),
      status: order.status.label,
      statusColor: statusColor,
      statusBackground: statusBackground,
    );
  }

  String _relativeTime(DateTime createdAt) {
    final Duration difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hrs ago';
    return '${difference.inDays} days ago';
  }
}

class _StaffDashboardBody extends StatelessWidget {
  const _StaffDashboardBody({
    required this.isLoading,
    required this.availability,
    required this.onChangeAvailability,
    required this.assigned,
    required this.tasksToday,
    required this.inProgress,
    required this.ready,
    required this.completed,
    required this.recentOrders,
    required this.onSeeOrders,
    required this.onOrderTap,
  });

  final bool isLoading;
  final String availability;
  final VoidCallback onChangeAvailability;
  final int? assigned;
  final int? tasksToday;
  final int? inProgress;
  final int? ready;
  final int? completed;
  final List<Order> recentOrders;
  final VoidCallback onSeeOrders;
  final ValueChanged<Order> onOrderTap;

  String _count(int? value) => isLoading ? '—' : '${value ?? 0}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.display,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TaskHeroCard(
            assigned: _count(tasksToday),
            inProgress: _count(inProgress),
            completed: _count(completed),
            availability: availability,
          ),
          const SizedBox(height: AppSpacing.md),
          _StaffAvailabilityCard(
            availability: availability,
            onChange: onChangeAvailability,
          ),
          const SizedBox(height: AppSpacing.md),
          _MetricGrid(
            cards: <_MetricCardData>[
              _MetricCardData(
                icon: AppIcons.checklist,
                iconColor: AppColors.primary,
                iconBackground: AppColors.primarySurface,
                title: 'Assigned',
                value: _count(assigned),
                subtitle: 'Total assigned',
              ),
              _MetricCardData(
                icon: AppIcons.success,
                iconColor: AppColors.success,
                iconBackground: AppColors.successSurface,
                title: 'Ready',
                value: _count(ready),
                subtitle: 'Awaiting pickup',
              ),
              _MetricCardData(
                icon: AppIcons.refresh,
                iconColor: AppColors.secondary,
                iconBackground: AppColors.secondarySurface,
                title: 'In Progress',
                value: _count(inProgress),
                subtitle: 'Currently active',
              ),
              _MetricCardData(
                icon: AppIcons.success,
                iconColor: AppColors.successLight,
                iconBackground: AppColors.successSurface,
                title: 'Completed',
                value: _count(completed),
                subtitle: 'Total delivered',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _SectionHeader(
            title: 'My Assigned Orders',
            actionLabel: 'See all',
            onTap: onSeeOrders,
          ),
          const SizedBox(height: AppSpacing.md),
          if (isLoading)
            const AppLoadingView()
          else if (recentOrders.isEmpty)
            const AppEmptyState(
              icon: AppIcons.receipt,
              title: 'No assigned orders',
              message: 'Orders assigned to you will appear here.',
            )
          else
            ...recentOrders.map(_orderCard),
        ],
      ),
    );
  }

  _OrderCard _orderCard(Order order) {
    final String customerName = order.customer.name;
    final List<String> words = customerName
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final String initials = words.isEmpty
        ? 'C'
        : words.length == 1
        ? words.first[0].toUpperCase()
        : '${words.first[0]}${words.last[0]}'.toUpperCase();
    final String items = order.items
        .map((item) => item.itemCategoryName)
        .take(2)
        .join(', ');
    final (Color statusColor, Color statusBackground) = orderStatusColors(
      order.status,
    );
    return _OrderCard(
      initials: initials,
      customer: customerName,
      order: '${order.orderNumber} · ${items.isEmpty ? 'Order items' : items}',
      meta: _relativeTime(order.createdAt),
      trailing: formatOrderMoney(order.grandTotal),
      status: order.status.label,
      statusColor: statusColor,
      statusBackground: statusBackground,
      avatarColor: AppColors.secondary,
      onTap: () => onOrderTap(order),
    );
  }

  String _relativeTime(DateTime createdAt) {
    final Duration difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hrs ago';
    return '${difference.inDays} days ago';
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.cards});

  final List<_MetricCardData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gap = AppSpacing.md;
        final double width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: cards
              .map(
                (_MetricCardData card) => SizedBox(
                  width: width,
                  child: _MetricCard(data: card),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;
  final String subtitle;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              _SmallIcon(
                icon: data.icon,
                color: data.iconColor,
                background: data.iconBackground,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            data.value,
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.ink,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(data.subtitle, style: AppTextStyles.micro),
        ],
      ),
    );
  }
}

class _TaskHeroCard extends StatelessWidget {
  const _TaskHeroCard({
    required this.assigned,
    required this.inProgress,
    required this.completed,
    this.availability = 'Available',
  });

  final String assigned;
  final String inProgress;
  final String completed;
  final String availability;

  (Color, String) _getAvailabilityBadgeInfo(String status) {
    switch (status.toLowerCase()) {
      case 'busy':
        return (const Color(0xFFF59E0B), 'Busy');
      case 'on break':
      case 'break':
        return (const Color(0xFFEA580C), 'On Break');
      case 'offline':
        return (const Color(0xFF94A3B8), 'Offline');
      case 'available':
      default:
        return (const Color(0xFF10B981), 'Available');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (Color badgeDotColor, String badgeStatus) = _getAvailabilityBadgeInfo(
      availability,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.secondary, AppColors.secondaryLight],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'MY TASKS TODAY',
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.whiteOverlay80,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: badgeDotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      badgeStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$assigned Assigned',
            style: AppTextStyles.headingExtraLarge.copyWith(fontSize: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$inProgress In Progress   $completed Completed',
            style: AppTextStyles.captionBold.copyWith(
              color: AppColors.whiteOverlay80,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashRegisterCard extends StatelessWidget {
  const _CashRegisterCard({required this.status, required this.detail});

  final String status;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Row(
        children: <Widget>[
          const _SmallIcon(
            icon: AppIcons.wallet,
            color: AppColors.successLight,
            background: AppColors.successSubtle,
            large: true,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  status,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.successDarker,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.successDarker,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            AppIcons.chevronRight,
            color: AppColors.successLight,
            size: AppIconSizes.lg,
          ),
        ],
      ),
    );
  }
}

class _TeamStatusRow extends StatelessWidget {
  const _TeamStatusRow({
    required this.available,
    required this.busy,
    required this.onBreak,
    required this.offline,
  });

  final int? available;
  final int? busy;
  final int? onBreak;
  final int? offline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _TeamStatusCard(
            color: AppColors.availabilityAvailable,
            count: available?.toString() ?? '—',
            label: 'Available',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TeamStatusCard(
            color: AppColors.availabilityBusy,
            count: busy?.toString() ?? '—',
            label: 'Busy',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TeamStatusCard(
            color: AppColors.availabilityBreak,
            count: onBreak?.toString() ?? '—',
            label: 'On Break',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TeamStatusCard(
            color: AppColors.errorLight,
            count: offline?.toString() ?? '—',
            label: 'Offline',
          ),
        ),
      ],
    );
  }
}

class _TeamStatusCard extends StatelessWidget {
  const _TeamStatusCard({
    required this.color,
    required this.count,
    required this.label,
  });

  final Color color;
  final String count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: color.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(count, style: AppTextStyles.subtitle),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.micro,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<_QuickActionData> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions
          .map(
            (_QuickActionData action) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: action == actions.last ? 0 : AppSpacing.md,
                ),
                child: _QuickAction(data: action),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final Color background;
  final VoidCallback onTap;
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: AppShadows.subtle,
          ),
          child: Column(
            children: <Widget>[
              _SmallIcon(
                icon: data.icon,
                color: data.iconColor,
                background: data.background,
                large: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.micro.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.initials,
    required this.customer,
    required this.order,
    required this.meta,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
    this.trailing,
    this.avatarColor = AppColors.primary,
    this.onTap,
  });

  final String initials;
  final String customer;
  final String order;
  final String meta;
  final String status;
  final Color statusColor;
  final Color statusBackground;
  final String? trailing;
  final Color avatarColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppShadows.subtle,
        ),
        child: Row(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 42,
                child: Center(
                  child: Text(
                    initials,
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    customer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    order,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(meta, style: AppTextStyles.micro),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                if (trailing != null) ...<Widget>[
                  Text(
                    trailing!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _StatusPill(
                  label: status,
                  color: statusColor,
                  background: statusBackground,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: _SectionTitle(title: title)),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _SmallIcon extends StatelessWidget {
  const _SmallIcon({
    required this.icon,
    required this.color,
    required this.background,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox.square(
        dimension: large ? 42 : 30,
        child: Icon(icon, color: color, size: large ? 22 : 17),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: AppTextStyles.micro.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StaffAvailabilityCard extends StatelessWidget {
  const _StaffAvailabilityCard({
    required this.availability,
    required this.onChange,
  });

  final String availability;
  final VoidCallback onChange;

  ({
    Color bg,
    Color border,
    Color text,
    Color dot,
    Color buttonBg,
    Color buttonText,
    String description,
  })
  _getAvailabilityTheme(String status) {
    switch (status.toLowerCase()) {
      case 'busy':
        return (
          bg: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE68A),
          text: const Color(0xFFB45309),
          dot: const Color(0xFFF59E0B),
          buttonBg: const Color(0xFFFEF3C7),
          buttonText: const Color(0xFF92400E),
          description: 'Tap to update your availability',
        );
      case 'on break':
      case 'break':
        return (
          bg: const Color(0xFFFFF7ED),
          border: const Color(0xFFFED7AA),
          text: const Color(0xFFC2410C),
          dot: const Color(0xFFEA580C),
          buttonBg: const Color(0xFFFFEDD5),
          buttonText: const Color(0xFF9A3412),
          description: 'Tap to update your availability',
        );
      case 'offline':
        return (
          bg: const Color(0xFFF8FAFC),
          border: const Color(0xFFE2E8F0),
          text: const Color(0xFF475569),
          dot: const Color(0xFF94A3B8),
          buttonBg: const Color(0xFFF1F5F9),
          buttonText: const Color(0xFF334155),
          description: 'Tap to update your availability',
        );
      case 'available':
      default:
        return (
          bg: const Color(0xFFF0FDF4),
          border: const Color(0xFFBBF7D0),
          text: const Color(0xFF15803D),
          dot: const Color(0xFF16A34A),
          buttonBg: const Color(0xFFDCFCE7),
          buttonText: const Color(0xFF166534),
          description: 'Tap to update your availability',
        );
    }
  }

  String _formatStatus(String status) {
    final lower = status.toLowerCase();
    if (lower == 'busy') return 'Busy';
    if (lower == 'on break' || lower == 'break') return 'On Break';
    if (lower == 'offline') return 'Offline';
    return 'Available';
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getAvailabilityTheme(availability);
    final String statusLabel = _formatStatus(availability);

    return InkWell(
      onTap: onChange,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.dot,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: theme.dot.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    theme.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.buttonBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.buttonText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: theme.buttonText,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetAvailabilityBottomSheet extends StatelessWidget {
  const _SetAvailabilityBottomSheet({
    required this.currentAvailability,
    required this.onSelect,
  });

  final String currentAvailability;
  final ValueChanged<String> onSelect;

  static const List<({String status, String description, Color dotColor})>
  _options = <({String status, String description, Color dotColor})>[
    (
      status: 'Available',
      description: 'Ready to receive and work on assigned tasks',
      dotColor: Color(0xFF10B981),
    ),
    (
      status: 'Busy',
      description: 'Currently working — no new tasks please',
      dotColor: Color(0xFFF59E0B),
    ),
    (
      status: 'On Break',
      description: 'Taking a short break, back soon',
      dotColor: Color(0xFFEA580C),
    ),
    (
      status: 'Offline',
      description: 'Not available for work right now',
      dotColor: Color(0xFF94A3B8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Set Availability',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Let your team know your status',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._options.map((option) {
              final bool isSelected =
                  currentAvailability.toLowerCase() ==
                      option.status.toLowerCase() ||
                  (currentAvailability.isEmpty && option.status == 'Available');

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => onSelect(option.status),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF0F7FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: option.dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                option.status,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                option.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
