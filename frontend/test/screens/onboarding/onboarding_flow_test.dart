import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/models/user_profile.dart';
import 'package:resq/screens/onboarding/onboarding_flow.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets(
    'new profile starts at step one with Cancel and disabled Continue',
    (tester) async {
      await pumpTestApp(
        tester,
        const OnboardingFlow(initialProfile: UserProfile(uid: 'u1')),
      );
      expect(find.text('Step 1 of 4'), findsOneWidget);
      expect(find.text('Personal info'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Continue'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('saved progress resumes at the recorded step', (tester) async {
    await pumpTestApp(
      tester,
      const OnboardingFlow(
        initialProfile: UserProfile(uid: 'u2', resumeStep: 3),
      ),
    );
    expect(find.text('Step 3 of 4'), findsOneWidget);
    expect(find.text('Family circle'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('resume step is clamped to the four-step flow', (tester) async {
    await pumpTestApp(
      tester,
      const OnboardingFlow(
        initialProfile: UserProfile(uid: 'u3', resumeStep: 99),
      ),
    );
    expect(find.text('Step 4 of 4'), findsOneWidget);
    expect(find.text('Home location'), findsOneWidget);
    expect(find.text('Finish setup'), findsOneWidget);
  });
}
