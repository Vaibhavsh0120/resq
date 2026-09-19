import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/services/theme_controller.dart';
import 'package:resq/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ThemeController> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(390, 844),
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final controller = await ThemeController.load();
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ThemeControllerScope(
      controller: controller,
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.mode,
        home: child,
      ),
    ),
  );
  await tester.pump();
  return controller;
}
