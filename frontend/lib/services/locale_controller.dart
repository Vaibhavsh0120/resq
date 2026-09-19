import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController._(this._locale);

  static const _prefsKey = 'resq.locale';
  Locale? _locale;
  Locale? get locale => _locale;

  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString(_prefsKey);
    return LocaleController._(language == null ? null : Locale(language));
  }

  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}

class LocaleControllerScope extends InheritedNotifier<LocaleController> {
  const LocaleControllerScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocaleControllerScope>();
    assert(
      scope != null,
      'LocaleControllerScope is missing above this widget.',
    );
    return scope!.notifier!;
  }
}
