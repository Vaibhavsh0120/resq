import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/sos_event.dart';

abstract interface class SosRepository {
  Future<String> activate({
    required String ownerId,
    double? latitude,
    double? longitude,
  });
}

class FirestoreSosRepository implements SosRepository {
  FirestoreSosRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<String> activate({
    required String ownerId,
    double? latitude,
    double? longitude,
  }) async {
    String? circleId;
    var recipients = <String>[];
    try {
      final settings = await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('settings')
          .doc('app')
          .get();
      circleId = settings.data()?['circleId'] as String?;
      if (circleId != null) {
        final members = await _firestore
            .collection('householdCircles')
            .doc(circleId)
            .collection('members')
            .where('accepted', isEqualTo: true)
            .get();
        recipients = members.docs
            .map((document) => document.id)
            .where((uid) => uid != ownerId)
            .toList(growable: false);
      }
    } on FirebaseException catch (error) {
      if (error.code != 'permission-denied') rethrow;
    }

    final document = _firestore.collection('sosEvents').doc();
    final payload = SosEventPayload(
      ownerId: ownerId,
      authorizedUids: recipients,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now().toUtc(),
    ).toMap();
    await document.set({
      ...payload,
      'createdAt': FieldValue.serverTimestamp(),
      'circleId': ?circleId,
      'deliveryStatus': recipients.isEmpty ? 'no_recipients' : 'pending',
    });
    return document.id;
  }
}
