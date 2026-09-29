import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';
import '../../../l10n/app_localizations.dart';

class SosEventDetailScreen extends StatelessWidget {
  const SosEventDetailScreen({super.key, required this.eventId});
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.sosEventTitle)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('sosEvents')
            .doc(eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(strings.sosEventUnavailable));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data();
          if (data == null) {
            return Center(child: Text(strings.sosEventMissing));
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
                      strings.sosCircleActivated,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _deliveryLabel(
                        data['deliveryStatus'] as String?,
                        strings,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(strings.sosPushUnconfirmed),
                    if (createdAt != null)
                      Text('${strings.sosRecordedAt} ${createdAt.toString()}'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(strings.sosDirectContact),
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
                label: Text(strings.call112),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _deliveryLabel(String? status, AppLocalizations strings) =>
    switch (status) {
      'inbox_delivered' => strings.sosInboxDelivered,
      'dispatching' => strings.sosInboxDispatching,
      'no_recipients' => strings.sosInboxNoRecipients,
      _ => strings.sosInboxWaiting,
    };
