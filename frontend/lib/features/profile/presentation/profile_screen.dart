import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../services/locale_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/theme_mode_button.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../readiness/presentation/readiness_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.isGuest});

  final bool isGuest;

  Future<void> _logout(BuildContext context) async {
    await AuthService.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final controller = LocaleControllerScope.of(context);
    final locale = await showModalBottomSheet<Locale?>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android_rounded),
              title: const Text('Use device language'),
              onTap: () => Navigator.pop(context, const Locale('und')),
            ),
            ListTile(
              title: const Text('English'),
              onTap: () => Navigator.pop(context, const Locale('en')),
            ),
            ListTile(
              title: const Text('हिन्दी'),
              onTap: () => Navigator.pop(context, const Locale('hi')),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || locale == null) return;
    await controller.setLocale(locale.languageCode == 'und' ? null : locale);
  }

  void _openSection(BuildContext context, String label) {
    if (label == 'Your readiness') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReadinessScreen(isGuest: isGuest),
        ),
      );
    } else if (label == 'Notification preferences') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
      );
    } else if (label.startsWith('Language')) {
      _chooseLanguage(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label is ready for connected account data.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sections = <({IconData icon, String label})>[
      (icon: Icons.fact_check_outlined, label: 'Your readiness'),
      (icon: Icons.badge_outlined, label: 'Your information'),
      (icon: Icons.people_alt_outlined, label: 'Manage My Circle'),
      (icon: Icons.notifications_outlined, label: 'Notification preferences'),
      (icon: Icons.sos_outlined, label: 'SOS history'),
      (icon: Icons.privacy_tip_outlined, label: 'Privacy and AI data access'),
      (icon: Icons.language_rounded, label: 'Language — English / हिन्दी'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Profile and settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CircleAvatar(
            radius: 38,
            child: Icon(
              isGuest ? Icons.shield_outlined : Icons.person_rounded,
              size: 36,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isGuest ? 'Emergency guest' : 'Your ResQ profile',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          ...sections.map(
            (item) => ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              trailing:
                  isGuest &&
                      const {
                        'Your readiness',
                        'Your information',
                        'Manage My Circle',
                        'SOS history',
                      }.contains(item.label)
                  ? const Icon(Icons.lock_outline_rounded)
                  : const Icon(Icons.chevron_right_rounded),
              onTap: () => _openSection(context, item.label),
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.brightness_6_outlined),
            title: Text('Appearance'),
            trailing: ThemeModeButton(),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
