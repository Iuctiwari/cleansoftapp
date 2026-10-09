import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/access_policy.dart';
import 'package:nexoraa_mobile/features/company_admin/company_admin.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/features/authentication/screens/forgot_password_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/login_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/reset_password_screen.dart';
import 'package:nexoraa_mobile/features/authentication/screens/splash_screen.dart';
import 'package:nexoraa_mobile/features/branch/branch.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/models/consumer_models.dart';
import 'package:nexoraa_mobile/features/consumer/screens/address_screens.dart';
import 'package:nexoraa_mobile/features/consumer/screens/booking_screen.dart';
import 'package:nexoraa_mobile/features/consumer/screens/consumer_auth_screens.dart';
import 'package:nexoraa_mobile/features/consumer/screens/consumer_home_screen.dart';
import 'package:nexoraa_mobile/features/consumer/screens/request_detail_screen.dart';
import 'package:nexoraa_mobile/features/consumer/screens/shop_detail_screen.dart';
import 'package:nexoraa_mobile/features/consumer/screens/welcome_screen.dart';
import 'package:nexoraa_mobile/features/dashboard/dashboard.dart';
import 'package:nexoraa_mobile/features/notifications/notifications.dart';
import 'package:nexoraa_mobile/features/online_requests/screens/online_requests_screen.dart';
import 'package:nexoraa_mobile/features/online_requests/screens/shop_listing_screen.dart';
import 'package:nexoraa_mobile/features/online_requests/widgets/shop_ui.dart';
import 'package:nexoraa_mobile/features/profile/screens/edit_profile_screen.dart';
import 'package:nexoraa_mobile/features/profile/screens/profile_screen.dart';
import 'package:nexoraa_mobile/features/settings/settings.dart';
import 'package:nexoraa_mobile/features/staff/models/staff_member.dart';
import 'package:nexoraa_mobile/features/staff/screens/edit_staff_screen.dart';
import 'package:nexoraa_mobile/features/staff/screens/register_staff_screen.dart';
import 'package:nexoraa_mobile/features/staff/screens/staff_management_screen.dart';
import 'package:nexoraa_mobile/features/staff/screens/view_staff_profile_screen.dart';

import 'package:nexoraa_mobile/features/subscription/screens/subscription_screen.dart';

