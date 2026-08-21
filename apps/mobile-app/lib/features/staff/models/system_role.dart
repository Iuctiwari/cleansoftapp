class SystemRole {
  final String role;
  final String description;
  final List<String> permissions;

  const SystemRole({
    required this.role,
    required this.description,
    required this.permissions,
  });

  factory SystemRole.fromJson(Map<String, dynamic> json) {
    return SystemRole(
      role: json['role'] as String,
      description: json['description'] as String,
      permissions: (json['permissions'] as List).cast<String>(),
    );
  }
}
