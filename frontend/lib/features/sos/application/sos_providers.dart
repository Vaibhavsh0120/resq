import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sos_repository.dart';
import '../data/sos_api.dart';

final sosRepositoryProvider = Provider<SosRepository>(
  (ref) => FirestoreSosRepository(FirebaseFirestore.instance),
);

final sosApiProvider = Provider<SosApi>((ref) => SosApi());
