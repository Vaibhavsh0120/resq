import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';

class SosEventDetailScreen extends StatelessWidget {
  const SosEventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS event')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('sosEvents')
            .doc(eventId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'This SOS event is unavailable or you do not have access.',
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(child: Text('This SOS event was not found.'));
          }
          final created = data['createdAt'];
          final createdAt = created is Timestamp
              ? created.toDate().toLocal()
              : null;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.sos_rounded,
                      size: 52,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'A Family Circle member activated SOS',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Status: ${data['status'] ?? 'active'}'),
                    if (createdAt != null)
                      Text('Recorded: ${createdAt.toString()}'),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Contact the person directly and call emergency services if immediate help is needed. ResQ does not dispatch responders.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => launchUrl(
                  Uri(scheme: 'tel', path: '112'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.call_rounded),
                label: const Text('Call 112'),
              ),
            ],
          );
        },
      ),
    );
  }
}
