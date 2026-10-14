enum OrderStatus {
  draft('Draft'),
  received('Received'),
  assigned('Assigned'),
  accepted('Accepted'),
  rejected('Rejected'),
  inProgress('InProgress'),
  ready('Ready'),
  outForDelivery('OutForDelivery'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderStatus(this.apiValue);

  final String apiValue;

  static OrderStatus fromApi(String value) {
    for (final OrderStatus status in values) {
      if (status.apiValue == value) return status;
    }
    throw FormatException('Unknown order status: $value.');
  }

  String get label => switch (this) {
    OrderStatus.inProgress => 'Processing',
    OrderStatus.outForDelivery => 'Out for delivery',
    _ => apiValue,
  };
}

enum OrderPaymentStatus {
  unpaid('Unpaid'),
  pending('Pending'),
  partiallyPaid('PartiallyPaid'),
  paid('Paid'),
  partiallyRefunded('PartiallyRefunded'),
  refunded('Refunded');

  const OrderPaymentStatus(this.apiValue);

  final String apiValue;

  static OrderPaymentStatus fromApi(String value) {
    for (final OrderPaymentStatus status in values) {
      if (status.apiValue == value) return status;
    }
    throw FormatException('Unknown payment status: $value.');
  }

  String get label => switch (this) {
    OrderPaymentStatus.partiallyPaid => 'Partially paid',
    OrderPaymentStatus.partiallyRefunded => 'Partially refunded',
    _ => apiValue,
  };
}

enum PaymentMethod {
  cash('Cash'),
  card('Card'),
  upi('UPI');

  const PaymentMethod(this.apiValue);
  final String apiValue;

  static PaymentMethod fromApi(String value) {
    for (final PaymentMethod method in values) {
      if (method.apiValue == value) return method;
    }
    throw FormatException('Unknown payment method: $value.');
  }
}

enum OrderListFilter {
  all('All', null),
  pending('Pending', OrderStatus.received),
  processing('Processing', OrderStatus.inProgress),
  ready('Ready', OrderStatus.ready),
  completed('Completed', OrderStatus.delivered);

  const OrderListFilter(this.label, this.status);

  final String label;
  final OrderStatus? status;
}

class OrderCustomerSnapshot {
  const OrderCustomerSnapshot({
    required this.name,
    this.mobile,
    this.email,
    this.address,
    this.customerType,
  });

  factory OrderCustomerSnapshot.fromJson(Map<String, dynamic> json) =>
      OrderCustomerSnapshot(
        name: _text(json['name']) ?? 'Customer',
        mobile: _text(json['mobile']),
        email: _text(json['email']),
        address: _text(json['address']),
        customerType: _text(json['customerType']),
      );

  final String name;
  final String? mobile;
  final String? email;
  final String? address;
  final String? customerType;
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.itemCategoryId,
    required this.itemCategoryName,
    required this.serviceId,
    required this.serviceName,
    required this.unitPrice,
    required this.discount,
    required this.tax,
    required this.lineTotal,
    this.quantity,
    this.weight,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> category = _map(json['itemCategorySnapshot']);
    final Map<String, dynamic> service = _map(json['serviceSnapshot']);
    return OrderItem(
      id: _text(json['id']) ?? '',
      itemCategoryId: _text(json['itemCategoryId']) ?? '',
      itemCategoryName: _text(category['name']) ?? 'Item',
      serviceId: _text(json['serviceId']) ?? '',
      serviceName: _text(service['name']) ?? 'Service',
      quantity: _number(json['quantity']),
      weight: _number(json['weight']),
      unitPrice: _number(json['unitPrice']) ?? 0,
      discount: _number(json['discount']) ?? 0,
      tax: _number(json['tax']) ?? 0,
      lineTotal: _number(json['lineTotal']) ?? 0,
      notes: _text(json['notes']),
    );
  }

  final String id;
  final String itemCategoryId;
  final String itemCategoryName;
  final String serviceId;
  final String serviceName;
  final double? quantity;
  final double? weight;
  final double unitPrice;
  final double discount;
  final double tax;
  final double lineTotal;
  final String? notes;

  String get measurement {
    if (weight != null) return '${_compactNumber(weight!)} kg';
    if (quantity != null) return _compactNumber(quantity!);
    return '';
  }
}

