import 'package:flutter_test/flutter_test.dart';
import 'package:resq/models/user_profile.dart';

void main() {
  test('personal info completion requires every responder field', () {
    expect(const PersonalInfo(fullName: 'A').isComplete, isFalse);
    expect(
      PersonalInfo(
        fullName: 'Alex Morgan',
        phoneNumber: '+12025550123',
        dateOfBirth: DateTime(1990, 5, 4),
        bloodType: BloodType.oPositive,
      ).isComplete,
      isTrue,
    );
  });

  test('profile round-trips onboarding data', () {
    final map = {
      'email': 'alex@example.com',
      'authProvider': 'password',
      'personalInfo': {
        'fullName': 'Alex Morgan',
        'phoneNumber': '+12025550123',
        'dateOfBirth': '1990-05-04T00:00:00.000',
        'bloodType': 'O+',
      },
      'medicalInfo': {
        'allergies': 'Peanuts',
        'usesMobilityAid': false,
        'hasVisualImpairment': true,
        'hasHearingImpairment': false,
        'stepCompleted': true,
      },
      'familyCircle': {
        'members': [
          {
            'id': 'one',
            'name': 'Sam',
            'relationship': 'Sibling',
            'phoneNumber': '123',
            'isEmergencyContact': true,
          },
        ],
        'stepCompleted': true,
      },
      'homeLocation': {
        'latitude': 12.34,
        'longitude': 56.78,
        'addressLine': '1 Main Street',
        'city': 'Pune',
        'state': 'Maharashtra',
      },
      'onboardingCompleted': true,
      'resumeStep': 4,
    };

    final profile = UserProfile.fromMap('uid-1', map);
    expect(profile.uid, 'uid-1');
    expect(profile.personalInfo.bloodType, BloodType.oPositive);
    expect(profile.medicalInfo.hasVisualImpairment, isTrue);
    expect(profile.familyCircle.members.single.isEmergencyContact, isTrue);
    expect(profile.homeLocation.isComplete, isTrue);
    expect(profile.onboardingCompleted, isTrue);
  });

  test('missing Firestore document creates safe onboarding defaults', () {
    final profile = UserProfile.fromMap('uid-2', null);
    expect(profile.resumeStep, 1);
    expect(profile.onboardingCompleted, isFalse);
    expect(profile.familyCircle.members, isEmpty);
  });

  test('phone validation requires a real country-aware number', () {
    expect(isValidInternationalPhoneNumber('+919876543210'), isTrue);
    expect(isValidInternationalPhoneNumber('+12025550123'), isTrue);
    expect(isValidInternationalPhoneNumber('+91 123'), isFalse);
    expect(isValidInternationalPhoneNumber('9876543210'), isFalse);
    expect(isValidInternationalPhoneNumber(null), isFalse);
  });
}
