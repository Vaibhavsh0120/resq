import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';
import '../domain/resq_notification.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => FirestoreNotificationsRepository(FirebaseFirestore.instance),
);

final notificationsProvider =
    StreamProvider.family<List<ResQNotification>, String>(
      (ref, uid) =>
          ref.watch(notificationsRepositoryProvider).watchNotifications(uid),
    );

final unreadNotificationsProvider = Provider.family<int, String>((ref, uid) {
  return ref
          .watch(notificationsProvider(uid))
          .value
          ?.where((notification) => !notification.isRead)
          .length ??
      0;
});
