import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_repository.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ApiReportsRepository(),
);
