import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/alerts_repository.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>(
  (ref) => ApiAlertsRepository(),
);

final activeAlertsProvider = StreamProvider<AlertFeed>(
  (ref) => ref.watch(alertsRepositoryProvider).watchActive(),
);