class OrderAssignment {
  const OrderAssignment({
    required this.id,
    required this.assignedTo,
    required this.assignedBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.note,
  });

  factory OrderAssignment.fromJson(Map<String, dynamic> json) =>
      OrderAssignment(
        id: _requiredText(json, 'id'),
        assignedTo: _requiredText(json, 'assignedTo'),
        assignedBy: _requiredText(json, 'assignedBy'),
        status: _requiredText(json, 'status'),
        dueDate: _date(json['dueDate']),
        note: _text(json['note']),
        createdAt: DateTime.parse(_requiredText(json, 'createdAt')),
        updatedAt: DateTime.parse(_requiredText(json, 'updatedAt')),
      );

  final String id;
  final String assignedTo;
  final String assignedBy;
  final String status;
  final DateTime? dueDate;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class OrderStatusHistory {
  const OrderStatusHistory({
    required this.id,
    required this.orderId,
    required this.previousStatus,
    required this.newStatus,
    required this.changedBy,
    required this.timestamp,
    this.note,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) =>
      OrderStatusHistory(
        id: _requiredText(json, 'id'),
        orderId: _requiredText(json, 'orderId'),
        previousStatus: OrderStatus.fromApi(
          _requiredText(json, 'previousStatus'),
        ),
        newStatus: OrderStatus.fromApi(_requiredText(json, 'newStatus')),
        changedBy: _requiredText(json, 'changedBy'),
        note: _text(json['note']),
        timestamp: DateTime.parse(_requiredText(json, 'timestamp')),
      );

  final String id;
  final String orderId;
  final OrderStatus previousStatus;
  final OrderStatus newStatus;
  final String changedBy;
  final String? note;
  final DateTime timestamp;
}

class Order {
  const Order({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.orderNumber,
    required this.customerId,
    required this.customer,
    required this.status,
    required this.paymentStatus,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.discountPercentage,
    required this.tax,
    required this.grandTotal,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.createdAt,
    required this.updatedAt,
    this.expectedDeliveryDate,
    this.deliveryDate,
    this.assignedTo,
    this.assignment,
    this.createdBy,
    this.paymentMethod,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: _requiredText(json, 'id'),
    tenantId: _requiredText(json, 'tenantId'),
    branchId: _requiredText(json, 'branchId'),
    orderNumber: _requiredText(json, 'orderNumber'),
    customerId: _requiredText(json, 'customerId'),
    customer: OrderCustomerSnapshot.fromJson(_map(json['customerSnapshot'])),
    status: OrderStatus.fromApi(_requiredText(json, 'status')),
    paymentStatus: OrderPaymentStatus.fromApi(
      _requiredText(json, 'paymentStatus'),
    ),
    items: _list(json['items'])
        .map((Object? item) => OrderItem.fromJson(_map(item)))
        .toList(growable: false),
    subtotal: _requiredNumber(json, 'subtotal'),
    discount: _requiredNumber(json, 'discount'),
    discountPercentage: _number(json['discountPercentage']) ?? 0,
    tax: _requiredNumber(json, 'tax'),
    grandTotal: _requiredNumber(json, 'grandTotal'),
    paidAmount: _requiredNumber(json, 'paidAmount'),
    outstandingAmount: _requiredNumber(json, 'outstandingAmount'),
    expectedDeliveryDate: _date(json['expectedDeliveryDate']),
    deliveryDate: _date(json['deliveryDate']),
    assignedTo: _text(json['assignedTo']),
    assignment: json['assignment'] == null
        ? null
        : OrderAssignment.fromJson(_map(json['assignment'])),
    createdBy: _text(json['createdBy']),
    createdAt: DateTime.parse(_requiredText(json, 'createdAt')),
    updatedAt: DateTime.parse(_requiredText(json, 'updatedAt')),
    paymentMethod: _text(json['paymentMethod']),
  );

  final String id;
  final String tenantId;
  final String branchId;
  final String orderNumber;
  final String customerId;
  final OrderCustomerSnapshot customer;
  final OrderStatus status;
  final OrderPaymentStatus paymentStatus;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double discountPercentage;
  final double tax;
  final double grandTotal;
  final double paidAmount;
  final double outstandingAmount;
  final DateTime? expectedDeliveryDate;
  final DateTime? deliveryDate;
  final String? assignedTo;
  final OrderAssignment? assignment;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paymentMethod;
}

class OrderPage {
  const OrderPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory OrderPage.fromJson(Map<String, dynamic> json) => OrderPage(
    items: _list(
      json['items'],
    ).map((Object? item) => Order.fromJson(_map(item))).toList(growable: false),
    total: _requiredInt(json, 'total'),
    page: _requiredInt(json, 'page'),
    limit: _requiredInt(json, 'limit'),
    totalPages: _requiredInt(json, 'totalPages'),
  );

  final List<Order> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
}

class OrderStatistics {
  const OrderStatistics({
    required this.totalOrders,
    required this.todayOrders,
    required this.yesterdayOrders,
    required this.outstandingTotal,
    required this.outstandingCustomerCount,
    required this.statusBreakdown,
  });

  factory OrderStatistics.fromJson(Map<String, dynamic> json) =>
      OrderStatistics(
        totalOrders: _requiredInt(json, 'totalOrders'),
        todayOrders: _requiredInt(json, 'todayOrders'),
        yesterdayOrders: _requiredInt(json, 'yesterdayOrders'),
        outstandingTotal: _requiredNumber(json, 'outstandingTotal'),
        outstandingCustomerCount: _requiredInt(
          json,
          'outstandingCustomerCount',
        ),
        statusBreakdown: _map(
          json['statusBreakdown'],
        ).map((key, value) => MapEntry(key, value is num ? value.toInt() : 0)),
      );

  final int totalOrders;
  final int todayOrders;
  final int yesterdayOrders;
  final double outstandingTotal;
  final int outstandingCustomerCount;
  final Map<String, int> statusBreakdown;

  int count(OrderStatus status) => statusBreakdown[status.apiValue] ?? 0;
}

class CreateOrderItemInput {
  const CreateOrderItemInput({
    required this.itemCategoryId,
    required this.serviceId,
    this.quantity,
    this.weight,
    this.discount = 0,
    this.notes,
    this.standalonePrice = false,
  });

  final String itemCategoryId;
  final String serviceId;
  final double? quantity;
  final double? weight;
  final double discount;
  final String? notes;

  /// Salon lines: charge the full catalog price (no laundry additional-service surcharge).
  final bool standalonePrice;

  Map<String, Object?> toJson() => <String, Object?>{
    'itemCategoryId': itemCategoryId,
    'serviceId': serviceId,
    if (quantity != null) 'quantity': quantity,
    if (weight != null) 'weight': weight,
    if (discount > 0) 'discount': discount,
    if (notes?.trim().isNotEmpty ?? false) 'notes': notes!.trim(),
    if (standalonePrice) 'standalonePrice': true,
  };
}

class CreateOrderInput {
  const CreateOrderInput({
    required this.customerId,
    required this.items,
    this.discountPercentage = 0,
    this.expectedDeliveryDate,
  });

  final String customerId;
  final List<CreateOrderItemInput> items;
  final double discountPercentage;
  final DateTime? expectedDeliveryDate;

  Map<String, Object?> toJson() => <String, Object?>{
    'customerId': customerId,
    'items': items
        .map((CreateOrderItemInput item) => item.toJson())
        .toList(growable: false),
    if (discountPercentage > 0) 'discountPercentage': discountPercentage,
    if (expectedDeliveryDate != null)
      'expectedDeliveryDate': expectedDeliveryDate!.toUtc().toIso8601String(),
  };
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

double? _number(Object? value) => value is num ? value.toDouble() : null;

double _requiredNumber(Map<String, dynamic> json, String key) {
  final double? value = _number(json[key]);
  if (value == null) throw FormatException('Missing $key.');
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! num) throw FormatException('Missing $key.');
  return value.toInt();
}

DateTime? _date(Object? value) {
  final String? text = _text(value);
  return text == null ? null : DateTime.tryParse(text);
}

String _compactNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
