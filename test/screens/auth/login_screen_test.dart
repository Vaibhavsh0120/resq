import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/screens/auth/login_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('shows every required login route and provider', (tester) async {
    await pumpTestApp(tester, const LoginScreen());
    expect(find.text('Emergency access'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('invalid form is rejected before Firebase is called', (
    tester,
  ) async {
    await pumpTestApp(tester, const LoginScreen());
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('password eye icon works on login', (tester) async {
    await pumpTestApp(tester, const LoginScreen());
    final fields = find.byType(EditableText);
    expect(tester.widget<EditableText>(fields.at(1)).obscureText, isTrue);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(tester.widget<EditableText>(fields.at(1)).obscureText, isFalse);
  });

  testWidgets('signup and password-reset links open their screens', (
    tester,
  ) async {
    await pumpTestApp(tester, const LoginScreen());
    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    final backToSignIn = find.widgetWithText(TextButton, 'Sign in');
    await tester.ensureVisible(backToSignIn);
    await tester.tap(backToSignIn);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Forgot password?'));
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);
  });
}
