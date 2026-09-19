import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/models/user_profile.dart';
import 'package:resq/screens/auth/forgot_password_screen.dart';
import 'package:resq/screens/auth/login_screen.dart';
import 'package:resq/screens/auth/signup_screen.dart';
import 'package:resq/screens/onboarding/onboarding_flow.dart';

import '../helpers/test_app.dart';

void main() {
  const targets = <String, Size>{
    'iPhone': Size(390, 844),
    'iPad portrait': Size(1024, 1366),
    'iPad landscape': Size(1366, 1024),
    'PC': Size(1536, 900),
  };

  for (final target in targets.entries) {
    testWidgets('${target.key} layouts render without overflow', (
      tester,
    ) async {
      final screens = <Widget>[
        const LoginScreen(),
        const SignupScreen(),
        const ForgotPasswordScreen(),
        const OnboardingFlow(initialProfile: UserProfile(uid: 'step-1')),
        const OnboardingFlow(
          initialProfile: UserProfile(uid: 'step-2', resumeStep: 2),
        ),
        const OnboardingFlow(
          initialProfile: UserProfile(uid: 'step-3', resumeStep: 3),
        ),
        const OnboardingFlow(
          initialProfile: UserProfile(uid: 'step-4', resumeStep: 4),
        ),
      ];

      for (final screen in screens) {
        await pumpTestApp(tester, screen, size: target.value);
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '$screen on ${target.key}',
        );
      }
    });
  }
}
