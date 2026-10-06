import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/consumer/controllers/consumer_session_controller.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_session_storage.dart';
import 'package:nexoraa_mobile/features/consumer/services/location_service.dart';

/// Wiring for the customer (marketplace) side of the app.
abstract final class ConsumerDependencies {
  static Uri authBaseUri() => Uri.parse(
    BackendEnvironment.resolveBase(
      _environment('API_BASE_URL', 'http://10.0.2.2:3001/api'),
      'RENDER_AUTH_API_BASE_URL',
    ),
  );

  static Uri marketplaceBaseUri() => Uri.parse(
    BackendEnvironment.resolveBase(
      _environment('MARKETPLACE_API_BASE_URL', 'http://10.0.2.2:3017/api'),
      'RENDER_MARKETPLACE_API_BASE_URL',
    ),
  );

  static ConsumerSessionStorage storage = SecureConsumerSessionStorage(authBaseUri: authBaseUri);

  static ConsumerApiService api = ConsumerApiService(
    authBaseUri: authBaseUri,
    marketplaceBaseUri: marketplaceBaseUri,
    storage: storage,
  );

  static ConsumerSessionController controller = ConsumerSessionController(
    api: api,
    storage: storage,
  );

  static LocationService location = const LocationService();

  static String _environment(String key, String fallback) {
    if (!dotenv.isInitialized) return fallback;
    final String? value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? fallback : value;
  }
}
