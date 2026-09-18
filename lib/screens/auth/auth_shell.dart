import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/theme_mode_button.dart';

/// Shared layout shell for Login / Sign up / Forgot password.
///
/// - Phone widths (< [AppBreakpoints.compact]): full-bleed, scrollable,
///   padded form — no side panel, so nothing crowds a small screen.
/// - Tablet/desktop widths (>= [AppBreakpoints.expanded]): a branding panel
///   on the leading side and a centered, max-width form card on the
///   trailing side — so the form never stretches edge-to-edge on a Mac or
///   iPad landscape window, which would look broken.
/// - The in-between range gets the same centered-card treatment without the
///   branding panel, since there isn't width to spare for both.
class AuthShell extends StatefulWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Optional footer row below the card (e.g. "Don't have an account? Sign up").
  final Widget? footer;

  static const double _cardMaxWidth = 440;

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
    _fade = CurvedAnimation(parent: _controller, curve: AppMotion.standard);
    _slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.emphasized),
        );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final showBrandPanel = AppBreakpoints.isExpanded(width);

                final formCard = FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: _FormCard(
                      title: widget.title,
                      subtitle: widget.subtitle,
                      footer: widget.footer,
                      child: widget.child,
                    ),
                  ),
                );

                if (showBrandPanel) {
                  return Row(
                    children: [
                      Expanded(
                        child: FadeTransition(
                          opacity: _fade,
                          child: const _BrandPanel(),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AuthShell._cardMaxWidth,
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl,
                                horizontal: AppSpacing.lg,
                              ),
                              child: formCard,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Medium and compact widths: centered card, no brand panel.
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AuthShell._cardMaxWidth,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                        horizontal: AppBreakpoints.isCompact(width)
                            ? AppSpacing.lg
                            : AppSpacing.xl,
                      ),
                      child: formCard,
                    ),
                  ),
                );
              },
            ),
          ),
          const Positioned(
            top: 8,
            right: 8,
            child: SafeArea(child: ThemeModeButton()),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        child,
        if (footer != null) ...[const SizedBox(height: AppSpacing.lg), footer!],
      ],
    );
  }
}

/// Leading branding panel shown only on wide (tablet-landscape/desktop)
/// layouts — charcoal surface, the ResQ mark, and a short reassurance line.
/// Never shown on phone widths, where every pixel goes to the form.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkSurface : AppColors.lightForeground;
    final fg = isDark ? AppColors.darkForeground : AppColors.lightSurface;

    return Container(
      color: bg,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ResQ',
            style: Theme.of(context).textTheme.displayLarge
                ?.copyWith(color: fg, fontSize: 40),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: 320,
            child: Text(
              'Fast access. Clear guidance. Responsible assistance. '
              'Your safety, one tap away.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: fg.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }
}
