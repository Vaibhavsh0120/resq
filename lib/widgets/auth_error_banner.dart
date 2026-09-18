import 'package:flutter/material.dart';

import '../theme/app_motion.dart';
import '../theme/app_theme.dart';

/// Inline error banner shown at the top of an auth form.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: scheme.error, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps [AuthErrorBanner] so it grows/fades in and shrinks/fades out
/// smoothly as [message] changes, instead of popping in and out of the
/// layout instantly. Always present in the tree (zero-height when there's
/// no message) — screens using this don't need their own `if (error !=
/// null)` conditional in the widget list.
class AnimatedAuthError extends StatelessWidget {
  const AnimatedAuthError({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final hasMessage = message != null;
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.medium,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
        child: hasMessage
            ? Padding(
                key: ValueKey(message),
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AuthErrorBanner(message: message!),
              )
            : const SizedBox.shrink(key: ValueKey('no-error')),
      ),
    );
  }
}
