/// Data models mirroring the `users/{uid}` Firestore document.
///
/// Kept deliberately flat-ish and forward-compatible: every onboarding step
/// writes into its own map field, so future steps/fields can be added
/// without migrating existing documents, and partially-completed onboarding
/// is just "some of these fields are null."
library;

enum BloodType {
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  abPositive('AB+'),
  abNegative('AB-'),
  oPositive('O+'),
  oNegative('O-'),
  unknown('Unknown');

  const BloodType(this.label);
  final String label;

  static BloodType? fromLabel(String? label) {
    if (label == null) return null;
    for (final type in BloodType.values) {
      if (type.label == label) return type;
    }
    return null;
  }
}

/// Onboarding Step 1.
class PersonalInfo {
  const PersonalInfo({
    this.fullName,
    this.phoneNumber,
    this.dateOfBirth,
    this.bloodType,
  });

  final String? fullName;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final BloodType? bloodType;

  bool get isComplete =>
      fullName != null &&
      fullName!.trim().isNotEmpty &&
      phoneNumber != null &&
      phoneNumber!.trim().isNotEmpty &&
      dateOfBirth != null &&
      bloodType != null;

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'dateOfBirth': dateOfBirth?.toIso8601String(),
    'bloodType': bloodType?.label,
  };

  factory PersonalInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PersonalInfo();
    return PersonalInfo(
      fullName: map['fullName'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'] as String)
          : null,
      bloodType: BloodType.fromLabel(map['bloodType'] as String?),
    );
  }

  PersonalInfo copyWith({
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    BloodType? bloodType,
  }) => PersonalInfo(
    fullName: fullName ?? this.fullName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    bloodType: bloodType ?? this.bloodType,
  );
}

/// Onboarding Step 2. Accessibility needs are optional by design — an empty
/// selection is a valid, complete answer ("none of these apply").
class MedicalInfo {
  const MedicalInfo({
    this.allergies,
    this.medicalConditions,
    this.usesMobilityAid = false,
    this.hasVisualImpairment = false,
    this.hasHearingImpairment = false,
    this.stepCompleted = false,
  });

  final String? allergies;
  final String? medicalConditions;
  final bool usesMobilityAid;
  final bool hasVisualImpairment;
  final bool hasHearingImpairment;

  /// Explicit flag rather than inferring from field presence — this step's
  /// fields are all individually optional, so "the user finished this step"
  /// can't be derived from any single field being non-null.
  final bool stepCompleted;

  Map<String, dynamic> toMap() => {
    'allergies': allergies,
    'medicalConditions': medicalConditions,
    'usesMobilityAid': usesMobilityAid,
    'hasVisualImpairment': hasVisualImpairment,
    'hasHearingImpairment': hasHearingImpairment,
    'stepCompleted': stepCompleted,
  };

  factory MedicalInfo.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const MedicalInfo();
    return MedicalInfo(
      allergies: map['allergies'] as String?,
      medicalConditions: map['medicalConditions'] as String?,
      usesMobilityAid: map['usesMobilityAid'] as bool? ?? false,
      hasVisualImpairment: map['hasVisualImpairment'] as bool? ?? false,
      hasHearingImpairment: map['hasHearingImpairment'] as bool? ?? false,
      stepCompleted: map['stepCompleted'] as bool? ?? false,
    );
  }
}

/// A single Family Circle member, as recorded by the *inviting* user this
/// session — no invite is actually sent yet (see `docs/architecture.md`
/// for the planned `familyInvites` collection that will link
/// this to the invitee's own account once that feature is built).
class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.relationship,
    this.phoneNumber,
    this.isEmergencyContact = false,
  });

  /// Locally-generated id (timestamp-based) — stable enough to key a list
  /// and to diff against when editing, without needing a server round-trip.
  final String id;
  final String name;
  final String relationship;
  final String? phoneNumber;
  final bool isEmergencyContact;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'relationship': relationship,
    'phoneNumber': phoneNumber,
    'isEmergencyContact': isEmergencyContact,
  };

  factory FamilyMember.fromMap(Map<String, dynamic> map) => FamilyMember(
    id: map['id'] as String,
    name: map['name'] as String,
    relationship: map['relationship'] as String,
    phoneNumber: map['phoneNumber'] as String?,
    isEmergencyContact: map['isEmergencyContact'] as bool? ?? false,
  );

  FamilyMember copyWith({
    String? name,
    String? relationship,
    String? phoneNumber,
    bool? isEmergencyContact,
  }) => FamilyMember(
    id: id,
    name: name ?? this.name,
    relationship: relationship ?? this.relationship,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
  );
}

