import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/screens/auth/auth_shell.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('compact layout hides the brand panel', (tester) async {
    await pumpTestApp(
      tester,
      const AuthShell(
        title: 'Test form',
        subtitle: 'Subtitle',
        child: Text('Body'),
      ),
    );
    expect(find.text('Test form'), findsOneWidget);
    expect(find.text('Your safety, one tap away.'), findsNothing);
  });

  testWidgets('wide layout shows the brand panel without stretching form', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const AuthShell(
        title: 'Test form',
        subtitle: 'Subtitle',
        child: Text('Body'),
      ),
      size: const Size(1280, 800),
    );
    expect(find.text('ResQ'), findsOneWidget);
    expect(find.textContaining('Your safety, one tap away.'), findsOneWidget);
    final formText = tester.getSize(find.text('Test form'));
    expect(formText.width, lessThan(440));
  });
}
