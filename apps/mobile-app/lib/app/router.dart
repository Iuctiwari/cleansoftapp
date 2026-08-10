import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/screens/login_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/forgot_password_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/splash_screen.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard.dart';

import '../features/auth/models/registration_form.dart';
import '../features/auth/pages/account_created_page.dart';
import '../features/auth/pages/account_details_page.dart';
import '../features/auth/pages/business_info_page.dart';
import '../features/auth/pages/sign_in_page.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String registerBusinessInfo = '/register/business-info';
  static const String registerAccountDetails = '/register/account-details';
  static const String registerSuccess = '/register/success';
  static const String forgotPassword = '/forgot-password';
  static const String notifications = '/dashboard/notifications';
}

abstract final class AppRouteNames {
  static const String splash = 'splash';
  static const String login = 'login';
  static const String dashboard = 'dashboard';
  static const String registerBusinessInfo = 'registerBusinessInfo';
  static const String registerAccountDetails = 'registerAccountDetails';
  static const String registerSuccess = 'registerSuccess';
  static const String forgotPassword = 'forgot-password';
  static const String notifications = 'notifications';
}

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: AuthenticationDependencies.controller,
    redirect: (BuildContext context, GoRouterState state) {
      // TEMPORARY DEVELOPMENT / UI TESTING ONLY.
      // Do not execute authentication route guards while the bypass is enabled.
      if (AuthenticationDependencies.temporaryDevelopmentUiBypassEnabled) {
        return null;
      }

      final bool authenticated =
          AuthenticationDependencies.controller.isAuthenticated;
      final bool openingDashboard =
          state.matchedLocation == AppRoutes.dashboard;
      final bool openingLogin = state.matchedLocation == AppRoutes.login;

      if (openingDashboard && !authenticated) return AppRoutes.login;
      if (openingLogin && authenticated) return AppRoutes.dashboard;
      return null;
    },
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
    return _fadePage<void>(
      state: state,
      child: const LoginScreen(),
    );
  },
),
      GoRoute(
        name: AppRouteNames.forgotPassword,
        path: AppRoutes.forgotPassword,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(
            state: state,
            child: const ForgotPasswordScreen(),
          );
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
      GoRoute(
        name: AppRouteNames.registerBusinessInfo,
        path: AppRoutes.registerBusinessInfo,
        builder: (context, state) {
          final form = state.extra as RegistrationForm? ?? RegistrationForm();
          return BusinessInfoPage(form: form);
        },
      ),
      GoRoute(
        name: AppRouteNames.registerAccountDetails,
        path: AppRoutes.registerAccountDetails,
        builder: (context, state) {
          final form = state.extra as RegistrationForm? ?? RegistrationForm();
          return AccountDetailsPage(form: form);
        },
      ),
      GoRoute(
        name: AppRouteNames.registerSuccess,
        path: AppRoutes.registerSuccess,
        builder: (context, state) {
          final businessName = state.extra as String? ?? 'Your Business';
          return AccountCreatedPage(businessName: businessName);
        },
      ),
      GoRoute(
        name: AppRouteNames.notifications,
        path: AppRoutes.notifications,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(
            state: state,
            child: const NotificationScreen(),
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
