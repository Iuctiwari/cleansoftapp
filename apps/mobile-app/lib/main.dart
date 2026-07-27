import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const NexoraaMobileApp());
}

final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const MobileHomeScreen();
      },
    ),
  ],
);

class NexoraaMobileApp extends StatelessWidget {
  const NexoraaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: dotenv.get('APP_NAME', fallback: 'Nexoraa CleanSoft'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String appName = dotenv.get(
      'APP_NAME',
      fallback: 'Nexoraa CleanSoft',
    );
    final String environment = dotenv.get(
      'APP_ENV',
      fallback: 'development',
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(appName, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text('Environment: $environment'),
              const SizedBox(height: 24),
              const Text('Flutter Mobile Foundation Ready'),
            ],
          ),
        ),
      ),
    );
  }
}
