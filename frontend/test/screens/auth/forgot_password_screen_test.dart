import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/screens/auth/forgot_password_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('reset navigation meets the minimum touch target', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpTestApp(tester, const ForgotPasswordScreen());
    final size = tester.getSize(
      find.widgetWithText(TextButton, 'Back to sign in'),
    );
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('reset form validates missing and malformed email', (
    tester,
  ) async {
    await pumpTestApp(tester, const ForgotPasswordScreen());
    final button = find.widgetWithText(ElevatedButton, 'Send reset link');
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    await tester.tap(button);
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });
}
