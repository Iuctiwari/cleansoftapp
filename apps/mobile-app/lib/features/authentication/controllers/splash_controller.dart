import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/controllers/authentication_controller.dart';

enum StartupDestination { dashboard, login }

final class SplashController {
  const SplashController({
    required AuthenticationController authenticationController,
    this.bypassAuthentication = false,
  }) : _authenticationController = authenticationController;

  final AuthenticationController _authenticationController;
  final bool bypassAuthentication;

  Future<StartupDestination> resolveDestination() async {
    await Future<void>.delayed(AppDurations.startupSplash);

    // TEMPORARY DEVELOPMENT / UI TESTING ONLY.
    // Show the login UI without reading authentication state.
    if (bypassAuthentication) return StartupDestination.login;

    return _authenticationController.isAuthenticated
        ? StartupDestination.dashboard
        : StartupDestination.login;
  }
}
