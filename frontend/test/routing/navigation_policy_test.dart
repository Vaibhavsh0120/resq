import 'package:flutter_test/flutter_test.dart';
import 'package:resq/routing/navigation_policy.dart';

void main() {
  test('signed-out native user sees startup once, then login', () {
    expect(
      decideAppDestination(
        isAuthenticated: false,
        isAnonymous: false,
        showsStartupVideo: true,
        startupShown: false,
      ),
      AppDestination.startup,
    );
    expect(
      decideAppDestination(
        isAuthenticated: false,
        isAnonymous: false,
        showsStartupVideo: true,
        startupShown: true,
      ),
      AppDestination.login,
    );
  });

  test('web skips startup video', () {
    expect(
      decideAppDestination(
        isAuthenticated: false,
        isAnonymous: false,
        showsStartupVideo: false,
        startupShown: false,
      ),
      AppDestination.login,
    );
  });

  test('guest skips onboarding and registered account does not', () {
    expect(
      decideAppDestination(
        isAuthenticated: true,
        isAnonymous: true,
        showsStartupVideo: true,
        startupShown: false,
      ),
      AppDestination.home,
    );
    expect(
      decideAppDestination(
        isAuthenticated: true,
        isAnonymous: false,
        showsStartupVideo: true,
        startupShown: false,
        onboardingCompleted: false,
      ),
      AppDestination.onboarding,
    );
  });

  test('completed registered account goes home', () {
    expect(
      decideAppDestination(
        isAuthenticated: true,
        isAnonymous: false,
        showsStartupVideo: true,
        startupShown: false,
        onboardingCompleted: true,
      ),
      AppDestination.home,
    );
  });
}
