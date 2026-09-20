import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/family_models.dart';

abstract interface class FamilyRepository {
  Future<void> migrateOnboardingContacts(String uid);
  Stream<String?> watchCircleId(String uid);
  Stream<List<EmergencyContact>> watchEmergencyContacts(String uid);
  Stream<List<CircleMember>> watchMembers(String circleId);
  Future<void> checkIn(SafetyCheckIn checkIn);
}

class FirestoreFamilyRepository implements FamilyRepository {
  FirestoreFamilyRepository(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Future<void> migrateOnboardingContacts(String uid) async {
    final user = _firestore.collection('users').doc(uid);
    final migration = user.collection('settings').doc('familyMigration');
    final alreadyMigrated = await migration.get();
    if (alreadyMigrated.data()?['onboardingContactsV1'] == true) return;

    final snapshot = await user.get();
    final contacts = onboardingEmergencyContacts(
      snapshot.data()?['familyCircle'] as Map<String, dynamic>?,
    );
    final batch = _firestore.batch();
    for (final contact in contacts) {
      batch.set(user.collection('emergencyContacts').doc(contact.id), {
        'name': contact.name,
        'phoneNumber': contact.phoneNumber,
        'relationship': contact.relationship,
        'source': 'onboarding',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    batch.set(migration, {
      'onboardingContactsV1': true,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  @override
  Stream<String?> watchCircleId(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('app')
      .snapshots()
      .map((snapshot) => snapshot.data()?['circleId'] as String?);

  @override
  Stream<List<EmergencyContact>> watchEmergencyContacts(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('emergencyContacts')
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (document) =>
                      EmergencyContact.fromMap(document.id, document.data()),
                )
                .toList(growable: false),
          );

  @override
  Stream<List<CircleMember>> watchMembers(String circleId) => _firestore
      .collection('householdCircles')
      .doc(circleId)
      .collection('members')
      .where('accepted', isEqualTo: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(
              (document) => CircleMember.fromMap(document.id, document.data()),
            )
            .toList(growable: false),
      );

  @override
  Future<void> checkIn(SafetyCheckIn checkIn) async {
    final batch = _firestore.batch();
    final record = _firestore
        .collection('householdCircles')
        .doc(checkIn.circleId)
        .collection('checkIns')
        .doc();
    batch.set(record, {
      ...checkIn.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
