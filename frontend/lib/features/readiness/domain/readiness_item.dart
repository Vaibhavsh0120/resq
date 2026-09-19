class ReadinessItem {
  const ReadinessItem({
    required this.id,
    required this.label,
    required this.completed,
    this.updatedAt,
  });

  final String id;
  final String label;
  final bool completed;
  final DateTime? updatedAt;

  factory ReadinessItem.fromMap(String id, Map<String, dynamic> map) {
    return ReadinessItem(
      id: id,
      label: map['label'] as String? ?? id,
      completed: map['completed'] as bool? ?? false,
      updatedAt: _dateTime(map['updatedAt']),
    );
  }

  ReadinessItem copyWith({bool? completed, DateTime? updatedAt}) {
    return ReadinessItem(
      id: id,
      label: label,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
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