import '../features/tenant/models/registration_form.dart';
import '../features/tenant/models/tenant_onboarding_data.dart';
import '../features/tenant/screens/account_created.screen.dart';
import '../features/tenant/screens/account_details.screen.dart';
import '../features/tenant/screens/all_set.screen.dart';
import '../features/tenant/screens/business_info.screen.dart';
import '../features/tenant/screens/choose_plan.screen.dart';
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
  static const String onboardingChoosePlan = '/onboarding/choose-plan';
  static const String subscription = '/dashboard/subscription';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
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
  static const String settingsServices =
      '/dashboard/business-settings/services';
  static const String settingsItems = '/dashboard/business-settings/items';
  static const String settingsPricing = '/dashboard/business-settings/pricing';
  static const String rolesAndStaff = '/dashboard/roles-and-staff';
  static const String staffDashboard = '/staff-dashboard';
  static const String shopListing = '/dashboard/shop-listing';
  static const String onlineRequests = '/dashboard/online-requests';

  // Customer (marketplace) side — everything under /c/ uses the customer
  // session, never the shop login.
  static const String welcome = '/welcome';
  static const String consumerLogin = '/c/login';
  static const String consumerSignup = '/c/signup';
  static const String consumerVerify = '/c/verify';
  static const String consumerForgotPassword = '/c/forgot-password';
  static const String consumerHome = '/c/home';
  static const String consumerAddresses = '/c/addresses';
  static const String consumerAddressNew = '/c/addresses/new';
  static const String consumerAddressEdit = '/c/addresses/edit';
  static const String consumerShop = '/c/shops/:shopId';
  static const String consumerBook = '/c/shops/:shopId/book';
  static const String consumerRequest = '/c/requests/:requestId';

  /// Customer screens a signed-out visitor may open.
  static const Set<String> consumerPublic = <String>{
    consumerLogin,
    consumerSignup,
    consumerVerify,
    consumerForgotPassword,
  };

  // Company Admin — reachable only by direct URL, never linked from any
  // tenant-facing UI. Uses a completely separate auth system (Phase 1 of the
  // Nexoraa Company Admin Panel); see the `redirect` callback below for how
  // these paths bypass tenant-auth checks entirely.
  static const String companyAdminLogin = '/company-admin';
  static const String companyAdminDashboard = '/company-admin/dashboard';
  static const String companyAdminTenantDetail = '/company-admin/tenants/:tenantId';
  static const String companyAdminTenantModules =
      '/company-admin/tenants/:tenantId/modules';
  static const String companyAdminTenantTheme =
      '/company-admin/tenants/:tenantId/theme';
  static const String companyAdminPlanForm = '/company-admin/subscription-plans/new';
  static const String companyAdminPlanTenants =
      '/company-admin/subscription-plans/:planKey/tenants';
  static const String companyAdminBusinessTypeForm = '/company-admin/business-types/new';
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
  static const String onboardingChoosePlan = 'onboardingChoosePlan';
  static const String subscription = 'subscription';
  static const String forgotPassword = 'forgot-password';
  static const String resetPassword = 'resetPassword';
  static const String notifications = 'notifications';
  static const String branchList = 'branchList';
  static const String branchAdd = 'branchAdd';
  static const String branchEdit = 'branchEdit';
  static const String branchDetails = 'branchDetails';
  static const String profile = 'profile';
  static const String businessSettings = 'businessSettings';
  static const String settingsServices = 'settingsServices';
  static const String settingsItems = 'settingsItems';
  static const String settingsPricing = 'settingsPricing';
  static const String rolesAndStaff = 'rolesAndStaff';
  static const String staffList = 'staffList';
  static const String staffRegister = 'staffRegister';
  static const String staffViewProfile = 'staffViewProfile';
  static const String staffEdit = 'staffEdit';
  static const String profileEdit = 'profileEdit';
  static const String staffDashboard = 'staffDashboard';
  static const String shopListing = 'shopListing';
  static const String onlineRequests = 'onlineRequests';
  static const String welcome = 'welcome';
  static const String consumerLogin = 'consumerLogin';
  static const String consumerSignup = 'consumerSignup';
  static const String consumerVerify = 'consumerVerify';
  static const String consumerForgotPassword = 'consumerForgotPassword';
  static const String consumerHome = 'consumerHome';
  static const String consumerAddresses = 'consumerAddresses';
  static const String consumerAddressNew = 'consumerAddressNew';
  static const String consumerAddressEdit = 'consumerAddressEdit';
  static const String consumerShop = 'consumerShop';
  static const String consumerBook = 'consumerBook';
  static const String consumerRequest = 'consumerRequest';

  // Company Admin — see AppRoutes above for the isolation rationale.
  static const String companyAdminLogin = 'companyAdminLogin';
  static const String companyAdminDashboard = 'companyAdminDashboard';
  static const String companyAdminTenantDetail = 'companyAdminTenantDetail';
  static const String companyAdminTenantModules = 'companyAdminTenantModules';
  static const String companyAdminTenantTheme = 'companyAdminTenantTheme';
  static const String companyAdminPlanForm = 'companyAdminPlanForm';
  static const String companyAdminPlanTenants = 'companyAdminPlanTenants';
  static const String companyAdminBusinessTypeForm = 'companyAdminBusinessTypeForm';
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
    refreshListenable: Listenable.merge(<Listenable>[
      AuthenticationDependencies.controller,
      ConsumerDependencies.controller,
    ]),
    redirect: (BuildContext context, GoRouterState state) {
      // Company Admin is a completely separate identity/auth system (Phase 1
      // of the Nexoraa Company Admin Panel) — it must never be subject to
      // tenant/staff auth checks below, in either direction: an unauthenticated
      // tenant visitor must still reach /company-admin (it has its own login
      // screen), and a signed-in tenant owner must not be bounced away from it
      // either. Admin-session verification is handled per-screen instead
      // (AdminSessionGate), not here.
      if (state.matchedLocation.startsWith('/company-admin')) {
        return null;
      }

      // Customer side: its own session, independent of the shop login.
      if (state.matchedLocation.startsWith('/c/')) {
        final bool customer = ConsumerDependencies.controller.isAuthenticated;
        final bool public = AppRoutes.consumerPublic.contains(state.matchedLocation);
        if (!customer && !public) return AppRoutes.consumerLogin;
        if (customer && state.matchedLocation == AppRoutes.consumerLogin) {
          return AppRoutes.consumerHome;
        }
        return null;
      }
      if (state.matchedLocation == AppRoutes.welcome) {
        if (ConsumerDependencies.controller.isAuthenticated) return AppRoutes.consumerHome;
        return null;
      }

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
          AppRouteNames.shopListing => accessPolicy.allows(
            AppCapability.branchesView,
          ),
          AppRouteNames.onlineRequests => accessPolicy.allows(
            AppCapability.ordersView,
          ),
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
        name: AppRouteNames.resetPassword,
        path: AppRoutes.resetPassword,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final extra = state.extra;
          final identifier = extra is String ? extra : '';
          return _fadePage<void>(
            state: state,
            child: ResetPasswordScreen(initialIdentifier: identifier),
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
        name: AppRouteNames.onboardingChoosePlan,
        path: AppRoutes.onboardingChoosePlan,
        builder: (context, state) {
          final extra = state.extra;
          return ChoosePlanScreen(
            onboardingData: extra is TenantOnboardingData ? extra : null,
          );
        },
      ),
      GoRoute(
        name: AppRouteNames.subscription,
        path: AppRoutes.subscription,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(state: state, child: const SubscriptionScreen());
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
          );
        },
      ),
      GoRoute(
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
        name: AppRouteNames.settingsServices,
        path: AppRoutes.settingsServices,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(
            state: state,
            child: const ServicesSettingsScreen(),
          );
        },
      ),
      GoRoute(
        name: AppRouteNames.settingsItems,
        path: AppRoutes.settingsItems,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(
            state: state,
            child: const ItemsSettingsScreen(),
          );
        },
      ),
      GoRoute(
        name: AppRouteNames.settingsPricing,
        path: AppRoutes.settingsPricing,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _fadePage<void>(
            state: state,
            child: const PricingSettingsScreen(),
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

      // ── Shop side of the marketplace ─────────────────────────────────
      GoRoute(
        name: AppRouteNames.shopListing,
        path: AppRoutes.shopListing,
        builder: (BuildContext context, GoRouterState state) =>
            ShopListingScreen(branch: ShopBranchArgs.from(state.extra)),
      ),
      GoRoute(
        name: AppRouteNames.onlineRequests,
        path: AppRoutes.onlineRequests,
        builder: (BuildContext context, GoRouterState state) =>
            OnlineRequestsScreen(branch: ShopBranchArgs.from(state.extra)),
      ),

      // ── Customer (marketplace) ───────────────────────────────────────
      GoRoute(
        name: AppRouteNames.welcome,
        path: AppRoutes.welcome,
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadePage<void>(state: state, child: const WelcomeScreen()),
      ),
      GoRoute(
        name: AppRouteNames.consumerLogin,
        path: AppRoutes.consumerLogin,
        builder: (BuildContext context, GoRouterState state) => const ConsumerLoginScreen(),
      ),
      GoRoute(
        name: AppRouteNames.consumerSignup,
        path: AppRoutes.consumerSignup,
        builder: (BuildContext context, GoRouterState state) => const ConsumerSignupScreen(),
      ),
      GoRoute(
        name: AppRouteNames.consumerVerify,
        path: AppRoutes.consumerVerify,
        redirect: (BuildContext context, GoRouterState state) =>
            state.extra is ConsumerVerifyArgs ? null : AppRoutes.consumerLogin,
        builder: (BuildContext context, GoRouterState state) =>
            ConsumerVerifyEmailScreen(args: state.extra! as ConsumerVerifyArgs),
      ),
      GoRoute(
        name: AppRouteNames.consumerForgotPassword,
        path: AppRoutes.consumerForgotPassword,
        builder: (BuildContext context, GoRouterState state) => const ConsumerForgotPasswordScreen(),
      ),
      GoRoute(
        name: AppRouteNames.consumerHome,
        path: AppRoutes.consumerHome,
        pageBuilder: (BuildContext context, GoRouterState state) => _fadePage<void>(
          state: state,
          child: ConsumerHomeScreen(
            key: ValueKey<Object?>(state.extra),
            initialTab: state.extra is int ? state.extra! as int : 0,
          ),
        ),
      ),
      GoRoute(
        name: AppRouteNames.consumerAddresses,
        path: AppRoutes.consumerAddresses,
        builder: (BuildContext context, GoRouterState state) => const AddressListScreen(),
      ),
      GoRoute(
        name: AppRouteNames.consumerAddressNew,
        path: AppRoutes.consumerAddressNew,
        // extra == true: the compulsory first address.
        builder: (BuildContext context, GoRouterState state) =>
            AddressFormScreen(isFirstAddress: state.extra == true),
      ),
      GoRoute(
        name: AppRouteNames.consumerAddressEdit,
        path: AppRoutes.consumerAddressEdit,
        redirect: (BuildContext context, GoRouterState state) =>
            state.extra is ConsumerAddress ? null : AppRoutes.consumerAddresses,
        builder: (BuildContext context, GoRouterState state) =>
            AddressFormScreen(existing: state.extra! as ConsumerAddress),
      ),
      GoRoute(
        name: AppRouteNames.consumerShop,
        path: AppRoutes.consumerShop,
        builder: (BuildContext context, GoRouterState state) => ShopDetailScreen(
          shopId: state.pathParameters['shopId'] ?? '',
          origin: state.extra is ShopSearchFilters ? state.extra! as ShopSearchFilters : null,
        ),
      ),
      GoRoute(
        name: AppRouteNames.consumerBook,
        path: AppRoutes.consumerBook,
        redirect: (BuildContext context, GoRouterState state) =>
            state.extra is ShopDetail ? null : AppRoutes.consumerHome,
        builder: (BuildContext context, GoRouterState state) =>
            BookingScreen(shop: state.extra! as ShopDetail),
      ),
      GoRoute(
        name: AppRouteNames.consumerRequest,
        path: AppRoutes.consumerRequest,
        builder: (BuildContext context, GoRouterState state) =>
            RequestDetailScreen(requestId: state.pathParameters['requestId'] ?? ''),
      ),

      // ── Company Admin ────────────────────────────────────────────────
      // Deliberately NOT linked from any nav item/menu/button elsewhere in
      // this router or in any screen — reachable only by typing/deep-linking
      // these URLs directly. See the `redirect` callback above for why these
      // paths bypass tenant-auth entirely, and AdminSessionGate for the
      // separate admin-session check each of these screens performs itself.
      GoRoute(
        name: AppRouteNames.companyAdminLogin,
        path: AppRoutes.companyAdminLogin,
        builder: (BuildContext context, GoRouterState state) => const AdminLoginScreen(),
      ),
      GoRoute(
        name: AppRouteNames.companyAdminDashboard,
        path: AppRoutes.companyAdminDashboard,
        builder: (BuildContext context, GoRouterState state) =>
            const CompanyAdminShellScreen(),
      ),
      GoRoute(
        name: AppRouteNames.companyAdminTenantDetail,
        path: AppRoutes.companyAdminTenantDetail,
        builder: (BuildContext context, GoRouterState state) => TenantDetailScreen(
          tenantId: state.pathParameters['tenantId'] ?? '',
        ),
      ),
      GoRoute(
        name: AppRouteNames.companyAdminTenantModules,
        path: AppRoutes.companyAdminTenantModules,
        builder: (BuildContext context, GoRouterState state) => ModuleMatrixScreen(
          tenantId: state.pathParameters['tenantId'] ?? '',
        ),
      ),
      GoRoute(
        name: AppRouteNames.companyAdminTenantTheme,
        path: AppRoutes.companyAdminTenantTheme,
        builder: (BuildContext context, GoRouterState state) => ThemeEditorScreen(
          tenantId: state.pathParameters['tenantId'] ?? '',
        ),
      ),
      GoRoute(
        name: AppRouteNames.companyAdminPlanForm,
        path: AppRoutes.companyAdminPlanForm,
        builder: (BuildContext context, GoRouterState state) => PlanFormScreen(
          existing: state.extra as SubscriptionPlanModel?,
        ),
      ),
      GoRoute(
        name: AppRouteNames.companyAdminPlanTenants,
        path: AppRoutes.companyAdminPlanTenants,
        builder: (BuildContext context, GoRouterState state) => PlanTenantsScreen(
          planKey: state.pathParameters['planKey'] ?? '',
          planDisplayName: state.extra as String? ?? state.pathParameters['planKey'] ?? 'Plan',
        ),
      ),
      GoRoute(
        name: AppRouteNames.companyAdminBusinessTypeForm,
        path: AppRoutes.companyAdminBusinessTypeForm,
        builder: (BuildContext context, GoRouterState state) => BusinessTypeFormScreen(
          existing: state.extra is BusinessTypeModel ? state.extra! as BusinessTypeModel : null,
          initialValue: state.extra is String ? state.extra! as String : null,
        ),
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
