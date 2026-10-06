import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/app/app.dart';
import 'package:nexoraa_mobile/core/localization/l10n.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';
import 'package:nexoraa_mobile/features/authentication/password_policy.dart';

Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pumpWidget(const NexoraaApp());
  await tester.pump(AppDurations.startupSplash);
  await tester.pumpAndSettle();
  // Signed-out start shows the customer/business choice first (the shared
  // router may already be on the login screen from an earlier test).
  final Finder business = find.byKey(const Key('welcome.business'));
  if (business.evaluate().isNotEmpty) {
    await tester.tap(business);
    await tester.pumpAndSettle();
  }
}

void main() {
  tearDown(() => LocaleDependencies.controller.setLanguage(AppLanguage.english));

  testWidgets('login screen language pill switches the app language', (
    WidgetTester tester,
  ) async {
    await _pumpPastSplash(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.byType(LanguageSelectorButton));
    await tester.pumpAndSettle();
    expect(find.text('Choose language'), findsOneWidget);

    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();

    expect(LocaleDependencies.controller.language, AppLanguage.hindi);
    expect(find.text('फिर से स्वागत है'), findsOneWidget);
    expect(find.text('साइन इन करें'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);

    await tester.tap(find.byType(LanguageSelectorButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('मराठी'));
    await tester.pumpAndSettle();

    expect(find.text('पुन्हा स्वागत आहे'), findsOneWidget);
    expect(find.text('व्यवसाय खाते तयार करा'), findsOneWidget);
  });

  testWidgets('validation messages follow the chosen language', (
    WidgetTester tester,
  ) async {
    LocaleDependencies.controller.setLanguage(AppLanguage.hindi);
    await _pumpPastSplash(tester);

    await tester.tap(find.text('साइन इन करें'));
    await tester.pumpAndSettle();

    expect(
      find.text('आगे बढ़ने के लिए अपना ईमेल और पासवर्ड दर्ज करें।'),
      findsOneWidget,
    );
  });

  test('password policy messages are translated', () {
    final AppLocalizations marathi = lookupAppLocalizations(const Locale('mr'));
    expect(PasswordPolicy.validate('Short1!', marathi), 'पासवर्डमध्ये हे असावे: किमान 8 अक्षरे.');
    expect(PasswordPolicy.validate('Valid@Pass1', marathi), isNull);
  });
}
