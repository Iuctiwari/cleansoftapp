import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/notifications/controllers/notification_controller.dart';
import 'package:nexoraa_mobile/features/notifications/models/notification.dart';
import 'package:nexoraa_mobile/features/notifications/services/notification_api_service.dart';
import 'package:nexoraa_mobile/features/notifications/widgets/notification_widgets.dart';
import 'package:nexoraa_mobile/features/orders/controllers/order_controller.dart';
import 'package:nexoraa_mobile/features/orders/models/order.dart';
import 'package:nexoraa_mobile/features/orders/screens/order_details_screen.dart';
import 'package:nexoraa_mobile/features/orders/services/order_api_service.dart';
import 'package:nexoraa_mobile/features/orders/widgets/order_widgets.dart';
import 'package:nexoraa_mobile/features/payments/controllers/payments_controller.dart';
import 'package:nexoraa_mobile/features/payments/screens/payments_screen.dart';
import 'package:nexoraa_mobile/features/payments/widgets/payments_widgets.dart';
import 'package:nexoraa_mobile/features/orders/services/payment_api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({this.branchId, this.controller, super.key});

  /// Active branch selected on the Dashboard. Every request made by this
  /// screen is scoped to it, matching how Orders/Payments/Customers scope
  /// their own API calls to the currently selected branch. Ignored when
  /// [controller] is supplied.
  final String? branchId;

  /// Optional pre-configured controller, for tests and any future caller
  /// that wants to share a controller instance. When omitted the screen
  /// owns its full lifecycle (construction, branch selection, real-time
  /// connection, and disposal) like this route is normally reached.
  final NotificationController? controller;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationController _controller;
  late final bool _ownsController;
  late final OrderController _orderController;
  final ScrollController _scrollController = ScrollController();
  final Map<String, Future<Order>> _orderCache = <String, Future<Order>>{};

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        NotificationController(
          service: NotificationApiService(
            tokenStorage: AuthenticationDependencies.tokenStorage,
          ),
        );
    _controller.addListener(_refresh);
    _scrollController.addListener(_onScroll);
    if (_ownsController) {
      _controller.selectBranch(widget.branchId);
      unawaited(_controller.connectRealtime());
    }
    _orderController = OrderController(
      service: OrderApiService(
        tokenStorage: AuthenticationDependencies.tokenStorage,
      )..selectBranch(_controller.branchId),
    );
    unawaited(_controller.ensureLoaded());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.removeListener(_refresh);
    if (_ownsController) _controller.dispose();
    _orderController.dispose();
    super.dispose();
  }

  /// Fetches (and caches) the order behind a notification, for the compact
  /// order number/customer name shown on its card. Reuses the existing
  /// Orders API via [_orderController] — no notification-service change.
  Future<Order> _orderFor(String orderId) =>
      _orderCache.putIfAbsent(orderId, () => _orderController.details(orderId));

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    // Only paginate while actively scrolling toward the bottom; scrolling
    // back up must never trigger a reload (pull-to-refresh is separate).
    if (_scrollController.position.userScrollDirection !=
        ScrollDirection.reverse) {
      return;
    }
    if (_scrollController.position.extentAfter < 240) {
      unawaited(_controller.loadMore());
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRouteNames.dashboard);
    }
  }

  Future<void> _reload() => _controller.load();

  /// Marks [notification] read (if not already) and navigates to the screen
  /// it relates to, reusing the same scoped-controller navigation pattern
  /// used everywhere else in the app (Dashboard, Customer Profile, More).
  /// Marking read is fire-and-forget — [NotificationController.markRead]
  /// already updates local state/badge optimistically, so navigation never
  /// waits on the network.
  Future<void> _openNotification(AppNotification notification) async {
    if (!notification.isRead) unawaited(_controller.markRead(notification.id));
    final String? orderId = notification.orderId;
    if (orderId == null || !mounted) return;
    switch (notification.type) {
      case AppNotificationType.paymentPending:
        await _openPayments(initialTab: PaymentsTab.outstanding);
      case AppNotificationType.paymentReceived:
        await _openPayments();
      case AppNotificationType.orderCreated:
      case AppNotificationType.orderInProgress:
      case AppNotificationType.orderInDelivery:
      case AppNotificationType.deliveryCompleted:
      case AppNotificationType.workerAssigned:
      case AppNotificationType.assignmentAccepted:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => OrderDetailsScreen(
              orderId: orderId,
              controller: _orderController,
            ),
          ),
        );
      case AppNotificationType.system:
      // No related screen to navigate to.
    }
  }

  /// Opens the existing Payments screen, reusing the same scoped-controller
  /// navigation pattern already used by the Dashboard/More/Customer Profile.
  Future<void> _openPayments({PaymentsTab initialTab = PaymentsTab.history}) async {
    final String? branchId = _controller.branchId;
    if (branchId == null) return;
    final PaymentApiService paymentService = PaymentApiService(
      tokenStorage: AuthenticationDependencies.tokenStorage,
    )..selectBranch(branchId);
    final PaymentsController controller = PaymentsController(
      paymentService: paymentService,
      orderController: _orderController,
    );
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PaymentsScreen(controller: controller, initialTab: initialTab),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _goBack,
          icon: const Icon(AppIcons.arrowBack),
          tooltip: 'Back to dashboard',
        ),
        title: const Text('Notifications'),
        actions: <Widget>[
          if (_controller.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: NotificationMarkAllReadButton(
                onPressed: () => unawaited(_controller.markAllRead()),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.authenticationContentMaxWidth,
            ),
            child: RefreshIndicator(
              onRefresh: _reload,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: _slivers(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _slivers() {
    return <Widget>[
      if (_controller.unreadCount > 0)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.xl,
              AppSpacing.pageHorizontal,
              AppSpacing.none,
            ),
            child: NotificationUnreadSummary(count: _controller.unreadCount),
          ),
        ),
      SliverToBoxAdapter(
        child: NotificationCategoryChips(
          selected: _controller.category,
          onSelected: _controller.selectCategory,
        ),
      ),
      ..._content(),
    ];
  }

  List<Widget> _content() {
    // Only replace the whole list with a spinner on the true first load
    // (nothing to show yet). A refresh relies on RefreshIndicator's own
    // spinner as the single loading indicator, instead of stacking a
    // second one on top of it.
    if (_controller.isLoading && !_controller.hasLoaded) {
      return const <Widget>[SliverFillRemaining(child: AppLoadingView())];
    }
    if (_controller.error != null && _controller.notifications.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorView(message: _controller.error!, onRetry: _reload),
        ),
      ];
    }
    final List<AppNotification> visible = _controller.notifications;
    if (visible.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: AppIcons.notificationsOff,
            title: 'No notifications',
            message: _controller.category == NotificationCategory.all
                ? "You're all caught up!"
                : 'Nothing in this category yet.',
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.sm,
          AppSpacing.pageHorizontal,
          AppSpacing.pageBottom,
        ),
        sliver: SliverList.separated(
          itemCount: visible.length + (_controller.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
          itemBuilder: (BuildContext context, int index) {
            if (index == visible.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final AppNotification notification = visible[index];
            return _NotificationCard(
              key: ValueKey<String>(notification.id),
              notification: notification,
              orderFor: _orderFor,
              onTap: () => unawaited(_openNotification(notification)),
            );
          },
        ),
      ),
    ];
  }
}

