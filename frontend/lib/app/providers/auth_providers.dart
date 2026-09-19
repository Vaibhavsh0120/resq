import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserIdProvider = Provider<String?>(
  (ref) => FirebaseAuth.instance.currentUser?.uid,
);
