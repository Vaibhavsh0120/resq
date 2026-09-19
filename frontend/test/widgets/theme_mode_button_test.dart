import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/widgets/theme_mode_button.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('selecting Dark updates and persists the theme mode', (
    tester,
  ) async {
    final controller = await pumpTestApp(
      tester,
      const Scaffold(body: ThemeModeButton()),
    );
    expect(controller.mode, ThemeMode.system);

    await tester.tap(find.byIcon(Icons.brightness_auto_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeMode.dark);
  });
}
