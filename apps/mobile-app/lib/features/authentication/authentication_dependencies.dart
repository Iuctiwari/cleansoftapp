import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/authentication/controllers/authentication_controller.dart';
import 'package:nexoraa_mobile/features/authentication/services/api_authentication_service.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/authentication/services/authentication_service.dart';

abstract final class AuthenticationDependencies {
  static AuthTokenStorage tokenStorage = SecureAuthTokenStorage();

  static AuthenticationService service = ApiAuthenticationService(
    apiBaseUri: Uri.parse(
      BackendEnvironment.resolveBase(
        _environment('API_BASE_URL', 'http://127.0.0.1:3000/api'),
      ),
    ),
    loginContext: _environment('AUTH_LOGIN_CONTEXT', 'tenant'),
    tenantSlug: _environment('AUTH_TENANT_SLUG', 'nexoraa-admin'),
    tokenStorage: tokenStorage,
  );

  static AuthenticationController controller = AuthenticationController(
    service: service,
  );

  static String _environment(String key, String fallback) {
    return _optionalEnvironment(key) ?? fallback;
  }

  static String? _optionalEnvironment(String key) {
    if (!dotenv.isInitialized) return null;
    final String? value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
