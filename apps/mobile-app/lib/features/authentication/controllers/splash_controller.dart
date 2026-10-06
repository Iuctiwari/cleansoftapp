import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/controllers/authentication_controller.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/subscription/services/subscription_api_service.dart';

enum StartupDestination { dashboard, login, choosePlan, welcome, consumerHome }

final class SplashController {
  SplashController({
    required AuthenticationController authenticationController,
    SubscriptionApiService? subscriptionApiService,
  }) : _authenticationController = authenticationController,
       _subscriptionApiService = subscriptionApiService ?? SubscriptionApiService();

  final AuthenticationController _authenticationController;
  final SubscriptionApiService _subscriptionApiService;

  Future<StartupDestination> resolveDestination() async {
    await Future<void>.delayed(AppDurations.startupSplash);

    if (!_authenticationController.isAuthenticated) {
      return ConsumerDependencies.controller.isAuthenticated
          ? StartupDestination.consumerHome
          : StartupDestination.welcome;
    }

    // Only an Owner ever chooses a plan — staff/cashier/branch-manager
    // sessions proceed to their normal destination regardless of whether
    // the tenant has a subscription yet, exactly as before this check
    // existed. A subscription-status lookup failure (network, service
    // down) must never block a returning user from reaching their
    // dashboard — only an explicit "no subscription" response redirects.
    final String? roleCode = _authenticationController.session?.roleCode;
    if (roleCode != 'tenant_owner' && roleCode != 'Owner') {
      return StartupDestination.dashboard;
    }

    try {
      final bool hasSubscription = (await _subscriptionApiService.getStatus()).hasSubscription;
      if (!hasSubscription) return StartupDestination.choosePlan;
    } on Object {
      // Fail open — see doc comment above.
    }

    return StartupDestination.dashboard;
  }
}
