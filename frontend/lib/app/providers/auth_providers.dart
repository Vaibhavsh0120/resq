import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserIdProvider = Provider<String?>(
  (ref) =>
      Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid,
);

final currentRegisteredUserIdProvider = Provider<String?>((ref) {
  if (Firebase.apps.isEmpty) return null;
  final user = FirebaseAuth.instance.currentUser;
  return user == null || user.isAnonymous ? null : user.uid;
});
