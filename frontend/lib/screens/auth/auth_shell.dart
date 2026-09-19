import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_surfaces.dart';
import '../../widgets/brand_mark.dart';
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

  static const double _cardMaxWidth = 560;

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
      body: AppBackground(
        child: Stack(
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
                          flex: 5,
                          child: FadeTransition(
                            opacity: _fade,
                            child: const _BrandPanel(),
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: AuthShell._cardMaxWidth,
                              ),
                              child: ScrollConfiguration(
                                behavior: ScrollConfiguration.of(context)
                                    .copyWith(scrollbars: false),
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                  ),
                                  child: formCard,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (AppBreakpoints.isCompact(width)) {
                    final compactCard = FadeTransition(
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
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AuthShell._cardMaxWidth,
                        ),
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(scrollbars: false),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.md,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            child: compactCard,
                          ),
                        ),
                      ),
                    );
                  }

                  // Medium and compact widths: centered card, no brand panel.
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AuthShell._cardMaxWidth,
                      ),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context)
                            .copyWith(scrollbars: false),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            vertical: AppBreakpoints.isCompact(width)
                                ? AppSpacing.md
                                : AppSpacing.xl,
                            horizontal: AppBreakpoints.isCompact(width)
                                ? AppSpacing.lg
                                : AppSpacing.xl,
                          ),
                          child: formCard,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (AppBreakpoints.isExpanded(MediaQuery.sizeOf(context).width))
              const Positioned(
                top: 8,
                right: 8,
                child: SafeArea(child: ThemeModeButton()),
              ),
          ],
        ),
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = AppBreakpoints.isCompact(width);
    final expanded = AppBreakpoints.isExpanded(width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!expanded) ...[
          Row(
            children: [
              ResQBrandMark(size: compact ? 28 : 42, showWordmark: true),
              const Spacer(),
              const ThemeModeButton(),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.xl),
        ],
        AppSectionCard(
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
              child,
            ],
          ),
        ),
        if (footer != null) ...[const SizedBox(height: AppSpacing.md), footer!],
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
    final bg = isDark ? const Color(0xFF111113) : const Color(0xFF123B3A);
    const fg = Color(0xFFFFFDF8);

    return Container(
      color: bg,
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const ResQBrandMark(size: 64),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Safety feels better when you are prepared.',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(color: fg, fontSize: 34),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: 320,
                child: Text(
                  'Keep the details and people that matter close, so you can act with confidence when every second counts.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: fg.withValues(alpha: 0.75),
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your safety, one tap away.',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(color: fg),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Center(
                child: AppIllustration(
                  'assets/illustrations/auth_safety.png',
                  height: 330,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
