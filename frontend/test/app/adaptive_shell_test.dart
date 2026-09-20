import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/app/shell/adaptive_app_shell.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets(
    'uses bottom navigation on compact screens and sidebar on wide screens',
    (tester) async {
      const targets = <(Size, bool)>[
        (Size(390, 844), false),
        (Size(834, 1194), false),
        (Size(1194, 834), true),
        (Size(1440, 900), true),
        (Size(1728, 1000), true),
      ];
      for (final (size, usesSidebar) in targets) {
        await pumpTestApp(
          tester,
          const AdaptiveAppShell(isGuest: false),
          size: size,
        );
        expect(
          find.byType(NavigationRail),
          usesSidebar ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(NavigationBar),
          usesSidebar ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'shell at $size');
      }
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
