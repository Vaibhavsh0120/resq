import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/readiness_item.dart';

abstract interface class ReadinessRepository {
  Stream<List<ReadinessItem>> watch(String uid);
  Future<void> setCompleted(String uid, ReadinessItem item, bool completed);
}

class FirestoreReadinessRepository implements ReadinessRepository {
  FirestoreReadinessRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const defaults = <String, String>{
    'personal_medical': 'Personal and medical information',
    'emergency_contacts': 'Emergency contacts',
    'meeting_point': 'Household meeting point',
    'go_bag': 'Emergency go-bag',
    'documents': 'Important document copies',
    'local_numbers': 'Local emergency numbers',
    'offline_guidance': 'Offline safety guidance',
  };

  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _firestore.collection('users').doc(uid).collection('readiness');

  @override
  Stream<List<ReadinessItem>> watch(String uid) {
    return _items(uid).snapshots().map((snapshot) {
      final stored = {
        for (final document in snapshot.docs)
          document.id: ReadinessItem.fromMap(document.id, document.data()),
      };
      return defaults.entries
          .map(
            (entry) =>
                stored[entry.key] ??
                ReadinessItem(
                  id: entry.key,
                  label: entry.value,
                  completed: false,
                ),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<void> setCompleted(String uid, ReadinessItem item, bool completed) {
    return _items(uid).doc(item.id).set({
      'label': item.label,
      'completed': completed,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
