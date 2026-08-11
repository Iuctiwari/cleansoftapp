import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/screens/login_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/forgot_password_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/splash_screen.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard.dart';

import '../features/tenant/models/registration_form.dart';
import '../features/tenant/models/tenant_onboarding_data.dart';
import '../features/tenant/screens/account_created.screen.dart';
import '../features/tenant/screens/account_details.screen.dart';
import '../features/tenant/screens/all_set.screen.dart';
import '../features/tenant/screens/business_info.screen.dart';
import '../features/tenant/screens/first_branch.screen.dart';
import '../features/tenant/screens/invite_staff.screen.dart';
import '../features/tenant/screens/services.screen.dart';

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String registerBusinessInfo = '/register/business-info';
  static const String registerAccountDetails = '/register/account-details';
  static const String registerSuccess = '/register/success';
  static const String onboardingFirstBranch = '/onboarding/first-branch';
  static const String onboardingServices = '/onboarding/services';
  static const String onboardingInviteStaff = '/onboarding/invite-staff';
  static const String onboardingAllSet = '/onboarding/all-set';
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
  static const String onboardingFirstBranch = 'onboardingFirstBranch';
  static const String onboardingServices = 'onboardingServices';
  static const String onboardingInviteStaff = 'onboardingInviteStaff';
  static const String onboardingAllSet = 'onboardingAllSet';
  static const String forgotPassword = 'forgot-password';
  static const String notifications = 'notifications';
}

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: AuthenticationDependencies.controller,
    redirect: (BuildContext context, GoRouterState state) {
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
          return _fadePage<void>(state: state, child: const LoginScreen());
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
          final onboardingData = state.extra is TenantOnboardingData
              ? state.extra! as TenantOnboardingData
              : null;
          return _fadePage<void>(
            state: state,
            child: DashboardPlaceholderScreen(
              tenantId:
                  onboardingData?.tenantId ??
                  AuthenticationDependencies.controller.session?.tenantId,
            ),
          );
        },
      ),
      GoRoute(
        name: AppRouteNames.registerBusinessInfo,
        path: AppRoutes.registerBusinessInfo,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is TenantOnboardingData) {
            return BusinessInfoPage(
              form: extra.registrationForm,
              onboardingData: extra,
            );
          }
          final form = _registrationFormFromExtra(extra);
          return BusinessInfoPage(form: form);
        },
      ),
      GoRoute(
        name: AppRouteNames.registerAccountDetails,
        path: AppRoutes.registerAccountDetails,
        builder: (context, state) {
          final form = _registrationFormFromExtra(state.extra);
          return AccountDetailsPage(form: form);
        },
      ),
      GoRoute(
        name: AppRouteNames.registerSuccess,
        path: AppRoutes.registerSuccess,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is TenantOnboardingData) {
            return AccountCreatedPage(
              businessName: extra.registrationForm.businessName,
              onboardingData: extra,
            );
          }
          final businessName = state.extra as String? ?? 'Your Business';
          return AccountCreatedPage(businessName: businessName);
        },
      ),
      GoRoute(
        name: AppRouteNames.onboardingFirstBranch,
        path: AppRoutes.onboardingFirstBranch,
        builder: (context, state) {
          final data = state.extra as TenantOnboardingData;
          return FirstBranchScreen(data: data);
        },
      ),
      GoRoute(
        name: AppRouteNames.onboardingServices,
        path: AppRoutes.onboardingServices,
        builder: (context, state) {
          final data = state.extra as TenantOnboardingData;
          return ServicesScreen(data: data);
        },
      ),
      GoRoute(
        name: AppRouteNames.onboardingInviteStaff,
        path: AppRoutes.onboardingInviteStaff,
        builder: (context, state) {
          final data = state.extra as TenantOnboardingData;
          return InviteStaffScreen(data: data);
        },
      ),
      GoRoute(
        name: AppRouteNames.onboardingAllSet,
        path: AppRoutes.onboardingAllSet,
        builder: (context, state) {
          final data = state.extra as TenantOnboardingData;
          return AllSetScreen(data: data);
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

  static RegistrationForm _registrationFormFromExtra(Object? extra) {
    if (extra is RegistrationForm) return extra;
    if (extra is Map<String, dynamic>) {
      return RegistrationForm.fromJson(extra);
    }
    return RegistrationForm();
  }

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
