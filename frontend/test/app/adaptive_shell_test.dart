import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/app/shell/adaptive_app_shell.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets(
    'uses bottom navigation on compact screens and sidebar on wide screens',
    (tester) async {
      await pumpTestApp(
        tester,
        const AdaptiveAppShell(isGuest: false),
        size: const Size(390, 844),
      );
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      await pumpTestApp(
        tester,
        const AdaptiveAppShell(isGuest: false),
        size: const Size(1194, 834),
      );
      expect(
        MediaQuery.sizeOf(tester.element(find.byType(AdaptiveAppShell))),
        const Size(1194, 834),
      );
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets('guest family destination opens a sign-in gate', (tester) async {
    await pumpTestApp(
      tester,
      const AdaptiveAppShell(isGuest: true),
      size: const Size(390, 844),
    );

    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to use Family Circle'), findsOneWidget);
  });
}
