import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/app/app.dart';
import 'package:nexoraa_mobile/app/router.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

void main() {
  testWidgets('empty sign in stays on login and shows validation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NexoraaApp());

    expect(find.text('Nexoraa'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);

    await tester.pump(AppDurations.standard);
    expect(find.text('Welcome back'), findsNothing);

    await tester.pump(AppDurations.startupSplash - AppDurations.standard);
    await tester.pumpAndSettle();

    // Signed-out start shows the customer/business choice first.
    expect(find.text('I run a business'), findsOneWidget);
    await tester.tap(find.byKey(const Key('welcome.business')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Business Account'), findsOneWidget);

    final Finder passwordField = find.byType(EditableText).last;
    expect(tester.widget<EditableText>(passwordField).obscureText, isTrue);

    await tester.tap(find.byIcon(AppIcons.visibility));
    await tester.pump();

    expect(tester.widget<EditableText>(passwordField).obscureText, isFalse);

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsNothing);
    expect(
      find.text('Enter your email and password to continue.'),
      findsOneWidget,
    );
    expect(find.text('Invalid email or password'), findsNothing);
  });

  testWidgets('registration routes restore a JSON registration form', (
    WidgetTester tester,
  ) async {
    await dotenv.load(fileName: '.env');
    await tester.pumpWidget(const NexoraaApp());
    final Map<String, dynamic> formJson = <String, dynamic>{
      'businessName': 'FreshCare Laundry',
      'businessType': 'laundry',
      'ownerName': 'Priya Sharma',
      'email': 'priya@example.com',
      'mobileNumber': '+919876543210',
      'password': 'Fresh@2026Pass',
      'agreedToTerms': true,
    };

    AppRouter.router.goNamed(
      AppRouteNames.registerBusinessInfo,
      extra: formJson,
    );
    await tester.pumpAndSettle();

    expect(find.text('Tell us about your business'), findsOneWidget);
    expect(find.text('FreshCare Laundry'), findsOneWidget);

    AppRouter.router.goNamed(
      AppRouteNames.registerAccountDetails,
      extra: formJson,
    );
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('priya@example.com'), findsOneWidget);
  });
}
