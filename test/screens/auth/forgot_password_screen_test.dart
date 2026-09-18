import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/screens/auth/forgot_password_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('reset form validates missing and malformed email', (
    tester,
  ) async {
    await pumpTestApp(tester, const ForgotPasswordScreen());
    final button = find.widgetWithText(ElevatedButton, 'Send reset link');
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });
}
