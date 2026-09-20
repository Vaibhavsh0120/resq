import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/notifications/data/push_notification_service.dart';

void main() {
  test('device registration payload identifies token and platform', () {
    expect(
      buildDeviceRegistrationPayload(token: 'fcm-token', platform: 'android'),
      {'token': 'fcm-token', 'platform': 'android'},
    );
  });
}
