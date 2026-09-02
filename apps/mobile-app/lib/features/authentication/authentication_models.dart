class AuthenticationSession {
  const AuthenticationSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
    this.tenantId,
    this.tenantSlug,
    this.ownerUserId,
    this.ownerName,
    this.ownerEmail,
    this.businessName,
    this.branchId,
    this.branchName,
    this.roleCode = 'tenant_owner',
    this.permissions = const <String>[],
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
  final String? tenantId;
  final String? tenantSlug;
  final String? ownerUserId;
  final String? ownerName;
  final String? ownerEmail;
  final String? businessName;
  final String? branchId;
  final String? branchName;
  final String roleCode;
  final List<String> permissions;
}

class AuthenticationException implements Exception {
  const AuthenticationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthenticationNetworkException extends AuthenticationException {
  const AuthenticationNetworkException() : super('Enable internet connection');
}

class AuthenticationConfigurationException extends AuthenticationException {
  const AuthenticationConfigurationException(super.message);
}
