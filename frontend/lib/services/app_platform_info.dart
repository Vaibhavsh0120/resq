import 'package:flutter/foundation.dart';

/// The concrete platform ResQ is currently running on, resolved once at
/// startup. Kept as its own small enum (rather than reaching for
/// `defaultTargetPlatform`/`kIsWeb` all over the codebase) so future
/// features can gate behavior with a single, readable check — e.g. hiding
/// the startup video on web, choosing SMS vs push for alerts, or picking a
/// share sheet implementation per platform.
enum AppPlatform { android, ios, web, macos, windows, linux, unknown }

/// Resolves and caches [AppPlatform] for the lifetime of the app.
///
/// Read via [AppPlatformInfo.current] anywhere after [AppPlatformInfo.resolve]
/// has run once (done in `main()` before `runApp`), or call
/// [AppPlatformInfo.resolve] directly if a value is needed before then.
class AppPlatformInfo {
  AppPlatformInfo._();

  static AppPlatform? _cached;

  /// The resolved platform. Falls back to resolving on first access if
  /// `main()` hasn't called [resolve] yet (e.g. in tests).
  static AppPlatform get current => _cached ??= resolve();

  static bool get isWeb => current == AppPlatform.web;
  static bool get isAndroid => current == AppPlatform.android;
  static bool get isIOS => current == AppPlatform.ios;
  static bool get isDesktop =>
      current == AppPlatform.macos ||
      current == AppPlatform.windows ||
      current == AppPlatform.linux;

  /// True on the platforms the startup video is meant for — native mobile
  /// only. Web loads straight into the auth check.
  static bool get showsStartupVideo => isAndroid || isIOS;

  static AppPlatform resolve() {
    if (kIsWeb) return AppPlatform.web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AppPlatform.android;
      case TargetPlatform.iOS:
        return AppPlatform.ios;
      case TargetPlatform.macOS:
        return AppPlatform.macos;
      case TargetPlatform.windows:
        return AppPlatform.windows;
      case TargetPlatform.linux:
        return AppPlatform.linux;
      default:
        return AppPlatform.unknown;
    }
  }
}
