import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';

class FamilyMemberScreen extends StatelessWidget {
  const FamilyMemberScreen({
    super.key,
    required this.name,
    required this.status,
  });

  final String name;
  final String status;

  void _showAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action for $name will open on this device.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          CircleAvatar(
            radius: 42,
            child: Text(
              name.characters.first,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(status, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Action(
                icon: Icons.call_rounded,
                label: 'Call',
                onTap: () => _showAction(context, 'Calling'),
              ),
              _Action(
                icon: Icons.message_rounded,
                label: 'Message',
                onTap: () => _showAction(context, 'Messaging'),
              ),
              _Action(
                icon: Icons.location_on_rounded,
                label: 'Locate',
                onTap: () => _showAction(context, 'Directions'),
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
                const Text(
                  'Captured 18 minutes ago • sharing expires automatically',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppSectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.check_circle_rounded),
              title: Text('Safe check-in'),
              subtitle: Text('Checked in near home • today, 09:08'),
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
  final VoidCallback onTap;

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
