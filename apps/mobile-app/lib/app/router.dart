import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/screens/forgot_password_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/login_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/splash_screen.dart';
import 'package:nexoraa_mobile/features/branch/branch.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard.dart';
import 'package:nexoraa_mobile/features/notifications/notifications.dart';
import 'package:nexoraa_mobile/features/profile/screens/profile_screen.dart';
import 'package:nexoraa_mobile/features/settings/settings.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/screens/edit_staff_screen.dart';
import 'package:nexoraa_mobile/features/staff/screens/register_staff_screen.dart';
import 'package:nexoraa_mobile/features/staff/screens/staff_management_screen.dart';
import 'package:nexoraa_mobile/features/staff/screens/view_staff_profile_screen.dart';
import 'package:nexoraa_mobile/features/staff/screens/edit_staff_screen.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/profile/screens/edit_profile_screen.dart';

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
  static const String branchList = '/dashboard/branches';
  static const String branchAdd = '/dashboard/branches/add';
  static const String branchEdit = '/dashboard/branches/:branchId/edit';
  static const String branchDetails = '/dashboard/branches/:branchId';
  static const String staffList = '/dashboard/staff';
  static const String staffRegister = '/dashboard/staff/register';
  static const String staffViewProfile = '/dashboard/staff/:staffId';
  static const String staffEdit = '/dashboard/staff/:staffId/edit';
  static const String profile = '/dashboard/profile';
  static const String profileEdit = '/dashboard/profile/edit';
  static const String businessSettings = '/dashboard/business-settings';
  static const String rolesAndStaff = '/dashboard/roles-and-staff';
  static const String staffDashboard = '/staff-dashboard';
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
  static const String branchList = 'branchList';
  static const String branchAdd = 'branchAdd';
  static const String branchEdit = 'branchEdit';
  static const String branchDetails = 'branchDetails';
  static const String profile = 'profile';
  static const String businessSettings = 'businessSettings';
  static const String rolesAndStaff = 'rolesAndStaff';
  static const String staffList = 'staffList';
  static const String staffRegister = 'staffRegister';
  static const String staffViewProfile = 'staffViewProfile';
  static const String staffEdit = 'staffEdit';
  static const String profileEdit = 'profileEdit';
  static const String staffDashboard = 'staffDashboard';
}

abstract final class AppRouter {
  static String dashboardLocationForRole(
    String? roleCode,
  ) => switch (roleCode) {
    'Staff' || 'staff' => AppRoutes.staffDashboard,
    'Branch Manager' || 'branch_manager' => AppRoutes.staffDashboard,
    'Owner' => AppRoutes.dashboard,
    // No Cashier dashboard is currently implemented, so preserve its existing
    // destination instead of assigning it another role's dashboard.
    'Cashier' => AppRoutes.dashboard,
    _ => AppRoutes.dashboard,
  };

