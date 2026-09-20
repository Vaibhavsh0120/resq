import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../domain/family_models.dart';

class FamilyMemberScreen extends StatelessWidget {
  const FamilyMemberScreen({super.key, required this.member});

  final CircleMember member;

  Future<void> _openDeviceAction(BuildContext context, String scheme) async {
    final opened = await launchUrl(
      Uri(scheme: scheme, path: member.phoneNumber),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No app is available to $scheme this contact.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(member.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(
              member.displayName.characters.first,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            member.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            member.lastCheckInSafe == true
                ? 'Checked in safe'
                : 'No recent safe check-in',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Action(
                icon: Icons.call_rounded,
                label: 'Call',
                onTap: member.phoneNumber.isEmpty
                    ? null
                    : () => _openDeviceAction(context, 'tel'),
              ),
              _Action(
                icon: Icons.message_rounded,
                label: 'Message',
                onTap: member.phoneNumber.isEmpty
                    ? null
                    : () => _openDeviceAction(context, 'sms'),
              ),
              _Action(
                icon: Icons.location_on_rounded,
                label: 'Locate',
                onTap: member.sharesLocation
                    ? () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No active location share is available.',
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last shared location',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.base),
                  ),
                  child: const Center(
                    child: Icon(Icons.location_on_rounded, size: 42),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  member.sharesLocation
                      ? 'Waiting for an active, unexpired location share.'
                      : 'Location sharing is off for this member.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                member.lastCheckInSafe == true
                    ? Icons.check_circle_rounded
                    : Icons.history_rounded,
              ),
              title: Text(
                member.lastCheckInSafe == true
                    ? 'Safe check-in'
                    : 'No safe check-in recorded',
              ),
              subtitle: Text(
                member.lastCheckInAt == null
                    ? 'Check-in history will appear here.'
                    : 'Last update: ${member.lastCheckInAt}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(
        children: [
          IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
          Text(label),
        ],
      ),
    );
  }
}
