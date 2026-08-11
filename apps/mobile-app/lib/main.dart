import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nexoraa_mobile/app/app.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await AuthenticationDependencies.controller.restoreSession();
  runApp(const NexoraaApp());
}
