import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/readiness_repository.dart';
import '../domain/readiness_item.dart';

final readinessRepositoryProvider = Provider<ReadinessRepository>(
  (ref) => FirestoreReadinessRepository(FirebaseFirestore.instance),
);

final readinessItemsProvider =
    StreamProvider.family<List<ReadinessItem>, String>(
      (ref, uid) => ref.watch(readinessRepositoryProvider).watch(uid),
    );
