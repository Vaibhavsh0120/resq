import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/screens/auth/signup_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('signup exposes all required fields', (tester) async {
    await pumpTestApp(tester, const SignupScreen());
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
    expect(find.text('Use at least 6 characters'), findsOneWidget);
  });

  testWidgets('signup validates required values and matching passwords', (
    tester,
  ) async {
    await pumpTestApp(tester, const SignupScreen());
    final button = find.widgetWithText(ElevatedButton, 'Create account');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Enter your full name'), findsOneWidget);
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isTrue,
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Alex Morgan');
    await tester.enterText(fields.at(1), 'alex@example.com');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.enterText(fields.at(3), 'different123');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(find.text("Passwords don't match"), findsOneWidget);
  });
}
