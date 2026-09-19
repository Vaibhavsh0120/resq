class PublicAlert {
  const PublicAlert({
    required this.id,
    required this.titles,
    required this.summaries,
    required this.severity,
    required this.source,
    required this.issuedAt,
    required this.expiresAt,
    required this.verified,
    this.area,
  });

  final String id;
  final Map<String, String> titles;
  final Map<String, String> summaries;
  final String severity;
  final String source;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool verified;
  final String? area;

  factory PublicAlert.fromMap(String id, Map<String, dynamic> map) {
    return PublicAlert(
      id: id,
      titles: _strings(map['title']),
      summaries: _strings(map['summary']),
      severity: map['severity'] as String? ?? 'unknown',
      source: map['source'] as String? ?? 'Unknown source',
      issuedAt:
          _dateTime(map['issuedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt:
          _dateTime(map['expiresAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      verified: map['verified'] as bool? ?? false,
      area: map['affectedArea'] as String? ?? map['district'] as String?,
    );
  }

  String titleFor(String languageCode) =>
      titles[languageCode] ?? titles['en'] ?? 'Safety alert';
  String summaryFor(String languageCode) =>
      summaries[languageCode] ?? summaries['en'] ?? '';
  bool isActiveAt(DateTime value) => verified && expiresAt.isAfter(value);
}

Map<String, String> _strings(Object? value) {
  if (value is String) return {'en': value};
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item.toString()));
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
