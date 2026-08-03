import 'package:flutter/material.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

class NexoraaApp extends StatelessWidget {
  const NexoraaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      darkTheme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
      theme: AppTheme.light,
      themeMode: ThemeMode.system,
      title: 'Nexoraa CleanSoft',
    );
  }
}
