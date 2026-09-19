import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/theme_mode_button.dart';

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

  static const _maxWidth = 760.0;
  static const _stepNames = ['About you', 'Health', 'Circle', 'Location'];

  @override
  Widget build(BuildContext context) {
    final isFirst = step == 1;
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Row(
                      children: [
                        const ResQBrandMark(size: 38, showWordmark: true),
                        const Spacer(),
                        const ThemeModeButton(),
                        const SizedBox(width: AppSpacing.xs),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            onBackOrCancel();
                          },
                          icon: Icon(
                            isFirst
                                ? Icons.close_rounded
                                : Icons.arrow_back_rounded,
                            size: 18,
                          ),
                          label: Text(isFirst ? 'Cancel' : 'Back'),
                          style: TextButton.styleFrom(
                            foregroundColor: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
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
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: _Progress(
                      step: step,
                      totalSteps: totalSteps,
                      names: _stepNames,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width)
                        ? AppSpacing.md
                        : AppSpacing.xl,
                    AppSpacing.lg,
                    AppBreakpoints.isCompact(MediaQuery.sizeOf(context).width)
                        ? AppSpacing.md
                        : AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: _maxWidth),
                      child: AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : AppMotion.medium,
                        switchInCurve: AppMotion.emphasized,
                        transitionBuilder: (content, animation) =>
                            FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween(
                                  begin: const Offset(.025, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: content,
                              ),
                            ),
                        child: Column(
                          key: ValueKey(step),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Step $step of $totalSteps',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: AppColors.accent),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            AppSectionCard(
                              padding: EdgeInsets.all(
                                AppBreakpoints.isCompact(
                                      MediaQuery.sizeOf(context).width,
                                    )
                                    ? AppSpacing.md
                                    : AppSpacing.lg,
                              ),
                              child: child,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: .96),
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed:
                                isNextEnabled &&
                                    !isNextLoading &&
                                    onNext != null
                                ? () {
                                    HapticFeedback.lightImpact();
                                    onNext!();
                                  }
                                : null,
                            icon: isNextLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                    ),
                                  )
                                : Icon(
                                    step == totalSteps
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                  ),
                            label: Text(isNextLoading ? 'Saving…' : nextLabel),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.step,
    required this.totalSteps,
    required this.names,
  });
  final int step;
  final int totalSteps;
  final List<String> names;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Onboarding progress, step $step of $totalSteps: ${names[step - 1]}',
    child: Row(
      children: List.generate(totalSteps, (index) {
        final number = index + 1;
        final complete = number < step;
        final active = number == step;
        final color = complete || active
            ? AppColors.accent
            : Theme.of(context).colorScheme.outlineVariant;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == totalSteps - 1 ? 0 : AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: AppMotion.medium,
                  height: active ? 6 : 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  names[index],
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: active ? AppColors.accent : null,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ),
  );
}
