import 'dart:math' as math;

class SafePlace {
  const SafePlace({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.verified,
    required this.facilities,
    this.phone,
    this.verifiedAt,
  });

  final String id;
  final String name;
  final String type;
  final double latitude;
  final double longitude;
  final bool verified;
  final List<String> facilities;
  final String? phone;
  final DateTime? verifiedAt;

  factory SafePlace.fromMap(String id, Map<String, dynamic> map) {
    return SafePlace(
      id: id,
      name: map['name'] as String? ?? 'Safe place',
      type: map['type'] as String? ?? 'other',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      verified: map['verified'] as bool? ?? false,
      facilities: (map['facilities'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      phone: map['phone'] as String?,
      verifiedAt: _dateTime(map['verifiedAt']),
    );
  }

  double distanceKmFrom(double latitude, double longitude) {
    const earthRadiusKm = 6371.0;
    final lat1 = _radians(latitude);
    final lat2 = _radians(this.latitude);
    final deltaLat = _radians(this.latitude - latitude);
    final deltaLng = _radians(this.longitude - longitude);
    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}

double _radians(double degrees) => degrees * math.pi / 180;

DateTime? _dateTime(Object? value) {
  if (value is DateTime) return value;
  final dynamic timestamp = value;
  try {
    return timestamp?.toDate() as DateTime?;
  } catch (_) {
    return null;
  }
}
