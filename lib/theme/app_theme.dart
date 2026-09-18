import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ResQ's design system: "Sharp Light" (Better Design's precision-light
/// system) in light mode, with a derived — not inverted — dark mode.
///
/// Token reference (see `docs/architecture.md` for project-wide guidance):
/// - Base unit radius: 10px, scaled up/down for different component sizes.
/// - Primary: charcoal near-black (not pure black).
/// - Accent / focus / ring: blue `#335CFF`.
/// - Precision shadows: a crisp 1px outer border/ring + a soft, tight-radius
///   drop shadow — never large/diffuse.
class AppColors {
  AppColors._();

  /// Identical in both modes per the design system spec — contrast against
  /// both backgrounds is already sufficient, so it is not lightened for dark.
  static const Color accent = Color(0xFF335CFF);
  static const Color accentForeground = Color(0xFFFAFAFA);

  // Light mode
  static const Color lightBackground = Color(0xFFF7F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightForeground = Color(0xFF18181B);
  static const Color lightMuted = Color(0xFFF4F4F5);
  static const Color lightMutedForeground = Color(0xFF71717A);
  static const Color lightPrimary = Color(0xFF18181B); // charcoal near-black
  static const Color lightPrimaryForeground = Color(0xFFFAFAFA);
  static const Color lightDestructive = Color(0xFFDC2626);
  static const Color lightDestructiveForeground = Color(0xFFFAFAFA);
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color lightWarning = Color(0xFFB45309);

  // Dark mode — a genuine dark counterpart, not an inversion: deep neutral
  // charcoal (no blue/purple tint), slightly raised surfaces, off-white text.
  static const Color darkBackground = Color(0xFF0A0A0B);
  static const Color darkSurface = Color(0xFF141416);
  static const Color darkBorder = Color(0xFF2A2A2E);
  static const Color darkForeground = Color(0xFFF4F4F5);
  static const Color darkMuted = Color(0xFF1C1C1F);
  static const Color darkMutedForeground = Color(0xFFA1A1AA);
  static const Color darkPrimary = Color(
    0xFFF4F4F5,
  ); // light-on-dark, inverted role
  static const Color darkPrimaryForeground = Color(0xFF18181B);
  static const Color darkDestructive = Color(0xFFF87171);
  static const Color darkDestructiveForeground = Color(0xFF1B0000);
  static const Color darkSuccess = Color(0xFF4ADE80);
  static const Color darkWarning = Color(0xFFFBBF24);
}

/// Precision multi-layer shadows: a crisp 1px outer ring plus a soft,
/// tight-radius drop shadow. Never large/diffuse per the design system.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
        blurRadius: 10,
        spreadRadius: -2,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> raised(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.10),
        blurRadius: 24,
        spreadRadius: -6,
        offset: const Offset(0, 12),
      ),
    ];
  }
}

/// 10px base radius, scaled for component size — smaller for compact
/// controls (checkboxes/badges), larger for containers (dialogs/cards).
class AppRadius {
  AppRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double base = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double full = 999;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Responsive breakpoints (logical px) used across the auth flow so layouts
/// hold up on iPhone, iPad (portrait/landscape), and Mac/desktop windows.
class AppBreakpoints {
  AppBreakpoints._();

  static const double compact = 600; // phones
  static const double expanded = 1100; // iPad landscape, laptop+

  static bool isCompact(double width) => width < compact;
  static bool isExpanded(double width) => width >= expanded;
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color foreground, Color muted) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: foreground,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: foreground,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: foreground,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: foreground,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: FontWeight.w400,
        color: foreground,
        height: 1.5,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontWeight: FontWeight.w400,
        color: foreground,
        height: 1.5,
      ),
      bodySmall: base.bodySmall?.copyWith(color: muted, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: foreground,
      ),
      labelMedium: base.labelMedium?.copyWith(color: muted),
      labelSmall: base.labelSmall?.copyWith(color: muted),
    );
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final foreground = isDark
        ? AppColors.darkForeground
        : AppColors.lightForeground;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final mutedForeground = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final primaryForeground = isDark
        ? AppColors.darkPrimaryForeground
        : AppColors.lightPrimaryForeground;
    final destructive = isDark
        ? AppColors.darkDestructive
        : AppColors.lightDestructive;
    final destructiveForeground = isDark
        ? AppColors.darkDestructiveForeground
        : AppColors.lightDestructiveForeground;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: primaryForeground,
      secondary: AppColors.accent,
      onSecondary: AppColors.accentForeground,
      error: destructive,
      onError: destructiveForeground,
      surface: surface,
      onSurface: foreground,
      surfaceContainerHighest: muted,
      onSurfaceVariant: mutedForeground,
      outline: border,
      outlineVariant: border,
      inversePrimary: isDark ? AppColors.lightPrimary : AppColors.darkPrimary,
      inverseSurface: isDark ? AppColors.lightSurface : AppColors.darkSurface,
      onInverseSurface: isDark
          ? AppColors.lightForeground
          : AppColors.darkForeground,
      tertiary: AppColors.accent,
      onTertiary: AppColors.accentForeground,
      shadow: Colors.black,
      scrim: Colors.black.withValues(alpha: 0.5),
    );

    final textTheme = _textTheme(foreground, mutedForeground);
    final fontFamily = GoogleFonts.inter().fontFamily;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: fontFamily,
      textTheme: textTheme,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          mutedForeground.withValues(alpha: 0.4),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.accent,
        selectionColor: AppColors.accent.withValues(alpha: 0.25),
        selectionHandleColor: AppColors.accent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkMuted : AppColors.lightSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 16,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: mutedForeground),
        labelStyle: textTheme.bodyMedium?.copyWith(color: mutedForeground),
        errorStyle: textTheme.bodySmall?.copyWith(color: destructive),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide(color: destructive, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide(color: destructive, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          disabledBackgroundColor: mutedForeground.withValues(alpha: 0.3),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: foreground,
          side: BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.base),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: foreground,
          highlightColor: AppColors.accent.withValues(alpha: 0.1),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        side: BorderSide(color: border, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkMuted : AppColors.darkSurface,
        contentTextStyle:
            (fontFamily != null
                    ? TextStyle(fontFamily: fontFamily)
                    : const TextStyle())
                .copyWith(
                  color: isDark
                      ? AppColors.darkForeground
                      : AppColors.lightSurface,
                ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}
