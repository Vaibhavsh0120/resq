import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The calm-safety visual language used throughout ResQ.
class AppColors {
  AppColors._();

  static const accent = Color(0xFF2F7D73);
  static const accentForeground = Color(0xFFFFFFFF);
  static const emergency = Color(0xFFE56B67);
  static const gold = Color(0xFFF1B84B);
  static const lightBackground = Color(0xFFF6F2E9);
  static const lightSurface = Color(0xFFFFFDF8);
  static const lightSurfaceRaised = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFDDE4DE);
  static const lightForeground = Color(0xFF16312F);
  static const lightMuted = Color(0xFFEAF1ED);
  static const lightMutedForeground = Color(0xFF5F7470);
  static const lightPrimary = Color(0xFF123B3A);
  static const lightPrimaryForeground = Color(0xFFFFFFFF);
  static const lightDestructive = Color(0xFFB83F42);
  static const lightSuccess = Color(0xFF287A57);
  static const lightWarning = Color(0xFF946200);
  static const darkBackground = Color(0xFF0D0D0F);
  static const darkSurface = Color(0xFF171719);
  static const darkSurfaceRaised = Color(0xFF202023);
  static const darkBorder = Color(0xFF343438);
  static const darkForeground = Color(0xFFF5F5F4);
  static const darkMuted = Color(0xFF242427);
  static const darkMutedForeground = Color(0xFFAAAAB1);
  static const darkPrimary = Color(0xFFF0F0EE);
  static const darkPrimaryForeground = Color(0xFF171719);
  static const darkDestructive = Color(0xFFFF8D88);
  static const darkSuccess = Color(0xFF75D2A2);
  static const darkWarning = Color(0xFFFFCC69);
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> card(Brightness brightness) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: brightness == Brightness.dark ? 0.22 : 0.055,
      ),
      blurRadius: 22,
      spreadRadius: -8,
      offset: const Offset(0, 10),
    ),
  ];
  static List<BoxShadow> raised(Brightness brightness) => [
    BoxShadow(
      color: Colors.black.withValues(
        alpha: brightness == Brightness.dark ? 0.32 : 0.08,
      ),
      blurRadius: 38,
      spreadRadius: -12,
      offset: const Offset(0, 18),
    ),
  ];
}

class AppRadius {
  AppRadius._();
  static const double xs = 8,
      sm = 12,
      base = 16,
      md = 20,
      lg = 24,
      xl = 32,
      full = 999;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32, xxl = 48;
}

class AppBreakpoints {
  AppBreakpoints._();
  static const double compact = 600, expanded = 1100;
  static bool isCompact(double width) => width < compact;
  static bool isExpanded(double width) => width >= expanded;
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color foreground, Color muted) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.8,
        color: foreground,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: foreground,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.7,
        color: foreground,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -.4,
        color: foreground,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: foreground, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(color: foreground, height: 1.5),
      bodySmall: base.bodySmall?.copyWith(color: muted, height: 1.45),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: foreground,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: muted,
      ),
    );
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final foreground = dark
        ? AppColors.darkForeground
        : AppColors.lightForeground;
    final muted = dark ? AppColors.darkMuted : AppColors.lightMuted;
    final mutedForeground = dark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final primary = dark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final onPrimary = dark
        ? AppColors.darkPrimaryForeground
        : AppColors.lightPrimaryForeground;
    final error = dark ? AppColors.darkDestructive : AppColors.lightDestructive;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.accentForeground,
      error: error,
      onError: Colors.white,
      surface: surface,
      onSurface: foreground,
      surfaceContainerHighest: muted,
      onSurfaceVariant: mutedForeground,
      outline: border,
      outlineVariant: border,
    );
    final textTheme = _textTheme(foreground, mutedForeground);
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.base),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: AppColors.accent,
        scaffoldBackgroundColor: background,
        textTheme: CupertinoTextThemeData(textStyle: textTheme.bodyMedium),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF222225) : const Color(0xFFFBFCF9),
        hintStyle: textTheme.bodyMedium?.copyWith(color: mutedForeground),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        prefixIconColor: mutedForeground,
        suffixIconColor: mutedForeground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
          borderSide: BorderSide(color: error, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: muted,
          disabledForegroundColor: mutedForeground,
          textStyle: textTheme.labelLarge,
          shape: rounded,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 54),
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: muted,
          disabledForegroundColor: mutedForeground,
          textStyle: textTheme.labelLarge,
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
          foregroundColor: foreground,
          side: BorderSide(color: border),
          textStyle: textTheme.labelLarge,
          shape: rounded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.accent,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        selectedColor: AppColors.accent.withValues(alpha: dark ? .32 : .14),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: foreground),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      dividerColor: border,
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: foreground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      focusColor: AppColors.accent.withValues(alpha: .18),
    );
  }
}
