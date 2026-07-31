import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
}

abstract final class AppRouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String dashboard = 'dashboard';
}

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        name: AppRouteNames.splash,
        path: AppRoutes.splash,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(state: state, child: const SplashScreen());
        },
      ),
      GoRoute(
        name: AppRouteNames.login,
        path: AppRoutes.login,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(state: state, child: const LoginScreen());
        },
      ),
      GoRoute(
        name: AppRouteNames.dashboard,
        path: AppRoutes.dashboard,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(
            state: state,
            child: const DashboardPlaceholderScreen(),
          );
        },
      ),
    ],
  );

  static CustomTransitionPage<T> _fadePage<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      transitionDuration: AppDurations.fast,
      child: child,
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            return FadeTransition(opacity: animation, child: child);
          },
    );
  }
}
