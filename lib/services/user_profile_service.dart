import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';

/// The single place that talks to Firestore for `users/{uid}`.
///
/// Every onboarding step writes only its own field (via `SetOptions(merge:
/// true)`), so a step's data survives even if the user backs out of the app
/// mid-flow — resuming onboarding just means reading the doc back and
/// jumping to `resumeStep`.
class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('users').doc(uid);

  Future<UserProfile> fetchProfile(String uid) async {
    final snapshot = await _doc(uid).get();
    return UserProfile.fromMap(uid, snapshot.data());
  }

  Stream<UserProfile> watchProfile(String uid) {
    return _doc(uid).snapshots().map((s) => UserProfile.fromMap(uid, s.data()));
  }

  /// Called once right after signup / first-ever Google sign-in to seed the
  /// document. Safe to call again (merge: true) — won't clobber onboarding
  /// progress if somehow called twice.
  Future<void> createInitialProfile({
    required String uid,
    required String? email,
    required String authProvider,
    String? fullName,
  }) async {
    await _doc(uid).set({
      'email': email,
      'authProvider': authProvider,
      'createdAt': FieldValue.serverTimestamp(),
      if (fullName != null && fullName.trim().isNotEmpty)
        'personalInfo': {'fullName': fullName},
      'onboardingCompleted': false,
      'resumeStep': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> savePersonalInfo(String uid, PersonalInfo info) async {
    await _doc(uid).set({
      'personalInfo': info.toMap(),
      'resumeStep': 2,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveMedicalInfo(String uid, MedicalInfo info) async {
    await _doc(uid).set({
      'medicalInfo': info.toMap(),
      'resumeStep': 3,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveFamilyCircle(String uid, FamilyCircle circle) async {
    await _doc(uid).set({
      'familyCircle': circle.toMap(),
      'resumeStep': 4,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveHomeLocation(String uid, HomeLocation location) async {
    await _doc(uid).set({
      'homeLocation': location.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> completeOnboarding(String uid) async {
    await _doc(uid).set({
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
