import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/theme/app_theme.dart';
import 'package:resq/widgets/app_surfaces.dart';
import 'package:resq/widgets/brand_mark.dart';

void main() {
  testWidgets('brand mark exposes a single image semantic', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: ResQBrandMark()),
      ),
    );

    expect(find.bySemanticsLabel('ResQ'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('section card supports large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: AppSectionCard(
                child: Text(
                  'Emergency access remains available without an account.',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