/// Onboarding Step 3. An empty family circle is a valid, complete answer —
/// not everyone has someone to add during onboarding; they can add family
/// members later from a future "Family Circle" settings screen.
class FamilyCircle {
  const FamilyCircle({this.members = const [], this.stepCompleted = false});

  final List<FamilyMember> members;
  final bool stepCompleted;

  Map<String, dynamic> toMap() => {
    'members': members.map((m) => m.toMap()).toList(),
    'stepCompleted': stepCompleted,
  };

  factory FamilyCircle.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const FamilyCircle();
    final rawMembers = map['members'] as List<dynamic>? ?? [];
    return FamilyCircle(
      members: rawMembers
          .map((m) => FamilyMember.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      stepCompleted: map['stepCompleted'] as bool? ?? false,
    );
  }
}

/// Onboarding Step 4.
class HomeLocation {
  const HomeLocation({
    this.latitude,
    this.longitude,
    this.addressLine,
    this.city,
    this.state,
    this.landmark,
  });

  final double? latitude;
  final double? longitude;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? landmark;

  bool get hasCoordinates => latitude != null && longitude != null;

  bool get isComplete =>
      hasCoordinates &&
      addressLine != null &&
      addressLine!.trim().isNotEmpty &&
      city != null &&
      city!.trim().isNotEmpty &&
      state != null &&
      state!.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'addressLine': addressLine,
    'city': city,
    'state': state,
    'landmark': landmark,
  };

  factory HomeLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HomeLocation();
    return HomeLocation(
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      addressLine: map['addressLine'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      landmark: map['landmark'] as String?,
    );
  }

  HomeLocation copyWith({
    double? latitude,
    double? longitude,
    String? addressLine,
    String? city,
    String? state,
    String? landmark,
  }) => HomeLocation(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    addressLine: addressLine ?? this.addressLine,
    city: city ?? this.city,
    state: state ?? this.state,
    landmark: landmark ?? this.landmark,
  );
}

/// The full `users/{uid}` document. `onboardingCompleted` is the single
/// flag `OnboardingGate` checks; `resumeStep` records how far the user got
/// so the flow can pick up where they left off.
class UserProfile {
  const UserProfile({
    required this.uid,
    this.email,
    this.authProvider,
    this.personalInfo = const PersonalInfo(),
    this.medicalInfo = const MedicalInfo(),
    this.familyCircle = const FamilyCircle(),
    this.homeLocation = const HomeLocation(),
    this.onboardingCompleted = false,
    this.resumeStep = 1,
  });

  final String uid;
  final String? email;

  /// 'password' | 'google.com' — kept for future provider-specific UI
  /// (e.g. hiding the change-password option for Google-only accounts).
  final String? authProvider;

  final PersonalInfo personalInfo;
  final MedicalInfo medicalInfo;
  final FamilyCircle familyCircle;
  final HomeLocation homeLocation;
  final bool onboardingCompleted;
  final int resumeStep;

  factory UserProfile.fromMap(String uid, Map<String, dynamic>? map) {
    if (map == null) return UserProfile(uid: uid);
    return UserProfile(
      uid: uid,
      email: map['email'] as String?,
      authProvider: map['authProvider'] as String?,
      personalInfo: PersonalInfo.fromMap(
        map['personalInfo'] as Map<String, dynamic>?,
      ),
      medicalInfo: MedicalInfo.fromMap(
        map['medicalInfo'] as Map<String, dynamic>?,
      ),
      familyCircle: FamilyCircle.fromMap(
        map['familyCircle'] as Map<String, dynamic>?,
      ),
      homeLocation: HomeLocation.fromMap(
        map['homeLocation'] as Map<String, dynamic>?,
      ),
      onboardingCompleted: map['onboardingCompleted'] as bool? ?? false,
      resumeStep: (map['resumeStep'] as num?)?.toInt() ?? 1,
    );
  }
}
