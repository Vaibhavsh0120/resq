import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/auth_service.dart';
import '../../../services/locale_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/theme_mode_button.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';

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
    final protected = {
      'Your readiness',
      'Your information',
      'Manage My Circle',
      'Notification preferences',
      'SOS history',
      'Privacy and AI data access',
    }.contains(label);
    if (isGuest && protected) {
      showModalBottomSheet<void>(
        context: context,
        builder: (context) => const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Sign in with a registered account to save private information and settings.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
      return;
    }
    if (label == 'Your readiness') {
      context.push('/readiness');
    } else if (label == 'Notification preferences') {
      context.push('/profile/notification-preferences');
    } else if (label == 'Manage My Circle') {
      context.go('/app/family');
    } else if (label.startsWith('Language')) {
      _chooseLanguage(context);
    } else if (label == 'Your information') {
      context.push('/profile/information');
    } else if (label == 'SOS history') {
      context.push('/profile/sos-history');
    } else if (label == 'Privacy and AI data access') {
      context.push('/profile/privacy');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label is not available in this build yet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final sections = <({IconData icon, String key, String label})>[
      (
        icon: Icons.fact_check_outlined,
        key: 'Your readiness',
        label: strings.yourReadiness,
      ),
      (
        icon: Icons.badge_outlined,
        key: 'Your information',
        label: strings.yourInformation,
      ),
      (
        icon: Icons.people_alt_outlined,
        key: 'Manage My Circle',
        label: strings.manageMyCircle,
      ),
      (
        icon: Icons.notifications_outlined,
        key: 'Notification preferences',
        label: strings.notificationPreferences,
      ),
      (icon: Icons.sos_outlined, key: 'SOS history', label: strings.sosHistory),
      (
        icon: Icons.privacy_tip_outlined,
        key: 'Privacy and AI data access',
        label: strings.privacyAiAccess,
      ),
      (
        icon: Icons.language_rounded,
        key: 'Language — English / हिन्दी',
        label: strings.language,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(strings.profileSettings)),
      body: AppPageContent(
        maxWidth: 760,
        child: ListView(
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
                          'Notification preferences',
                          'Privacy and AI data access',
                        }.contains(item.key)
                    ? const Icon(Icons.lock_outline_rounded)
                    : const Icon(Icons.chevron_right_rounded),
                onTap: () => _openSection(context, item.key),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.brightness_6_outlined),
              title: Text(strings.appearance),
              trailing: const ThemeModeButton(),
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: Text(strings.logout),
            ),
          ],
        ),
      ),
    );
  }
}
