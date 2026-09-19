import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';

class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({
    super.key,
    required this.name,
    required this.detail,
    required this.distance,
  });

  final String name;
  final String detail;
  final String distance;

  void _notify(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safe place')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Center(child: Icon(Icons.place_rounded, size: 52)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('$distance • $detail'),
          const SizedBox(height: AppSpacing.sm),
          const Row(
            children: [
              Icon(Icons.verified_rounded, size: 18),
              SizedBox(width: 6),
              Expanded(child: Text('Verified • information refreshed today')),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () =>
                _notify(context, 'Opening installed maps for directions.'),
            icon: const Icon(Icons.directions_rounded),
            label: const Text('Directions'),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _notify(context, 'Opening phone app.'),
            icon: const Icon(Icons.call_rounded),
            label: const Text('Call place'),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.medical_services_rounded),
              title: Text('Available facilities'),
              subtitle: Text(
                'First aid • Drinking water • Accessible entrance',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
