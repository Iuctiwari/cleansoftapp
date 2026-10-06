import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/core/network/tenant_config_bootstrapper.dart';

class NexoraaApp extends StatefulWidget {
  const NexoraaApp({super.key});

  @override
  State<NexoraaApp> createState() => _NexoraaAppState();
}

class _NexoraaAppState extends State<NexoraaApp> {
  @override
  void initState() {
    super.initState();
    // Fetches GET /tenant/config/active once tenant login succeeds (existing
    // AuthenticationController, listened to from the outside — see
    // TenantConfigBootstrapper). Before that first successful fetch, and for
    // any tenant with no theme set, themeProvider.lightTheme/darkTheme below
    // are the exact same AppTheme.light/AppTheme.dark instances this widget
    // rendered before this phase — zero visual change by construction.
    TenantConfigBootstrapper.start();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        TenantConfigBootstrapper.themeProvider,
        LocaleDependencies.controller,
      ]),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp.router(
          darkTheme: TenantConfigBootstrapper.themeProvider.darkTheme,
          debugShowCheckedModeBanner: false,
          locale: LocaleDependencies.controller.language.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: AppRouter.router,
          scrollBehavior: const _ClampedScrollBehavior(),
          theme: TenantConfigBootstrapper.themeProvider.lightTheme,
          themeMode: ThemeMode.light,
          title: 'Nexoraa CleanSoft',
        );
      },
    );
  }
}

class _ClampedScrollBehavior extends MaterialScrollBehavior {
  const _ClampedScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
