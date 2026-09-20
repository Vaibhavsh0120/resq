class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;

  factory EmergencyContact.fromMap(String id, Map<String, dynamic> map) {
    return EmergencyContact(
      id: id,
      name: map['name'] as String? ?? 'Emergency contact',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
    );
  }
}

List<EmergencyContact> onboardingEmergencyContacts(
  Map<String, dynamic>? familyCircle,
) {
  final members = familyCircle?['members'] as List<dynamic>? ?? const [];
  return members
      .whereType<Map>()
      .map((raw) => Map<String, dynamic>.from(raw))
      .where((member) => (member['id'] as String?)?.isNotEmpty == true)
      .map(
        (member) => EmergencyContact(
          id: member['id'] as String,
          name: member['name'] as String? ?? 'Emergency contact',
          phoneNumber: member['phoneNumber'] as String? ?? '',
          relationship: member['relationship'] as String? ?? '',
        ),
      )
      .toList(growable: false);
}

class CircleMember {
  const CircleMember({
    required this.uid,
    required this.displayName,
    required this.accepted,
    required this.role,
    required this.phoneNumber,
    required this.sharesLocation,
    this.lastCheckInAt,
    this.lastCheckInSafe,
  });

  final String uid;
  final String displayName;
  final bool accepted;
  final String role;
  final String phoneNumber;
  final bool sharesLocation;
  final DateTime? lastCheckInAt;
  final bool? lastCheckInSafe;

  factory CircleMember.fromMap(String uid, Map<String, dynamic> map) {
    final permissions = Map<String, dynamic>.from(
      map['sharingPermissions'] as Map? ?? const {},
    );
    return CircleMember(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Circle member',
      accepted: map['accepted'] as bool? ?? false,
      role: map['role'] as String? ?? 'member',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      sharesLocation: permissions['location'] as bool? ?? false,
      lastCheckInAt: _dateTime(map['lastCheckInAt']),
      lastCheckInSafe: map['lastCheckInSafe'] as bool?,
    );
  }
}

class SafetyCheckIn {
  const SafetyCheckIn({
    required this.circleId,
    required this.userId,
    required this.safe,
    this.eventId,
    this.note,
    this.latitude,
    this.longitude,
  });

  final String circleId;
  final String userId;
  final bool safe;
  final String? eventId;
  final String? note;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'safe': safe,
    if (eventId != null) 'eventId': eventId,
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    if (latitude != null && longitude != null)
      'location': {'latitude': latitude, 'longitude': longitude},
  };
}

class FamilySnapshot {
  const FamilySnapshot({
    this.circleId,
    this.members = const [],
    this.contacts = const [],
  });

  final String? circleId;
  final List<CircleMember> members;
  final List<EmergencyContact> contacts;
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
