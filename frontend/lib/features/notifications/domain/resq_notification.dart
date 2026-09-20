enum NotificationSeverity { info, warning, critical }

class ResQNotification {
  const ResQNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.category,
    required this.isRead,
    this.deepLink,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final NotificationSeverity severity;
  final String category;
  final bool isRead;
  final String? deepLink;
  final DateTime? createdAt;

  factory ResQNotification.fromMap(String id, Map<String, dynamic> map) {
    return ResQNotification(
      id: id,
      title: map['title'] as String? ?? 'ResQ update',
      body: map['body'] as String? ?? '',
      severity: NotificationSeverity.values.firstWhere(
        (value) => value.name == map['severity'],
        orElse: () => NotificationSeverity.info,
      ),
      category: map['category'] as String? ?? 'general',
      isRead: map['read'] as bool? ?? false,
      deepLink: map['deepLink'] as String?,
      createdAt: _dateTime(map['createdAt']),
    );
  }
}

DateTime? _dateTime(Object? value) {
  if (value is DateTime) return value;
  final dynamic timestamp = value;
  try {
    return timestamp?.toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}
