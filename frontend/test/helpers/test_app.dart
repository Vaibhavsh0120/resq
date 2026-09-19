import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:resq/l10n/app_localizations.dart';
import 'package:resq/app/providers/auth_providers.dart';
import 'package:resq/features/places/application/places_providers.dart';
import 'package:resq/features/updates/application/alerts_providers.dart';
import 'package:resq/features/updates/data/alerts_repository.dart';
import 'package:resq/features/updates/domain/public_alert.dart';
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
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWithValue(null),
        alertsRepositoryProvider.overrideWithValue(_EmptyAlertsRepository()),
        currentPositionProvider.overrideWith(
          (ref) => Future.error(
            const LocationUnavailable('Location unavailable in widget tests.'),
          ),
        ),
      ],
      child: ThemeControllerScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: controller.mode,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

class _EmptyAlertsRepository implements AlertsRepository {
  @override
  Stream<List<PublicAlert>> watchActive() => Stream.value(const []);
}
