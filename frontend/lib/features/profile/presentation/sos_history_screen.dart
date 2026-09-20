import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_surfaces.dart';

class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('SOS history')),
      body: uid == null
          ? const Center(child: Text('Sign in to view SOS history.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('sosEvents')
                  .where('ownerId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('SOS history could not be loaded.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data!.docs;
                if (records.isEmpty) {
                  return const Center(
                    child: Text('No SOS events have been activated.'),
                  );
                }
                return AppPageContent(
                  maxWidth: 760,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final data = records[index].data();
                      final timestamp = data['createdAt'];
                      final createdAt = timestamp is Timestamp
                          ? timestamp.toDate()
                          : null;
                      return ListTile(
                        leading: const Icon(Icons.sos_rounded),
                        title: Text(
                          (data['status'] as String? ?? 'active').toUpperCase(),
                        ),
                        subtitle: Text(
                          createdAt == null
                              ? 'Time unavailable'
                              : MaterialLocalizations.of(context)
                                    .formatFullDate(createdAt.toLocal()),
                        ),
                        trailing: Text(
                          data['deliveryStatus'] as String? ?? 'recorded',
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
