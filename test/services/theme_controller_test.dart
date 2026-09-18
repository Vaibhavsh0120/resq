import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/services/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to system mode', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = await ThemeController.load();
    expect(controller.mode, ThemeMode.system);
  });

  test('loads and persists an explicit theme', () async {
    SharedPreferences.setMockInitialValues({'resq.theme_mode': 'dark'});
    final controller = await ThemeController.load();
    expect(controller.mode, ThemeMode.dark);

    await controller.setMode(ThemeMode.light);
    final reloaded = await ThemeController.load();
    expect(reloaded.mode, ThemeMode.light);
  });
}
