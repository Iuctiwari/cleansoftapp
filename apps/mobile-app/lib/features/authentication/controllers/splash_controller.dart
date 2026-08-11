import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/controllers/authentication_controller.dart';

enum StartupDestination { dashboard, login }

final class SplashController {
  const SplashController({
    required AuthenticationController authenticationController,
  }) : _authenticationController = authenticationController;

  final AuthenticationController _authenticationController;

  Future<StartupDestination> resolveDestination() async {
    await Future<void>.delayed(AppDurations.startupSplash);

    return _authenticationController.isAuthenticated
        ? StartupDestination.dashboard
        : StartupDestination.login;
  }
}
