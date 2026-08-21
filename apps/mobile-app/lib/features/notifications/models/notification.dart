/// Notification types as defined by the Notification Service backend.
enum AppNotificationType {
  workerAssigned('WorkerAssigned'),
  assignmentAccepted('AssignmentAccepted'),
  orderCreated('OrderCreated'),
  orderInProgress('OrderInProgress'),
  orderInDelivery('OrderInDelivery'),
  deliveryCompleted('DeliveryCompleted'),
  paymentPending('PaymentPending'),
  paymentReceived('PaymentReceived'),
  system('System');

  const AppNotificationType(this.apiValue);

  final String apiValue;

  static AppNotificationType fromApi(String value) {
    for (final AppNotificationType type in values) {
      if (type.apiValue == value) return type;
    }
    throw FormatException('Unknown notification type: $value.');
  }

  /// Category this type is grouped under in the Notifications screen.
  NotificationCategory get category => switch (this) {
    AppNotificationType.workerAssigned ||
    AppNotificationType.assignmentAccepted => NotificationCategory.staff,
    AppNotificationType.orderCreated ||
    AppNotificationType.orderInProgress ||
    AppNotificationType.orderInDelivery ||
    AppNotificationType.deliveryCompleted => NotificationCategory.orders,
    AppNotificationType.paymentPending ||
    AppNotificationType.paymentReceived => NotificationCategory.payments,
    AppNotificationType.system => NotificationCategory.system,
  };
}

enum NotificationCategory {
  all('All'),
  orders('Orders'),
  payments('Payments'),
  staff('Staff'),
  system('System');

  const NotificationCategory(this.label);

  final String label;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.entityType,
    this.entityId,
    this.orderId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: _requiredText(json, 'id'),
        tenantId: _requiredText(json, 'tenantId'),
        branchId: _requiredText(json, 'branchId'),
        recipientId: _requiredText(json, 'recipientId'),
        title: _requiredText(json, 'title'),
        message: _requiredText(json, 'message'),
        type: AppNotificationType.fromApi(_requiredText(json, 'type')),
        entityType: _text(json['entityType']),
        entityId: _text(json['entityId']),
        orderId: _text(json['orderId']),
        isRead: json['isRead'] == true,
        createdAt: DateTime.parse(_requiredText(json, 'createdAt')),
        updatedAt: DateTime.parse(_requiredText(json, 'updatedAt')),
      );

  final String id;
  final String tenantId;
  final String branchId;
  final String recipientId;
  final String title;
  final String message;
  final AppNotificationType type;
  final String? entityType;
  final String? entityId;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationCategory get category => type.category;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    tenantId: tenantId,
    branchId: branchId,
    recipientId: recipientId,
    title: title,
    message: message,
    type: type,
    entityType: entityType,
    entityId: entityId,
    orderId: orderId,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class AppNotificationPage {
  const AppNotificationPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory AppNotificationPage.fromJson(Map<String, dynamic> json) =>
      AppNotificationPage(
        items: _list(
          json['items'],
        ).map((Object? item) => AppNotification.fromJson(_map(item))).toList(
          growable: false,
        ),
        total: _requiredInt(json, 'total'),
        page: _requiredInt(json, 'page'),
        limit: _requiredInt(json, 'limit'),
        totalPages: _requiredInt(json, 'totalPages'),
      );

  final List<AppNotification> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw const FormatException('Expected a JSON object.');
}

List<Object?> _list(Object? value) {
  if (value is List) return value.cast<Object?>();
  throw const FormatException('Expected a JSON list.');
}

String? _text(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

String _requiredText(Map<String, dynamic> json, String key) {
  final String? value = _text(json[key]);
  if (value == null) throw FormatException('Missing $key.');
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! num) throw FormatException('Missing $key.');
  return value.toInt();
}
