import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nexoraa_mobile/features/authentication/controllers/authentication_controller.dart';
import 'package:nexoraa_mobile/features/authentication/services/api_authentication_service.dart';
import 'package:nexoraa_mobile/features/authentication/services/auth_token_storage.dart';
import 'package:nexoraa_mobile/features/authentication/services/authentication_service.dart';

abstract final class AuthenticationDependencies {
  // TEMPORARY DEVELOPMENT / UI TESTING ONLY.
  // Set this to false to restore the existing API-backed authentication flow.
  static const bool temporaryDevelopmentUiBypassEnabled = true;

  static final AuthTokenStorage tokenStorage = SecureAuthTokenStorage();

  static final AuthenticationService service = ApiAuthenticationService(
    apiBaseUri: Uri.parse(
      _environment('API_BASE_URL', 'http://localhost:3000/api'),
    ),
    loginContext: _environment('AUTH_LOGIN_CONTEXT', 'tenant'),
    tenantSlug: _optionalEnvironment('AUTH_TENANT_SLUG'),
    tokenStorage: tokenStorage,
  );

  static final AuthenticationController controller = AuthenticationController(
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
