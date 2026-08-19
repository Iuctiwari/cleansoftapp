import 'package:nexoraa_mobile/features/orders/models/order.dart';

enum PaymentTransactionStatus {
  pending('Pending'),
  successful('Successful'),
  failed('Failed');

  const PaymentTransactionStatus(this.apiValue);

  final String apiValue;

  static PaymentTransactionStatus fromApi(String value) {
    for (final PaymentTransactionStatus status in values) {
      if (status.apiValue == value) return status;
    }
    throw FormatException('Unknown payment status: $value.');
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.paymentNumber,
    required this.method,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.customerName,
    this.orderNumber,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    id: _requiredText(json, 'id'),
    orderId: _requiredText(json, 'orderId'),
    customerId: _requiredText(json, 'customerId'),
    customerName: _text(json['customerName']),
    orderNumber: _text(json['orderNumber']),
    paymentNumber: _requiredText(json, 'paymentNumber'),
    method: PaymentMethod.fromApi(_requiredText(json, 'method')),
    amount: _requiredNumber(json, 'amountMinor') / 100,
    currency: _requiredText(json, 'currency'),
    status: PaymentTransactionStatus.fromApi(_requiredText(json, 'status')),
    createdAt: DateTime.parse(_requiredText(json, 'createdAt')),
  );

  final String id;
  final String orderId;
  final String customerId;
  final String? customerName;
  final String? orderNumber;
  final String paymentNumber;
  final PaymentMethod method;
  final double amount;
  final String currency;
  final PaymentTransactionStatus status;
  final DateTime createdAt;
}

class PaymentPage {
  const PaymentPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaymentPage.fromJson(Map<String, dynamic> json) => PaymentPage(
    items: _list(json['items'])
        .map((Object? item) => PaymentRecord.fromJson(_map(item)))
        .toList(growable: false),
    total: _requiredInt(json, 'total'),
    page: _requiredInt(json, 'page'),
    limit: _requiredInt(json, 'limit'),
    totalPages: _requiredInt(json, 'totalPages'),
  );

  final List<PaymentRecord> items;
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

double _requiredNumber(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! num) throw FormatException('Missing $key.');
  return value.toDouble();
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];
  if (value is! num) throw FormatException('Missing $key.');
  return value.toInt();
}