/// Resolves the related order (for the compact order number/customer name)
/// before rendering [NotificationListCard], without blocking the tap/read
/// behavior while that fetch is in flight or if it fails. Also applies an
/// instant, purely-local "read" override on tap so the unread dot clears on
/// the very same frame as the tap, independent of the controller's own
/// (already-optimistic, but network-adjacent) state update.
class _NotificationCard extends StatefulWidget {
  const _NotificationCard({
    required this.notification,
    required this.orderFor,
    required this.onTap,
    super.key,
  });

  final AppNotification notification;
  final Future<Order> Function(String orderId) orderFor;
  final VoidCallback onTap;

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _justRead = false;

  void _handleTap() {
    if (!_justRead && !widget.notification.isRead) {
      setState(() => _justRead = true);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final AppNotification notification = _justRead
        ? widget.notification.copyWith(isRead: true)
        : widget.notification;
    final String? orderId = notification.orderId;
    if (orderId == null) {
      return NotificationListCard(notification: notification, onTap: _handleTap);
    }
    return FutureBuilder<Order>(
      future: widget.orderFor(orderId),
      builder: (BuildContext context, AsyncSnapshot<Order> snapshot) {
        final Order? order = snapshot.data;
        final String? compact = order == null
            ? null
            : compactOrderNumber(order.orderNumber);
        return NotificationListCard(
          notification: notification,
          onTap: _handleTap,
          compactOrderNumber: compact,
          customerName: order?.customer.name,
          // The backend message embeds the full order number (e.g.
          // "ORD-B01-1024"); once resolved, show the same compact number
          // used everywhere else instead of the longer form.
          displayMessage: order == null || compact == null
              ? null
              : notification.message.replaceAll(order.orderNumber, compact),
        );
      },
    );
  }
}