  static RoleDashboardKind? roleDashboardKindForRole(String? roleCode) =>
      switch (roleCode) {
        'Staff' || 'staff' => RoleDashboardKind.staff,
        'Branch Manager' || 'branch_manager' => RoleDashboardKind.branchManager,
        _ => null,
      };

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: AuthenticationDependencies.controller,
    redirect: (BuildContext context, GoRouterState state) {
      final bool authenticated =
          AuthenticationDependencies.controller.isAuthenticated;
      final String? role =
          AuthenticationDependencies.controller.session?.roleCode;
      final AccessPolicy accessPolicy = AccessPolicy.fromSession(
        AuthenticationDependencies.controller.session,
      );

      final bool openingDashboard =
          state.matchedLocation == AppRoutes.dashboard;
      final bool openingLogin = state.matchedLocation == AppRoutes.login;
      final bool openingStaffDashboard =
          state.matchedLocation == AppRoutes.staffDashboard;
      final bool openingProtectedArea =
          state.matchedLocation.startsWith('/dashboard') ||
          openingStaffDashboard;

      if (!authenticated && openingProtectedArea) {
        return AppRoutes.login;
      }

      if (authenticated) {
        final bool isRoleDashboard =
            dashboardLocationForRole(role) == AppRoutes.staffDashboard;

        if (openingLogin) {
          return isRoleDashboard
              ? AppRoutes.staffDashboard
              : AppRoutes.dashboard;
        }

        if (openingDashboard && isRoleDashboard) {
          return AppRoutes.staffDashboard;
        }

        if (openingStaffDashboard && !isRoleDashboard) {
          return AppRoutes.dashboard;
        }

        final bool permitted = switch (state.name) {
          AppRouteNames.branchList || AppRouteNames.branchDetails =>
            accessPolicy.allows(AppCapability.branchesView),
          AppRouteNames.branchEdit => accessPolicy.allows(
            AppCapability.branchesEdit,
          ),
          AppRouteNames.branchAdd => accessPolicy.isOwner,
          AppRouteNames.staffList || AppRouteNames.staffViewProfile =>
            accessPolicy.allows(AppCapability.staffView),
          AppRouteNames.staffRegister || AppRouteNames.staffEdit =>
            accessPolicy.allows(AppCapability.staffManage),
          AppRouteNames.notifications => accessPolicy.allows(
            AppCapability.notificationsView,
          ),
          AppRouteNames.profile => accessPolicy.allows(
            AppCapability.ownProfile,
          ),
          AppRouteNames.businessSettings || AppRouteNames.rolesAndStaff =>
            accessPolicy.allows(AppCapability.businessSettings),
          _ => true,
        };
        if (!permitted) return dashboardLocationForRole(role);
      }

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
        name: AppRouteNames.staffDashboard,
        path: AppRoutes.staffDashboard,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String? role =
              AuthenticationDependencies.controller.session?.roleCode;
          return _fadePage<void>(
            state: state,
            child: RoleDashboardScreen(
              kind: roleDashboardKindForRole(role) ?? RoleDashboardKind.staff,
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
          final Object? extra = state.extra;
          final session = AuthenticationDependencies.controller.session;
          final AccessPolicy accessPolicy = AccessPolicy.fromSession(session);
          return _fadePage<void>(
            state: state,
            child: NotificationScreen(
              branchId: extra is String
                  ? extra
                  : accessPolicy.isBranchManager
                  ? session?.branchId
                  : null,
              // Dashboard passes its app-wide, already-connected controller
              // here so the panel shows live data instead of opening a
              // second, screen-scoped WebSocket connection.
              controller: extra is NotificationController ? extra : null,
            ),
          );
        },
      ),
      GoRoute(
        name: AppRouteNames.branchList,
        path: AppRoutes.branchList,
        builder: (BuildContext context, GoRouterState state) {
          return const BranchListScreen();
        },
      ),
      GoRoute(
        name: AppRouteNames.branchAdd,
        path: AppRoutes.branchAdd,
        builder: (BuildContext context, GoRouterState state) {
          return const BranchFormScreen(mode: BranchFormMode.add);
        },
      ),
      GoRoute(
        name: AppRouteNames.branchEdit,
        path: AppRoutes.branchEdit,
        builder: (BuildContext context, GoRouterState state) {
          final Branch branch = state.extra as Branch;
          return BranchFormScreen(mode: BranchFormMode.edit, branch: branch);
        },
      ),
      GoRoute(
        name: AppRouteNames.branchDetails,
        path: AppRoutes.branchDetails,
        builder: (BuildContext context, GoRouterState state) {
          final Branch branch = state.extra as Branch;
          return BranchDetailsScreen(branch: branch);
        },
      ),
      GoRoute(
        name: AppRouteNames.profile,
        path: AppRoutes.profile,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(state: state, child: const ProfileScreen());
        },
      ),
      GoRoute(
        name: AppRouteNames.profileEdit,
        path: AppRoutes.profileEdit,
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra;
          StaffMember staffMember;
          String? tenantId;
          bool isOwner = false;

          String? businessName;
          String? location;

          if (extra is Map<String, dynamic>) {
            staffMember = extra['staff'] as StaffMember;
            tenantId = extra['tenantId'] as String?;
            isOwner = extra['isOwner'] as bool? ?? false;
            businessName = extra['businessName'] as String?;
            location = extra['location'] as String?;
          } else if (extra is StaffMember) {
            // Legacy fallback
            staffMember = extra;
          } else {
            // Should not happen, but provide a safe fallback
            staffMember = StaffMember(
              id: '',
              tenantId: '',
              email: '',
              phone: '',
              status: 'Active',
              role: 'tenant_owner',
              branches: const [],
              loginId: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }

          return EditProfileScreen(
            initialProfile: staffMember,
            tenantId: tenantId,
            isOwner: isOwner,
            initialBusinessName: businessName,
            initialLocation: location,
        name: AppRouteNames.businessSettings,
        path: AppRoutes.businessSettings,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(
            state: state,
            child: const BusinessSettingsScreen(),
          );
        },
      ),
      GoRoute(
        name: AppRouteNames.rolesAndStaff,
        path: AppRoutes.rolesAndStaff,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(
            state: state,
            child: const RolesAndStaffScreen(),
          );
        },
      ),
      GoRoute(
        name: AppRouteNames.staffList,
        path: AppRoutes.staffList,
        builder: (BuildContext context, GoRouterState state) {
          return const StaffManagementScreen();
        },
      ),
      GoRoute(
        name: AppRouteNames.staffRegister,
        path: AppRoutes.staffRegister,
        builder: (BuildContext context, GoRouterState state) {
          final tenantId = state.extra as String? ?? '';
          return RegisterStaffScreen(tenantId: tenantId);
        },
      ),
      GoRoute(
        name: AppRouteNames.staffViewProfile,
        path: AppRoutes.staffViewProfile,
        builder: (BuildContext context, GoRouterState state) {
          final staffMember = state.extra as StaffMember;
          return ViewStaffProfileScreen(staff: staffMember);
        },
      ),
      GoRoute(
        name: AppRouteNames.staffEdit,
        path: AppRoutes.staffEdit,
        builder: (BuildContext context, GoRouterState state) {
          final staffMember = state.extra as StaffMember;
          return EditStaffScreen(staff: staffMember);
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
