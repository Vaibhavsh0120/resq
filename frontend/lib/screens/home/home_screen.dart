import 'package:flutter/material.dart';

import '../../app/shell/adaptive_app_shell.dart';
import '../../services/auth_service.dart';

/// Entry point retained for the existing authentication/onboarding gate.
/// The connected application itself lives in [AdaptiveAppShell].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.initialDestination = 'home'});

  final String initialDestination;

  @override
  Widget build(BuildContext context) {
    final isGuest = AuthService.instance.currentUser?.isAnonymous ?? false;
    return AdaptiveAppShell(
      isGuest: isGuest,
      initialDestination: initialDestination,
    );
  }
}
