import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'routing/app_router.dart';
import 'services/app_platform_info.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Resolved once, here, before anything else runs — screens/services read
  // AppPlatformInfo.current synchronously from then on (e.g. to skip the
  // startup video on web, or later to branch platform-specific features).
  AppPlatformInfo.resolve();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final themeController = await ThemeController.load();

  runApp(ResQApp(themeController: themeController));
}

class ResQApp extends StatelessWidget {
  const ResQApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ThemeControllerScope(
      controller: themeController,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) {
          return MaterialApp(
            title: 'ResQ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.mode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
