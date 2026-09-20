import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/notifications/domain/resq_notification.dart';

void main() {
  test(
    'notification model preserves severity, unread state, and deep link',
    () {
      final notification = ResQNotification.fromMap('notice-1', {
        'title': 'Emergency SOS from Maya',
        'body': 'Maya activated an SOS event.',
        'severity': 'critical',
        'category': 'sos',
        'read': false,
        'deepLink': '/sos/event-1',
        'createdAt': DateTime.utc(2026, 9, 20, 8, 30),
      });

      expect(notification.isRead, isFalse);
      expect(notification.severity, NotificationSeverity.critical);
      expect(notification.deepLink, '/sos/event-1');
      expect(notification.createdAt, DateTime.utc(2026, 9, 20, 8, 30));
    },
  );
}
