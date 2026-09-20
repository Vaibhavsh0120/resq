import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPageContent extends StatelessWidget {
  const AppPageContent({super.key, required this.child, this.maxWidth = 920});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF0D0D0F), Color(0xFF151517)]
              : const [Color(0xFFF9F6EF), Color(0xFFF0F6F1)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: -100,
            child: _Glow(
              color: dark
                  ? Colors.white.withValues(alpha: .025)
                  : AppColors.accent.withValues(alpha: .08),
              size: 300,
            ),
          ),
          Positioned(
            left: -120,
            bottom: -130,
            child: _Glow(
              color: dark
                  ? Colors.white.withValues(alpha: .018)
                  : AppColors.emergency.withValues(alpha: .06),
              size: 340,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );
}

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.showShadow = true,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: showShadow
            ? AppShadows.card(Theme.of(context).brightness)
            : null,
      ),
      child: Material(
        color: color ?? scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AppIllustration extends StatelessWidget {
  const AppIllustration(this.asset, {super.key, this.height = 180});
  final String asset;
  final double height;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      asset,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    ),
  );
}

class AppIconTile extends StatelessWidget {
  const AppIconTile({
    super.key,
    required this.icon,
    this.color = AppColors.accent,
    this.size = 52,
  });
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(AppRadius.base),
    ),
    child: Icon(icon, color: color),
  );
}
