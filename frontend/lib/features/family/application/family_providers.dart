import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/family_repository.dart';
import '../data/circle_api.dart';
import '../domain/family_models.dart';

final familyRepositoryProvider = Provider<FamilyRepository>(
  (ref) => FirestoreFamilyRepository(FirebaseFirestore.instance),
);

final circleApiProvider = Provider<CircleApi>((ref) => CircleApi());

final familyContactMigrationProvider = FutureProvider.family<void, String>(
  (ref, uid) =>
      ref.watch(familyRepositoryProvider).migrateOnboardingContacts(uid),
);

final familyCircleIdProvider = StreamProvider.family<String?, String>(
  (ref, uid) => ref.watch(familyRepositoryProvider).watchCircleId(uid),
);

final emergencyContactsProvider =
    StreamProvider.family<List<EmergencyContact>, String>(
      (ref, uid) =>
          ref.watch(familyRepositoryProvider).watchEmergencyContacts(uid),
    );

final circleMembersProvider = StreamProvider.family<List<CircleMember>, String>(
  (ref, circleId) => ref.watch(familyRepositoryProvider).watchMembers(circleId),
);
