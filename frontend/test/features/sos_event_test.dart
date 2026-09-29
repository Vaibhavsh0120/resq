import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/sos/domain/sos_event.dart';

void main() {
  test('SOS request contains location but no client-controlled recipients', () {
    final payload = SosCreatePayload(
      latitude: 28.6139,
      longitude: 77.2090,
    ).toMap();

    expect(payload, {'latitude': 28.6139, 'longitude': 77.2090});
  });
}
