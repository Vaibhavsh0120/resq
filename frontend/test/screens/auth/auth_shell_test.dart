import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/screens/auth/auth_shell.dart';
import 'package:resq/widgets/app_surfaces.dart';
import 'package:resq/widgets/brand_mark.dart';
import 'package:resq/widgets/theme_mode_button.dart';

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

  testWidgets('compact header keeps brand and appearance control together', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const AuthShell(
        title: 'Test form',
        subtitle: 'Subtitle',
        child: Text('Body'),
      ),
      size: const Size(390, 844),
    );

    final brandCenter = tester.getCenter(find.byType(ResQBrandMark));
    final appearanceCenter = tester.getCenter(find.byType(ThemeModeButton));
    final appearanceSize = tester.getSize(find.byType(ThemeModeButton));

    expect((brandCenter.dy - appearanceCenter.dy).abs(), lessThan(8));
    expect(appearanceCenter.dx, greaterThan(brandCenter.dx));
    expect(appearanceSize.width, greaterThanOrEqualTo(44));
    expect(appearanceSize.height, greaterThanOrEqualTo(44));
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
    expect(formText.width, lessThan(560));
  });

  testWidgets('wide auth illustration uses the larger presentation size', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const AuthShell(
        title: 'Test form',
        subtitle: 'Subtitle',
        child: Text('Body'),
      ),
      size: const Size(1280, 900),
    );

    final illustration = tester.widget<AppIllustration>(
      find.byType(AppIllustration),
    );
    expect(illustration.height, 330);
  });
}
