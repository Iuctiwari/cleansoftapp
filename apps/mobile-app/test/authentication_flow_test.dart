import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexoraa_mobile/app/app.dart';
import 'package:nexoraa_mobile/design_system/design_system.dart';

void main() {
  testWidgets('splash waits four seconds before showing login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NexoraaApp());

    expect(find.text('Nexoraa'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);

    await tester.pump(AppDurations.standard);
    expect(find.text('Welcome back'), findsNothing);

    await tester.pump(AppDurations.startupSplash - AppDurations.standard);
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
  });
}
