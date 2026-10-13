import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/core/phone/phone_verifier.dart';
import 'package:nexoraa_mobile/features/consumer/consumer_dependencies.dart';
import 'package:nexoraa_mobile/features/consumer/controllers/consumer_session_controller.dart';
import 'package:nexoraa_mobile/features/consumer/screens/consumer_auth_screens.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_api_service.dart';
import 'package:nexoraa_mobile/features/consumer/services/consumer_session_storage.dart';

class _FakeSession implements PhoneCodeSession {
  _FakeSession(this.owner);

  final _FakeVerifier owner;

  @override
  Future<String> confirm(String code) async {
    owner.confirmedWith = code;
    if (owner.wrongCode) throw const PhoneVerificationException('That code is not correct. Check it and try again.');
    return 'fake-firebase-token';
  }
}

class _FakeVerifier implements PhoneVerifier {
  String? sentTo;
  String? confirmedWith;
  bool wrongCode = false;
  bool failSend = false;

  @override
  Future<PhoneCodeSession> sendCode(String phoneE164) async {
    if (failSend) throw const PhoneVerificationException('Too many tries. Please wait a few minutes and try again.');
    sentTo = phoneE164;
    return _FakeSession(this);
  }
}

List<http.Request> _useBackend() {
  final List<http.Request> calls = <http.Request>[];
  final MemoryConsumerSessionStorage storage = MemoryConsumerSessionStorage();
  ConsumerDependencies.storage = storage;
  ConsumerDependencies.api = ConsumerApiService(
    authBaseUri: () => Uri.parse('http://auth.test/api'),
    marketplaceBaseUri: () => Uri.parse('http://market.test/api'),
    storage: storage,
    client: MockClient((http.Request r) async {
      calls.add(r);
      return http.Response(jsonEncode(<String, Object>{'data': <String, Object>{'accepted': true}}), 200);
    }),
  );
  ConsumerDependencies.controller = ConsumerSessionController(api: ConsumerDependencies.api, storage: storage);
  return calls;
}

Widget _app() => MaterialApp.router(
  routerConfig: GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => const ConsumerVerifyEmailScreen(args: ConsumerVerifyArgs(email: 'riya@example.com'))),
      GoRoute(path: '/login', name: AppRouteNames.consumerLogin, builder: (_, _) => const Scaffold(body: Text('route:login'))),
    ],
  ),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);

void main() {
  late _FakeVerifier verifier;
  late List<http.Request> calls;

  setUp(() {
    verifier = _FakeVerifier();
    PhoneVerification.verifier = verifier;
    calls = _useBackend();
  });

  testWidgets('verify with the phone: number, code, then the server is given Firebase\'s proof', (WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const Key('consumerVerify.phoneToggle')));
    await tester.pumpAndSettle();

    // a wrong-looking number is refused before anything is sent
    await tester.enterText(find.byKey(const Key('consumerVerify.phone')), '12345');
    await tester.tap(find.byKey(const Key('consumerVerify.phoneSend')));
    await tester.pumpAndSettle();
    expect(verifier.sentTo, isNull);

    await tester.enterText(find.byKey(const Key('consumerVerify.phone')), '98112 00001');
    await tester.tap(find.byKey(const Key('consumerVerify.phoneSend')));
    await tester.pumpAndSettle();
    expect(verifier.sentTo, '+919811200001');
    expect(find.text('Code sent to +91 9811200001'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('consumerVerify.phoneCode')), '123456');
    await tester.tap(find.byKey(const Key('consumerVerify.phoneConfirm')));
    await tester.pumpAndSettle();

    expect(verifier.confirmedWith, '123456');
    final http.Request request = calls.lastWhere((http.Request r) => r.url.path.endsWith('/verify-phone'));
    expect(jsonDecode(request.body), <String, Object?>{'email': 'riya@example.com', 'idToken': 'fake-firebase-token'});
    expect(find.text('route:login'), findsOneWidget);
  });

  testWidgets('a wrong code or a failed send shows a clear message and verifies nothing', (WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byKey(const Key('consumerVerify.phoneToggle')));
    await tester.pumpAndSettle();

    verifier.failSend = true;
    await tester.enterText(find.byKey(const Key('consumerVerify.phone')), '9811200001');
    await tester.tap(find.byKey(const Key('consumerVerify.phoneSend')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Too many tries'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    verifier.failSend = false;
    verifier.wrongCode = true;
    await tester.tap(find.byKey(const Key('consumerVerify.phoneSend')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('consumerVerify.phoneCode')), '000000');
    await tester.tap(find.byKey(const Key('consumerVerify.phoneConfirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining('not correct'), findsOneWidget);
    expect(calls.where((http.Request r) => r.url.path.endsWith('/verify-phone')), isEmpty);
  });

  testWidgets('the email code is still there, and you can switch back to it', (WidgetTester tester) async {
    await tester.pumpWidget(_app());
    expect(find.byKey(const Key('consumerVerify.code')), findsOneWidget);
    await tester.tap(find.byKey(const Key('consumerVerify.phoneToggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consumerVerify.code')), findsNothing);
    await tester.tap(find.byKey(const Key('consumerVerify.emailToggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('consumerVerify.code')), findsOneWidget);
  });
}
