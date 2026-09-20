import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/navigation/root_router.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'services/app_platform_info.dart';
import 'services/locale_controller.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';
import 'features/notifications/data/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> resqMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolved once, here, before anything else runs — screens/services read
  // AppPlatformInfo.current synchronously from then on (e.g. to skip the
  // startup video on web, or later to branch platform-specific features).
  AppPlatformInfo.resolve();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(resqMessagingBackgroundHandler);

  final themeController = await ThemeController.load();
  final localeController = await LocaleController.load();

  runApp(
    ProviderScope(
      child: ResQApp(
        themeController: themeController,
        localeController: localeController,
      ),
    ),
  );
  await PushNotificationService.instance.configure();
}

class ResQApp extends StatelessWidget {
  const ResQApp({
    super.key,
    required this.themeController,
    required this.localeController,
  });

  final ThemeController themeController;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return LocaleControllerScope(
      controller: localeController,
      child: AnimatedBuilder(
        animation: Listenable.merge([themeController, localeController]),
        builder: (context, _) {
          return ThemeControllerScope(
            controller: themeController,
            child: MaterialApp.router(
              title: 'ResQ',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeController.mode,
              locale: localeController.locale,
              routerConfig: rootRouter,
              supportedLocales: const [Locale('en'), Locale('hi')],
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          );
        },
      ),
    );
  }
}
