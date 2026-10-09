import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/core/push/firebase_push_platform.dart';
import 'package:nexoraa_mobile/core/push/push_api.dart';
import 'package:nexoraa_mobile/core/push/push_destination.dart';
import 'package:nexoraa_mobile/core/push/push_registrar.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';

/// Wiring for phone push notifications.
abstract final class PushDependencies {
  static Uri _notificationBaseUri() {
    String value = 'http://10.0.2.2:3005/api';
    if (dotenv.isInitialized) {
      final String? configured = dotenv.env['NOTIFICATION_API_BASE_URL']?.trim();
      if (configured != null && configured.isNotEmpty) value = configured;
    }
    return Uri.parse(BackendEnvironment.resolveBase(value, 'RENDER_NOTIFICATION_API_BASE_URL'));
  }

  static final PushRegistrar registrar = PushRegistrar(
    platform: FirebasePushPlatform(),
    api: PushApi(
      baseUri: _notificationBaseUri,
      authorization: (PushAccount account) async {
        if (account == PushAccount.shop) {
          final session = await AuthenticationDependencies.tokenStorage.read();
          return session == null ? null : 'Bearer ${session.accessToken}';
        }
        final session = await ConsumerDependencies.storage.read();
        return session == null ? null : 'Bearer ${session.accessToken}';
      },
      shopBranchId: () => AuthenticationDependencies.controller.session?.branchId,
    ),
    shopSession: AuthenticationDependencies.controller,
    shopSignedIn: () => AuthenticationDependencies.controller.isAuthenticated,
    consumerSession: ConsumerDependencies.controller,
    consumerSignedIn: () => ConsumerDependencies.controller.isAuthenticated,
    open: _open,
    pastSplash: () => AppRouter.router.routeInformationProvider.value.uri.path != AppRoutes.splash,
  );

  /// Starts pushes without delaying the app: call once, after the sessions are restored.
  static Future<void> start() async {
    AuthenticationDependencies.controller.beforeSignOut =
        () => registrar.unregister(PushAccount.shop);
    ConsumerDependencies.controller.beforeSignOut =
        () => registrar.unregister(PushAccount.consumer);
    await registrar.start();
  }

  static void _open(PushDestination destination) {
    final BuildContext? context = AppRouter.router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;
    context.pushNamed(
      destination.routeName,
      pathParameters: destination.pathParameters,
      extra: destination.extra,
    );
  }
}
