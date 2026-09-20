class SosEventPayload {
  const SosEventPayload({
    required this.ownerId,
    required this.authorizedUids,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  final String ownerId;
  final List<String> authorizedUids;
  final DateTime createdAt;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toMap() => {
    'ownerId': ownerId,
    'authorizedUids': authorizedUids,
    'status': 'active',
    'createdAt': createdAt,
    if (latitude != null && longitude != null)
      'location': {'latitude': latitude, 'longitude': longitude},
  };
}
