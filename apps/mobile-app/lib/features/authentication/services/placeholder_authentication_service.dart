import 'package:nexoraa_mobile/features/authentication/services/authentication_service.dart';

/// Frontend-only authentication placeholder.
///
/// This intentionally performs no storage, network, token, or backend work.
final class PlaceholderAuthenticationService implements AuthenticationService {
  const PlaceholderAuthenticationService();

  @override
  Future<bool> isAuthenticated() async => false;
}
