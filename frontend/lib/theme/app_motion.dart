import 'package:flutter/material.dart';

/// Shared animation constants so motion feels consistent across the auth
/// flow — one orchestrated feel rather than ad hoc durations per screen.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuint;

  /// A gentle fade + upward slide, used when navigating between the auth
  /// screens (Login ↔ Sign up ↔ Forgot password) so the flow reads as one
  /// connected sequence rather than a hard cut.
  static Route<T> fadeThrough<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: medium,
      reverseTransitionDuration: fast,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: emphasized);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Cross-fade used when swapping the whole app root (startup → auth/home),
  /// where a slide would feel like unwanted spatial motion.
  static Route<T> crossFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: slow,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: standard),
          child: child,
        );
      },
    );
  }
}
