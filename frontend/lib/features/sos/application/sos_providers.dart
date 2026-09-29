import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sos_repository.dart';
import '../data/sos_api.dart';

final sosRepositoryProvider = Provider<SosRepository>(
  (ref) => ApiSosRepository(ref.watch(sosApiProvider)),
);

final sosApiProvider = Provider<SosApi>((ref) => SosApi());
