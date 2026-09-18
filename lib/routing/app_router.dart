import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/onboarding/onboarding_flow.dart';
import '../screens/startup/startup_screen.dart';
import '../services/app_platform_info.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

/// App root: decides between the startup video, the auth flow, onboarding,
/// and Home based on [AuthService.authStateChanges] — the single source of
/// truth for navigation at this level.
///
/// Flow:
/// 1. Not signed in yet → [StartupScreen] (native mobile only — see
///    [AppPlatformInfo.showsStartupVideo]) once, then [LoginScreen].
/// 2. Signed in, anonymous (Emergency access) → straight to [HomeScreen];
///    guests must never be blocked by onboarding.
/// 3. Signed in, real account, onboarding incomplete → [OnboardingFlow],
///    resuming at whatever step their profile says they reached.
/// 4. Signed in, onboarding complete → [HomeScreen].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // The startup video (native mobile only) plays once per app launch, not
  // once per sign-out/sign-in within the same session — a returning-to-
  // login screen after logout shouldn't replay the splash.
  bool _startupShown = !AppPlatformInfo.showsStartupVideo;

  void _markStartupShown() => setState(() => _startupShown = true);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        final user = snapshot.data;
        if (user == null) {
          if (!_startupShown) {
            return StartupScreen(onFinished: _markStartupShown);
          }
          return const LoginScreen();
        }

        // Emergency/guest access must never be gated by onboarding.
        if (user.isAnonymous) {
          return const HomeScreen();
        }

        return _OnboardingGate(uid: user.uid);
      },
    );
  }
}

/// Reads (and streams) the signed-in user's Firestore profile to decide
/// Onboarding vs Home. Kept separate from [AuthGate] so the profile stream
/// only exists while a real (non-anonymous) user is signed in.
class _OnboardingGate extends StatelessWidget {
  const _OnboardingGate({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile>(
      stream: UserProfileService.instance.watchProfile(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _SplashLoader();
        }
        final profile = snapshot.data!;
        if (profile.onboardingCompleted) {
          return const HomeScreen();
        }
        return OnboardingFlow(initialProfile: profile);
      },
    );
  }
}

class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
