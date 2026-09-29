import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/family_models.dart';

abstract interface class FamilyRepository {
  Future<void> migrateOnboardingContacts(String uid);
  Stream<String?> watchCircleId(String uid);
  Stream<List<EmergencyContact>> watchEmergencyContacts(String uid);
  Stream<List<CircleMember>> watchMembers(String circleId);
  Stream<LocationShare?> watchActiveLocation({
    required String circleId,
    required String memberId,
  });
  Future<void> checkIn(SafetyCheckIn checkIn);
  Future<void> shareLocation({
    required String circleId,
    required String ownerId,
    required double latitude,
    required double longitude,
    Duration duration,
  });
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
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Sign in to check in.');
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/v1/circles/${checkIn.circleId}/check-ins'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'safe': checkIn.safe,
        'event_id': checkIn.eventId,
        'note': checkIn.note,
        'latitude': checkIn.latitude,
        'longitude': checkIn.longitude,
      }),
    );
    if (response.statusCode != 200) {
      throw StateError('Check-in could not be recorded.');
    }
  }

  @override
  Future<void> shareLocation({
    required String circleId,
    required String ownerId,
    required double latitude,
    required double longitude,
    Duration duration = const Duration(hours: 1),
  }) => _firestore.collection('locationShares').add({
    'circleId': circleId,
    'ownerId': ownerId,
    'location': {'latitude': latitude, 'longitude': longitude},
    'capturedAt': FieldValue.serverTimestamp(),
    'expiresAt': Timestamp.fromDate(DateTime.now().add(duration)),
  });

  @override
  Stream<LocationShare?> watchActiveLocation({
    required String circleId,
    required String memberId,
  }) => _firestore
      .collection('locationShares')
      .where('circleId', isEqualTo: circleId)
      .where('ownerId', isEqualTo: memberId)
      .where('expiresAt', isGreaterThan: Timestamp.now())
      .orderBy('expiresAt', descending: true)
      .limit(1)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.isEmpty
            ? null
            : LocationShare.fromMap(snapshot.docs.first.data()),
      );
}
