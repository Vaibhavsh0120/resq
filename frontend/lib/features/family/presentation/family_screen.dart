import 'package:flutter/material.dart';

import '../../../app/shell/adaptive_app_shell.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import 'family_member_screen.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key, required this.isGuest});

  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const PageStorageKey('family-scroll'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        const ResQPageHeader(
          title: 'Family',
          subtitle: 'Your household safety circle',
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: isGuest ? null : () {},
          icon: const Icon(Icons.health_and_safety_rounded),
          label: Text(isGuest ? 'Sign in to check in' : "I'm safe — check in"),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('My Circle', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              const _MemberRow(
                name: 'Ananya',
                detail: 'Safe • checked in 18 min ago',
              ),
              const Divider(),
              const _MemberRow(
                name: 'Rahul',
                detail: 'Location shared • 1.2 km away',
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person_add_alt_1_rounded),
                ),
                title: const Text('Invite family member'),
                subtitle: const Text('Share a secure, expiring invitation'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: isGuest ? null : () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.name, required this.detail});
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(name.characters.first)),
      title: Text(name),
      subtitle: Text(detail),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FamilyMemberScreen(name: name, status: detail),
        ),
      ),
    );
  }
}
