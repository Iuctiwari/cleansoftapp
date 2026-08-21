import 'package:flutter/foundation.dart';
import 'package:nexoraa_mobile/features/notifications/models/notification.dart';
import 'package:nexoraa_mobile/features/notifications/services/notification_api_service.dart';
import 'package:nexoraa_mobile/features/notifications/services/notification_socket_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({
    required NotificationApiService service,
    NotificationSocketService? socket,
  }) : _service = service,
       _socket = socket ?? NotificationSocketService();

  final NotificationApiService _service;
  final NotificationSocketService _socket;
  final List<AppNotification> _notifications = <AppNotification>[];
  int _page = 1;
  int _total = 0;
  int _totalPages = 0;
  int _unreadCount = 0;
  NotificationCategory _category = NotificationCategory.all;
  String? _error;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasLoaded = false;

  List<AppNotification> get notifications => _category == NotificationCategory.all
      ? List<AppNotification>.unmodifiable(_notifications)
      : List<AppNotification>.unmodifiable(
          _notifications.where(
            (AppNotification item) => item.category == _category,
          ),
        );
  int get total => _total;
  int get unreadCount => _unreadCount;
  NotificationCategory get category => _category;
  bool get isLoading => _loading;
  bool get isLoadingMore => _loadingMore;
  bool get hasMore => _page < _totalPages;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  bool get isRealtimeConnected => _socket.isConnected;

  /// Currently selected branch, for screens that need to scope other
  /// branch-aware services (e.g. Orders, Payments) to the same branch this
  /// controller's notifications are already scoped to.
  String? get branchId => _service.currentBranchId;

  void selectBranch(String? branchId) => _service.selectBranch(branchId);

  Future<void> ensureLoaded() async {
    if (!_hasLoaded && !_loading) await load();
  }

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    _page = 1;
    notifyListeners();
    try {
      final AppNotificationPage result = await _service.list(
        sortDirection: 'desc',
      );
      _notifications
        ..clear()
        ..addAll(result.items);
      _page = result.page;
      _total = result.total;
      _totalPages = result.totalPages;
      _hasLoaded = true;
      await _refreshUnreadCount();
    } on NotificationApiException catch (error) {
      _error = error.message;
      _notifications.clear();
      _total = 0;
      _totalPages = 0;
      _hasLoaded = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || _loading || _loadingMore) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final AppNotificationPage result = await _service.list(
        page: _page + 1,
        sortDirection: 'desc',
      );
      _notifications.addAll(result.items);
      _page = result.page;
      _total = result.total;
      _totalPages = result.totalPages;
      _error = null;
    } on NotificationApiException catch (error) {
      _error = error.message;
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  void selectCategory(NotificationCategory category) {
    if (category == _category) return;
    _category = category;
    notifyListeners();
  }

  Future<void> refreshUnreadCount() => _refreshUnreadCount();

  Future<void> _refreshUnreadCount() async {
    try {
      _unreadCount = await _service.unreadCount();
    } on NotificationApiException {
      // Keep the last-known count when the refresh itself fails.
    }
  }

  Future<void> markRead(String id) async {
    final int index = _notifications.indexWhere(
      (AppNotification item) => item.id == id,
    );
    if (index == -1 || _notifications[index].isRead) return;
    final AppNotification previous = _notifications[index];
    _notifications[index] = previous.copyWith(isRead: true);
    if (_unreadCount > 0) _unreadCount -= 1;
    notifyListeners();
    try {
      final AppNotification updated = await _service.markRead(id);
      final int current = _notifications.indexWhere(
        (AppNotification item) => item.id == id,
      );
      if (current != -1) _notifications[current] = updated;
    } on NotificationApiException {
      final int current = _notifications.indexWhere(
        (AppNotification item) => item.id == id,
      );
      if (current != -1) _notifications[current] = previous;
      _unreadCount += 1;
    } finally {
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    if (_unreadCount == 0 && _notifications.every((n) => n.isRead)) return;
    final List<AppNotification> previous = List<AppNotification>.of(
      _notifications,
    );
    final int previousUnread = _unreadCount;
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _unreadCount = 0;
    notifyListeners();
    try {
      await _service.markAllRead();
    } on NotificationApiException {
      _notifications
        ..clear()
        ..addAll(previous);
      _unreadCount = previousUnread;
    } finally {
      notifyListeners();
    }
  }

  /// Connects to the Notification Service's WebSocket gateway so new
  /// notifications, and read/read-all changes made elsewhere, appear
  /// without a manual refresh. No-ops silently if not authenticated/branch
  /// is not selected yet.
  Future<void> connectRealtime() async {
    final String? authorization = await _service.currentAuthorizationHeader();
    final String? branchId = _service.currentBranchId;
    if (authorization == null || branchId == null) return;
    _socket.connect(
      baseUri: _service.socketUri,
      authorizationHeader: authorization,
      branchId: branchId,
      onNew: _handleSocketNew,
      onRead: _handleSocketRead,
      onReadAll: _handleSocketReadAll,
    );
  }

  void disconnectRealtime() => _socket.disconnect();

  void _handleSocketNew(Map<String, dynamic> payload) {
    try {
      final AppNotification notification = AppNotification.fromJson(payload);
      if (_notifications.any((AppNotification item) => item.id == notification.id)) {
        return;
      }
      _notifications.insert(0, notification);
      _total += 1;
      if (!notification.isRead) _unreadCount += 1;
      notifyListeners();
    } on FormatException {
      // Ignore malformed real-time payloads; GET /notifications remains
      // the source of truth.
    }
  }

  void _handleSocketRead(Map<String, dynamic> payload) {
    try {
      final AppNotification notification = AppNotification.fromJson(payload);
      final int index = _notifications.indexWhere(
        (AppNotification item) => item.id == notification.id,
      );
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = notification;
        if (_unreadCount > 0) _unreadCount -= 1;
        notifyListeners();
      }
    } on FormatException {
      // Ignore malformed real-time payloads.
    }
  }

  void _handleSocketReadAll(Map<String, dynamic> payload) {
    if (_notifications.every((AppNotification item) => item.isRead) &&
        _unreadCount == 0) {
      return;
    }
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _unreadCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _socket.disconnect();
    super.dispose();
  }
}
