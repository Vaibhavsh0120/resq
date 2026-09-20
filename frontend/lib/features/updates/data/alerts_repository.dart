import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/public_alert.dart';

abstract interface class AlertsRepository {
  Stream<List<PublicAlert>> watchActive();
}

class FirestoreAlertsRepository implements AlertsRepository {
  FirestoreAlertsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<PublicAlert>> watchActive() {
    return _firestore
        .collection('publicAlerts')
        .where('verified', isEqualTo: true)
        .orderBy('issuedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final alerts = snapshot.docs
              .map((doc) => PublicAlert.fromMap(doc.id, doc.data()))
              .where((alert) => alert.isActiveAt(DateTime.now()))
              .toList();
          alerts.sort((a, b) {
            final severity = _severityRank(b.severity)
                .compareTo(_severityRank(a.severity));
            return severity != 0 ? severity : b.issuedAt.compareTo(a.issuedAt);
          });
          return List.unmodifiable(alerts);
        });
  }
}

int _severityRank(String severity) => switch (severity.toLowerCase()) {
  'critical' => 4,
  'extreme' => 4,
  'severe' => 3,
  'warning' => 3,
  'moderate' => 2,
  'minor' => 1,
  'info' => 1,
  _ => 0,
};
