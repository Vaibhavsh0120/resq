import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's [ThemeMode] and persists the user's explicit choice.
///
/// Defaults to [ThemeMode.system] (respects the OS/browser preference), and
/// remembers an explicit override across restarts once the user picks one —
/// there's no in-app toggle UI yet this session (out of scope), but the
/// controller is ready for one.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._mode);

  static const _prefsKey = 'resq.theme_mode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    final mode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return ThemeController._(mode);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}

/// Makes the app-wide theme preference available to screens without tying
/// them to the root widget's constructor. Listening widgets rebuild when the
/// selected mode changes.
class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(scope != null, 'ThemeControllerScope is missing above this widget.');
    return scope!.notifier!;
  }
}
