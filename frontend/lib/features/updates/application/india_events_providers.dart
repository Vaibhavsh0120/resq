import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/india_events_repository.dart';

final indiaEventsRepositoryProvider = Provider<IndiaEventsRepository>(
  (ref) => ApiIndiaEventsRepository(),
);

final indiaEventsProvider = StreamProvider<IndiaEventFeed>(
  (ref) => ref.watch(indiaEventsRepositoryProvider).watchRecent(),
);
