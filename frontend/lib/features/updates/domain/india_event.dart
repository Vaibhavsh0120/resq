class IndiaEvent {
  const IndiaEvent({
    required this.id,
    required this.title,
    required this.eventType,
    required this.latitude,
    required this.longitude,
    required this.sourceUrl,
    required this.countryLabel,
    required this.alertLevel,
    required this.updatedAt,
    required this.relevanceEndsAt,
  });

  final String id;
  final String title;
  final String eventType;
  final double latitude;
  final double longitude;
  final Uri sourceUrl;
  final String countryLabel;
  final String alertLevel;
  final DateTime updatedAt;
  final DateTime relevanceEndsAt;

  static IndiaEvent? fromMap(Map<String, dynamic> map) {
    String text(String key, [String fallback = '']) =>
        map[key] is String ? map[key] as String : fallback;
    final latitude = map['latitude'] is num
        ? (map['latitude'] as num).toDouble()
        : null;
    final longitude = map['longitude'] is num
        ? (map['longitude'] as num).toDouble()
        : null;
    final updated = DateTime.tryParse(text('updatedAt'));
    final relevanceEnd = DateTime.tryParse(text('relevanceEndsAt'));
    final url = Uri.tryParse(text('sourceUrl'));
    final id = text('id');
    final title = text('title');
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        updated == null ||
        relevanceEnd == null ||
        !relevanceEnd.isAfter(DateTime.now()) ||
        url == null ||
        url.scheme != 'https' ||
        !{'gdacs.org', 'www.gdacs.org'}.contains(url.host) ||
        id.isEmpty ||
        title.trim().isEmpty) {
      return null;
    }
    return IndiaEvent(
      id: id,
      title: title.trim(),
      eventType: text('eventType', 'Event'),
      latitude: latitude,
      longitude: longitude,
      sourceUrl: url,
      countryLabel: text('countryLabel', 'India-impacting'),
      alertLevel: text('alertLevel', 'Unknown'),
      updatedAt: updated,
      relevanceEndsAt: relevanceEnd,
    );
  }
}
