import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/resq_notification.dart';

abstract interface class NotificationsRepository {
  Stream<List<ResQNotification>> watchNotifications(String uid);
  Future<void> markRead(String uid, String notificationId);
  Future<void> markAllRead(String uid);
}

class FirestoreNotificationsRepository implements NotificationsRepository {
  FirestoreNotificationsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  @override
  Stream<List<ResQNotification>> watchNotifications(String uid) =>
      _collection(uid)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (document) =>
                      ResQNotification.fromMap(document.id, document.data()),
                )
                .toList(growable: false),
          );

  @override
  Future<void> markRead(String uid, String notificationId) =>
      _collection(uid)
          .doc(notificationId)
          .update({'read': true, 'readAt': FieldValue.serverTimestamp()});

  @override
  Future<void> markAllRead(String uid) async {
    final unread = await _collection(uid).where('read', isEqualTo: false).get();
    final batch = _firestore.batch();
    for (final document in unread.docs) {
      batch.update(document.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
