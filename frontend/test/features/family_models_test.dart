import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/family/domain/family_models.dart';

void main() {
  test(
    'family models keep emergency contacts separate from accepted members',
    () {
      final contact = EmergencyContact.fromMap('contact-1', {
        'name': 'Maya',
        'phoneNumber': '+919999999999',
        'relationship': 'Sister',
      });
      final member = CircleMember.fromMap('user-2', {
        'displayName': 'Arun',
        'phoneNumber': '+918888888888',
        'accepted': true,
        'role': 'member',
        'sharingPermissions': {'location': true},
      });
      const checkIn = SafetyCheckIn(
        circleId: 'circle-1',
        userId: 'user-1',
        safe: true,
        eventId: 'event-1',
      );

      expect(contact.name, 'Maya');
      expect(member.accepted, isTrue);
      expect(member.sharesLocation, isTrue);
      expect(checkIn.toMap()['safe'], isTrue);
      expect(checkIn.toMap()['eventId'], 'event-1');
    },
  );

  test('onboarding family entries migrate only as emergency contacts', () {
    final contacts = onboardingEmergencyContacts({
      'members': [
        {
          'id': 'legacy-1',
          'name': 'Maya',
          'relationship': 'Sister',
          'phoneNumber': '+919999999999',
          'isEmergencyContact': true,
        },
      ],
    });

    expect(contacts, hasLength(1));
    expect(contacts.single.id, 'legacy-1');
    expect(contacts.single.name, 'Maya');
    expect(contacts.single.phoneNumber, '+919999999999');
  });
}
