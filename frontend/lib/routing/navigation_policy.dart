/// Pure routing decision used by [AuthGate] and unit tests.
enum AppDestination { startup, login, onboarding, home }

AppDestination decideAppDestination({
  required bool isAuthenticated,
  required bool isAnonymous,
  required bool showsStartupVideo,
  required bool startupShown,
  bool? onboardingCompleted,
}) {
  if (!isAuthenticated) {
    return showsStartupVideo && !startupShown
        ? AppDestination.startup
        : AppDestination.login;
  }
  if (isAnonymous) return AppDestination.home;
  return onboardingCompleted == true
      ? AppDestination.home
      : AppDestination.onboarding;
}
