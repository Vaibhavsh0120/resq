import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/screens/startup/startup_screen.dart';

void main() {
  testWidgets('light startup presentation is plain white and skips on tap', (
    tester,
  ) async {
    var skipped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: StartupVideoPresentation(
          onTap: () => skipped = true,
          child: const ColoredBox(
            key: Key('video-content'),
            color: Colors.grey,
          ),
        ),
      ),
    );

    final background = tester.widget<ColoredBox>(
      find.byKey(const Key('startup-background')),
    );
    final fittedVideo = tester.widget<FittedBox>(
      find.byKey(const Key('startup-video-fit')),
    );

    expect(background.color, Colors.white);
    expect(fittedVideo.fit, BoxFit.contain);
    expect(find.byType(Text), findsNothing);
    expect(find.byType(Icon), findsNothing);

    await tester.tap(find.byKey(const Key('startup-tap-target')));
    expect(skipped, isTrue);
  });

  testWidgets('dark startup presentation is plain black', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: StartupVideoPresentation(onTap: () {}, child: const SizedBox()),
      ),
    );

    final background = tester.widget<ColoredBox>(
      find.byKey(const Key('startup-background')),
    );
    expect(background.color, Colors.black);
  });
}
