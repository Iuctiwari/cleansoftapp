enum CustomerType {
  regular('Regular'),
  walkIn('Walk-in'),
  corporate('Corporate'),
  vip('VIP');

  const CustomerType(this.apiValue);
  final String apiValue;

  static CustomerType fromApi(String value) => values.firstWhere(
    (CustomerType type) => type.apiValue == value,
    orElse: () => CustomerType.regular,
  );
}

class Customer {
  const Customer({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.name,
    required this.customerType,
    required this.joiningDate,
    required this.totalOrders,
    required this.totalSpent,
    required this.outstandingBalance,
    required this.createdAt,
    required this.updatedAt,
    this.mobile,
    this.email,
    this.address,
    this.lastOrderDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
    id: json['id'] as String,
    tenantId: json['tenantId'] as String,
    branchId: json['branchId'] as String,
    name: json['name'] as String,
    mobile: json['mobile'] as String?,
    email: json['email'] as String?,
    address: json['address'] as String?,
    customerType: CustomerType.fromApi(json['customerType'] as String),
    joiningDate: DateTime.parse(json['joiningDate'] as String),
    totalOrders: (json['totalOrders'] as num).toInt(),
    totalSpent: (json['totalSpent'] as num).toDouble(),
    outstandingBalance: (json['outstandingBalance'] as num).toDouble(),
    lastOrderDate: json['lastOrderDate'] == null
        ? null
        : DateTime.parse(json['lastOrderDate'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  final String id;
  final String tenantId;
  final String branchId;
  final String name;
  final String? mobile;
  final String? email;
  final String? address;
  final CustomerType customerType;
  final DateTime joiningDate;
  final int totalOrders;
  final double totalSpent;
  final double outstandingBalance;
  final DateTime? lastOrderDate;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class CustomerPage {
  const CustomerPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<Customer> items;
  final int total;
  final int page;
  final int limit;
}

class CustomerStatistics {
  const CustomerStatistics({
    required this.total,
    required this.active,
    required this.outstanding,
  });

  factory CustomerStatistics.fromJson(Map<String, dynamic> json) =>
      CustomerStatistics(
        total: (json['total'] as num).toInt(),
        active: (json['active'] as num).toInt(),
        outstanding: (json['outstanding'] as num).toDouble(),
      );

  final int total;
  final int active;
  final double outstanding;
}

class CustomerDraft {
  const CustomerDraft({
    required this.name,
    required this.customerType,
    this.mobile,
    this.email,
    this.address,
    this.joiningDate,
  });

  final String name;
  final String? mobile;
  final String? email;
  final String? address;
  final CustomerType customerType;
  final DateTime? joiningDate;

  Map<String, Object?> toJson({bool clearEmptyOptional = false}) =>
      <String, Object?>{
        'name': name.trim(),
        if (mobile?.trim().isNotEmpty ?? false)
          'mobile': mobile!.trim()
        else if (clearEmptyOptional)
          'mobile': null,
        if (email?.trim().isNotEmpty ?? false)
          'email': email!.trim()
        else if (clearEmptyOptional)
          'email': null,
        if (address?.trim().isNotEmpty ?? false)
          'address': address!.trim()
        else if (clearEmptyOptional)
          'address': null,
        'customerType': customerType.apiValue,
        if (joiningDate != null)
          'joiningDate': joiningDate!.toIso8601String().split('T').first,
      };
}
