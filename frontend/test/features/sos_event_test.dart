import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/sos/domain/sos_event.dart';

void main() {
  test('SOS payload includes owner, recipients, and optional location', () {
    final payload = SosEventPayload(
      ownerId: 'user-1',
      authorizedUids: const ['user-2'],
      latitude: 28.6139,
      longitude: 77.2090,
      createdAt: DateTime.utc(2026, 1, 1),
    ).toMap();

    expect(payload['ownerId'], 'user-1');
    expect(payload['authorizedUids'], ['user-2']);
    expect(payload['location'], {'latitude': 28.6139, 'longitude': 77.2090});
    expect(payload['status'], 'active');
  });
}
