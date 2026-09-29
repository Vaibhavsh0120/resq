import '../domain/sos_event.dart';
import 'sos_api.dart';

abstract interface class SosRepository {
  Future<SosCreatedEvent> activate({double? latitude, double? longitude});
}

class ApiSosRepository implements SosRepository {
  ApiSosRepository(this._api);

  final SosApi _api;

  @override
  Future<SosCreatedEvent> activate({double? latitude, double? longitude}) =>
      _api.create(SosCreatePayload(latitude: latitude, longitude: longitude));
}
