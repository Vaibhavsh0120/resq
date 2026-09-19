import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/places/domain/safe_place.dart';
import 'package:resq/features/readiness/domain/readiness_item.dart';
import 'package:resq/features/updates/domain/public_alert.dart';

void main() {
  test('connected feature models normalize Firestore data', () {
    final readiness = ReadinessItem.fromMap('go_bag', {
      'label': 'Emergency go-bag',
      'completed': true,
    });
    final alert = PublicAlert.fromMap('rain', {
      'title': {'en': 'Heavy rain', 'hi': 'भारी बारिश'},
      'summary': {'en': 'Avoid low roads'},
      'severity': 'severe',
      'source': 'IMD',
      'issuedAt': DateTime.utc(2026, 9, 19),
      'expiresAt': DateTime.utc(2026, 9, 20),
      'verified': true,
    });
    final place = SafePlace.fromMap('hospital', {
      'name': 'District Hospital',
      'type': 'hospital',
      'latitude': 28.6200,
      'longitude': 77.2100,
      'verified': true,
      'facilities': ['first_aid'],
    });

    expect(readiness.completed, isTrue);
    expect(alert.titleFor('hi'), 'भारी बारिश');
    expect(alert.isActiveAt(DateTime.utc(2026, 9, 19, 12)), isTrue);
    expect(place.distanceKmFrom(28.6139, 77.2090), closeTo(0.68, 0.05));
  });
}
