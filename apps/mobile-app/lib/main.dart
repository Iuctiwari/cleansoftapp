import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nexoraa_mobile/app/app.dart';
import 'package:nexoraa_mobile/core/localization/locale_controller.dart';
import 'package:nexoraa_mobile/core/network/backend_environment.dart';
import 'package:nexoraa_mobile/features/authentication/authentication_dependencies.dart';
import 'package:nexoraa_mobile/core/push/push_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await BackendEnvironment.resolve();
  await LocaleDependencies.controller.load();
  await AuthenticationDependencies.controller.restoreSession();
  await ConsumerDependencies.controller.restoreSession();
  runApp(const NexoraaApp());
  // Push notifications start in the background; the app never waits for them.
  unawaited(PushDependencies.start());
}
