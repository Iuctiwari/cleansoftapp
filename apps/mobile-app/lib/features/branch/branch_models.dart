enum BranchStatus { active, inactive }

BranchStatus branchStatusFromJson(String value) {
  switch (value) {
    case 'inactive':
      return BranchStatus.inactive;
    case 'active':
    default:
      return BranchStatus.active;
  }
}

String branchStatusToJson(BranchStatus status) {
  switch (status) {
    case BranchStatus.active:
      return 'active';
    case BranchStatus.inactive:
      return 'inactive';
  }
}

/// Mirrors the backend's `BranchDto` (apps/backend/branch-service).
class Branch {
  const Branch({
    required this.branchId,
    required this.tenantId,
    required this.branchName,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.phone,
    required this.email,
    required this.isHeadOffice,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.openingTime,
    this.closingTime,
    this.managerId,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      branchId: _requiredString(json, 'branchId'),
      tenantId: _requiredString(json, 'tenantId'),
      branchName: _requiredString(json, 'branchName'),
      code: _optionalString(json, 'code'),
      streetAddress: json['streetAddress'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      openingTime: _optionalString(json, 'openingTime'),
      closingTime: _optionalString(json, 'closingTime'),
      managerId: _optionalString(json, 'managerId'),
      isHeadOffice: json['isHeadOffice'] as bool? ?? false,
      status: branchStatusFromJson(json['status'] as String? ?? 'active'),
      createdAt: _requiredString(json, 'createdAt'),
      updatedAt: _requiredString(json, 'updatedAt'),
    );
  }

  final String branchId;
  final String tenantId;
  final String branchName;
  final String? code;
  final String streetAddress;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final String phone;
  final String email;
  final String? openingTime;
  final String? closingTime;
  final String? managerId;
  final bool isHeadOffice;
  final BranchStatus status;
  final String createdAt;
  final String updatedAt;

  static String _requiredString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Branch response is missing $key');
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value is String && value.isNotEmpty) return value;
    return null;
  }
}

class BranchListResult {
  const BranchListResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<Branch> items;
  final int page;
  final int pageSize;
  final int total;
}

/// Fields the create-branch form collects, matching `CreateBranchDto`.
class CreateBranchInput {
  const CreateBranchInput({
    required this.branchName,
    required this.phone,
    required this.email,
    this.code,
    this.streetAddress,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.openingTime,
    this.closingTime,
    this.managerId,
  });

  final String branchName;
  final String phone;
  final String email;
  final String? code;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? openingTime;
  final String? closingTime;
  final String? managerId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'branchName': branchName,
      'phone': phone,
      'email': email,
      if (code != null) 'code': code,
      if (streetAddress != null) 'streetAddress': streetAddress,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (postalCode != null) 'postalCode': postalCode,
      if (openingTime != null) 'openingTime': openingTime,
      if (closingTime != null) 'closingTime': closingTime,
      if (managerId != null) 'managerId': managerId,
    };
  }
}

/// Fields the edit-branch form may submit, matching `UpdateBranchDto`.
///
/// [managerIdChanged] controls the manager patch: when false the key is
/// omitted, while true sends either `null` to unassign or a value to assign.
class UpdateBranchInput {
  const UpdateBranchInput({
    this.branchName,
    this.code,
    this.streetAddress,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.phone,
    this.email,
    this.openingTime,
    this.closingTime,
    this.status,
    this.managerId,
    this.managerIdChanged = false,
  });

  final String? branchName;
  final String? code;
  final String? streetAddress;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final String? phone;
  final String? email;
  final String? openingTime;
  final String? closingTime;
  final BranchStatus? status;
  final String? managerId;
  final bool managerIdChanged;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (branchName != null) 'branchName': branchName,
      if (code != null) 'code': code,
      if (streetAddress != null) 'streetAddress': streetAddress,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (postalCode != null) 'postalCode': postalCode,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (openingTime != null) 'openingTime': openingTime,
      if (closingTime != null) 'closingTime': closingTime,
      if (status != null) 'status': branchStatusToJson(status!),
      if (managerIdChanged) 'managerId': managerId,
    };
  }
}
