import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/services/authentication_service.dart';

enum StartupDestination { dashboard, login }

final class SplashController {
  const SplashController({required AuthenticationService authenticationService})
    : _authenticationService = authenticationService;

  final AuthenticationService _authenticationService;

  Future<StartupDestination> resolveDestination() async {
    await Future<void>.delayed(AppDurations.startupSplash);
    final bool isAuthenticated = await _authenticationService.isAuthenticated();

    return isAuthenticated
        ? StartupDestination.dashboard
        : StartupDestination.login;
  }
}
