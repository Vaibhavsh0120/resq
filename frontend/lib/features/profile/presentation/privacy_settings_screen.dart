import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';
import '../data/app_settings_repository.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key, required this.notificationsOnly});
  final bool notificationsOnly;

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _repository = AppSettingsRepository(FirebaseFirestore.instance);
  AppSettings? _settings;
  bool _saving = false;

  Future<void> _save(AppSettings value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() {
      _settings = value;
      _saving = true;
    });
    try {
      await _repository.save(uid, value);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to manage settings.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.notificationsOnly
              ? 'Notification preferences'
              : 'Privacy and AI data access',
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: StreamBuilder<AppSettings>(
        stream: _repository.watch(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError && _settings == null) {
            return const Center(
              child: Text(
                'Privacy settings could not be loaded. Check your connection and try again.',
              ),
            );
          }
          final settings = _settings ?? snapshot.data;
          if (settings == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return AppPageContent(
            maxWidth: 760,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: widget.notificationsOnly
                  ? _notificationTiles(settings)
                  : _privacyTiles(settings),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _notificationTiles(AppSettings settings) => [
    const Text(
      'Choose which non-critical updates ResQ may send. Emergency system alerts can still be shown by your device.',
    ),
    const SizedBox(height: AppSpacing.md),
    SwitchListTile(
      title: const Text('Verified safety alerts'),
      subtitle: const Text('Hazards, closures, and official local warnings'),
      value: settings.alertNotifications,
      onChanged: (value) => _save(settings.copyWith(alertNotifications: value)),
    ),
    SwitchListTile(
      title: const Text('Family Circle'),
      subtitle: const Text('Invitations, SOS events, and emergency check-ins'),
      value: settings.circleNotifications,
      onChanged: (value) =>
          _save(settings.copyWith(circleNotifications: value)),
    ),
    SwitchListTile(
      title: const Text('Report status'),
      subtitle: const Text(
        'Moderation and verification updates for your reports',
      ),
      value: settings.reportNotifications,
      onChanged: (value) =>
          _save(settings.copyWith(reportNotifications: value)),
    ),
  ];

  List<Widget> _privacyTiles(AppSettings settings) => [
    const Text('Choose what ResQ may use when answering you.'),
    const SizedBox(height: AppSpacing.sm),
    Text(AppLocalizations.of(context).photoPrivacyNotice),
    const SizedBox(height: AppSpacing.md),
    ExpansionTile(
      leading: const Icon(Icons.auto_awesome_outlined),
      title: const Text('AI data access'),
      subtitle: const Text('Sensitive categories start off'),
      children: [
        _consent(
          'Readiness plan',
          settings.readinessConsent,
          (value) => settings.copyWith(readinessConsent: value),
        ),
        _consent(
          'Approximate location',
          settings.coarseLocationConsent,
          (value) => settings.copyWith(coarseLocationConsent: value),
        ),
        _consent(
          'Precise location',
          settings.preciseLocationConsent,
          (value) => settings.copyWith(preciseLocationConsent: value),
        ),
        _consent(
          'Medical information',
          settings.medicalConsent,
          (value) => settings.copyWith(medicalConsent: value),
        ),
        _consent(
          'Family Circle status',
          settings.familyConsent,
          (value) => settings.copyWith(familyConsent: value),
        ),
      ],
    ),
    const Divider(height: AppSpacing.xl),
    SwitchListTile(
      title: const Text('Daily emergency check-in'),
      subtitle: Text(
        settings.dailyCheckInEnabled
            ? 'At ${settings.dailyCheckInTime} during an active emergency'
            : 'Use during a verified emergency',
      ),
      value: settings.dailyCheckInEnabled,
      onChanged: (value) {
        if (value && settings.emergencyCheckInEventId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Activate daily check-ins from Family when a verified emergency is active.',
              ),
            ),
          );
          return;
        }
        _save(settings.copyWith(dailyCheckInEnabled: value));
      },
    ),
    if (settings.dailyCheckInEnabled)
      ListTile(
        leading: const Icon(Icons.schedule_rounded),
        title: const Text('Check-in time'),
        trailing: Text(settings.dailyCheckInTime),
        onTap: () async {
          final parts = settings.dailyCheckInTime.split(':');
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: int.tryParse(parts.first) ?? 9,
              minute: int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
            ),
          );
          if (picked != null) {
            await _save(
              settings.copyWith(
                dailyCheckInTime:
                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
              ),
            );
          }
        },
      ),
  ];

  Widget _consent(
    String title,
    bool value,
    AppSettings Function(bool value) update,
  ) => SwitchListTile(
    title: Text(title),
    value: value,
    onChanged: (enabled) => _save(update(enabled)),
  );
}
