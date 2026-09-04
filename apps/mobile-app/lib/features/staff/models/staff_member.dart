class StaffMember {
  final String id;
  final String tenantId;
  final String email;
  final String phone;
  final String status;
  final String availability;
  final String role;
  final List<String> branches;
  final String? firstName;
  final String? lastName;
  final String? departmentValue;

  /// The unique login username set by the owner at registration. Read-only.
  final String loginId;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffMember({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.phone,
    required this.status,
    this.availability = 'Available',
    required this.role,
    required this.branches,
    this.firstName,
    this.lastName,
    this.departmentValue,
    required this.loginId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['userId'] as String? ?? json['id'] as String? ?? '',
      tenantId: json['tenantId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['mobileNumber'] as String? ?? json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'Active',
      availability: json['availability'] as String? ?? 'Available',
      role: json['role'] as String? ?? 'Staff',
      branches: List<String>.from(json['branchIds'] ?? json['branches'] ?? []),
      firstName:
          json['name'] as String? ?? json['profile']?['firstName'] as String?,
      lastName: json['profile']?['lastName'] as String?,
      departmentValue: json['department'] as String?,
      loginId: json['loginId'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String get fullName =>
      [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
  String get displayName => fullName.isNotEmpty ? fullName : email;
  String get mobileNumber => phone;
  String get department => departmentValue ?? '';
}

class StaffStatistics {
  const StaffStatistics({
    required this.totalStaff,
    required this.activeStaff,
    required this.inactiveStaff,
  });

  final int totalStaff;
  final int activeStaff;
  final int inactiveStaff;

  factory StaffStatistics.fromJson(Map<String, dynamic> json) =>
      StaffStatistics(
        totalStaff: json['totalStaff'] as int? ?? 0,
        activeStaff: json['activeStaff'] as int? ?? 0,
        inactiveStaff: json['inactiveStaff'] as int? ?? 0,
      );
}
