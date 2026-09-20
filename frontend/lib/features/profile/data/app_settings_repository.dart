import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettings {
  const AppSettings({
    this.alertNotifications = true,
    this.circleNotifications = true,
    this.reportNotifications = true,
    this.readinessConsent = false,
    this.coarseLocationConsent = false,
    this.preciseLocationConsent = false,
    this.medicalConsent = false,
    this.familyConsent = false,
    this.dailyCheckInEnabled = false,
    this.dailyCheckInTime = '09:00',
    this.emergencyCheckInEventId,
  });

  final bool alertNotifications;
  final bool circleNotifications;
  final bool reportNotifications;
  final bool readinessConsent;
  final bool coarseLocationConsent;
  final bool preciseLocationConsent;
  final bool medicalConsent;
  final bool familyConsent;
  final bool dailyCheckInEnabled;
  final String dailyCheckInTime;
  final String? emergencyCheckInEventId;

  factory AppSettings.fromMap(Map<String, dynamic>? map) {
    final notifications = Map<String, dynamic>.from(
      map?['notificationCategories'] as Map? ?? const {},
    );
    final consent = Map<String, dynamic>.from(
      map?['aiConsent'] as Map? ?? const {},
    );
    final checkIn = Map<String, dynamic>.from(
      map?['emergencyCheckIn'] as Map? ?? const {},
    );
    return AppSettings(
      alertNotifications: notifications['alerts'] as bool? ?? true,
      circleNotifications: notifications['circle'] as bool? ?? true,
      reportNotifications: notifications['reports'] as bool? ?? true,
      readinessConsent: consent['readiness'] as bool? ?? false,
      coarseLocationConsent: consent['coarseLocation'] as bool? ?? false,
      preciseLocationConsent: consent['preciseLocation'] as bool? ?? false,
      medicalConsent: consent['medical'] as bool? ?? false,
      familyConsent: consent['family'] as bool? ?? false,
      dailyCheckInEnabled: checkIn['enabled'] as bool? ?? false,
      dailyCheckInTime: checkIn['time'] as String? ?? '09:00',
      emergencyCheckInEventId: checkIn['eventId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'notificationCategories': {
      'alerts': alertNotifications,
      'circle': circleNotifications,
      'reports': reportNotifications,
    },
    'aiConsent': {
      'readiness': readinessConsent,
      'coarseLocation': coarseLocationConsent,
      'preciseLocation': preciseLocationConsent,
      'medical': medicalConsent,
      'family': familyConsent,
    },
    'emergencyCheckIn': {
      'enabled': dailyCheckInEnabled,
      'time': dailyCheckInTime,
      if (emergencyCheckInEventId != null) 'eventId': emergencyCheckInEventId,
      'timezoneOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
    },
    'updatedAt': FieldValue.serverTimestamp(),
  };

  AppSettings copyWith({
    bool? alertNotifications,
    bool? circleNotifications,
    bool? reportNotifications,
    bool? readinessConsent,
    bool? coarseLocationConsent,
    bool? preciseLocationConsent,
    bool? medicalConsent,
    bool? familyConsent,
    bool? dailyCheckInEnabled,
    String? dailyCheckInTime,
    String? emergencyCheckInEventId,
  }) => AppSettings(
    alertNotifications: alertNotifications ?? this.alertNotifications,
    circleNotifications: circleNotifications ?? this.circleNotifications,
    reportNotifications: reportNotifications ?? this.reportNotifications,
    readinessConsent: readinessConsent ?? this.readinessConsent,
    coarseLocationConsent: coarseLocationConsent ?? this.coarseLocationConsent,
    preciseLocationConsent:
        preciseLocationConsent ?? this.preciseLocationConsent,
    medicalConsent: medicalConsent ?? this.medicalConsent,
    familyConsent: familyConsent ?? this.familyConsent,
    dailyCheckInEnabled: dailyCheckInEnabled ?? this.dailyCheckInEnabled,
    dailyCheckInTime: dailyCheckInTime ?? this.dailyCheckInTime,
    emergencyCheckInEventId:
        emergencyCheckInEventId ?? this.emergencyCheckInEventId,
  );
}

class AppSettingsRepository {
  AppSettingsRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _reference(String uid) =>
      _firestore.collection('users').doc(uid).collection('settings').doc('app');

  Stream<AppSettings> watch(String uid) =>
      _reference(uid)
          .snapshots()
          .map((snapshot) => AppSettings.fromMap(snapshot.data()));

  Future<void> save(String uid, AppSettings settings) =>
      _reference(uid).set(settings.toMap(), SetOptions(merge: true));

  Future<void> activateEmergencyCheckIn({
    required String uid,
    required String eventId,
  }) => _reference(uid).set({
    'emergencyCheckIn': {
      'enabled': true,
      'eventId': eventId,
      'time': '09:00',
      'timezoneOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
    },
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
