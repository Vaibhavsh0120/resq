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
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PublicAlert.fromMap(doc.id, doc.data()))
              .where((alert) => alert.isActiveAt(DateTime.now()))
              .toList(growable: false),
        );
  }
}
