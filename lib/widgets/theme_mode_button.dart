import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/theme_controller.dart';

/// Compact Light / Dark / System selector used throughout the startup flow.
class ThemeModeButton extends StatelessWidget {
  const ThemeModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerScope.of(context);
    return PopupMenuButton<ThemeMode>(
      tooltip: 'Choose appearance',
      initialValue: controller.mode,
      onSelected: (mode) {
        HapticFeedback.selectionClick();
        controller.setMode(mode);
      },
      icon: Icon(_iconFor(controller.mode)),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.system,
          child: ListTile(
            leading: Icon(Icons.brightness_auto_outlined),
            title: Text('System'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: ListTile(
            leading: Icon(Icons.light_mode_outlined),
            title: Text('Light'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: ListTile(
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('Dark'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  IconData _iconFor(ThemeMode mode) => switch (mode) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_outlined,
  };
}
