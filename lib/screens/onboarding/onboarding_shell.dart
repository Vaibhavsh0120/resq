import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/theme_mode_button.dart';

/// Shared chrome for all 4 onboarding steps: an animated progress bar,
/// "Step X of 4" label, and Back/Cancel navigation.
///
/// - Step 1: shows **Cancel** (signs out, returns to Login) — starting
///   onboarding is easy to back out of entirely.
/// - Steps 2–4: shows **Back** to the previous step instead — once personal
///   info exists, backing out of the whole flow is a bigger, more
///   deliberate action than just revisiting the prior step.
///
/// Layout follows the same responsive approach as [AuthShell]: full-bleed
/// scrollable form on phones, a centered max-width card on tablet/desktop
/// so a 4-step form doesn't stretch edge-to-edge on a Mac window.
class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onBackOrCancel,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.isNextLoading = false,
    this.isNextEnabled = true,
  });

  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onBackOrCancel;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isNextLoading;
  final bool isNextEnabled;

  static const double _cardMaxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isFirstStep = step == 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _cardMaxWidth),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onBackOrCancel();
                      },
                      icon: Icon(
                        isFirstStep ? Icons.close : Icons.arrow_back,
                        size: 18,
                      ),
                      label: Text(isFirstStep ? 'Cancel' : 'Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    const ThemeModeButton(),
                    Text(
                      'Step $step of $totalSteps',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _cardMaxWidth),
                  child: _ProgressBar(step: step, totalSteps: totalSteps),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                      AppBreakpoints.isCompact(constraints.maxWidth)
                      ? AppSpacing.lg
                      : AppSpacing.xl;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: AppSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _cardMaxWidth,
                        ),
                        child: AnimatedSwitcher(
                          duration: AppMotion.medium,
                          switchInCurve: AppMotion.emphasized,
                          transitionBuilder: (widgetChild, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.04, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: widgetChild,
                                ),
                              ),
                          child: Column(
                            key: ValueKey(step),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              child,
                              const SizedBox(height: AppSpacing.xxl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _cardMaxWidth),
                  child: FilledButton(
                    onPressed: isNextEnabled && !isNextLoading && onNext != null
                        ? () {
                            HapticFeedback.lightImpact();
                            onNext!();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.base),
                      ),
                    ),
                    child: isNextLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(nextLabel),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.step, required this.totalSteps});

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < step;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? scheme.secondary
                    : scheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
        );
      }),
    );
  }
}
