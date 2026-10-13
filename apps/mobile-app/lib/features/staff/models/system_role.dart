class SystemRole {
  final String role;
  final String description;

  /// What this role can do in this shop right now.
  final List<String> permissions;

  /// The platform default, used by "Reset to default".
  final List<String> defaultPermissions;

  /// The shop owner may change which modules this role gets.
  final bool editable;

  /// The owner has changed it from the default.
  final bool isCustomized;

  const SystemRole({
    required this.role,
    required this.description,
    required this.permissions,
    this.defaultPermissions = const <String>[],
    this.editable = false,
    this.isCustomized = false,
  });

  factory SystemRole.fromJson(Map<String, dynamic> json) {
    final List<String> permissions = (json['permissions'] as List).cast<String>();
    return SystemRole(
      role: json['role'] as String,
      description: json['description'] as String,
      permissions: permissions,
      defaultPermissions: json['defaultPermissions'] is List
          ? (json['defaultPermissions'] as List).cast<String>()
          : permissions,
      editable: json['editable'] as bool? ?? false,
      isCustomized: json['isCustomized'] as bool? ?? false,
    );
  }
}
