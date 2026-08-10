class AuthenticationSession {
  const AuthenticationSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;
}

class AuthenticationException implements Exception {
  const AuthenticationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthenticationNetworkException extends AuthenticationException {
  const AuthenticationNetworkException()
    : super('Unable to connect. Check your internet connection and try again.');
}

class AuthenticationConfigurationException extends AuthenticationException {
  const AuthenticationConfigurationException(super.message);
}
