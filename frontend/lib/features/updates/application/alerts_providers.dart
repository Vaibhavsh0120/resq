import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alerts_repository.dart';
import '../domain/public_alert.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>(
  (ref) => FirestoreAlertsRepository(FirebaseFirestore.instance),
);

final activeAlertsProvider = StreamProvider<List<PublicAlert>>(
  (ref) => ref.watch(alertsRepositoryProvider).watchActive(),
);
