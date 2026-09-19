import 'package:flutter_test/flutter_test.dart';
import 'package:resq/features/reports/domain/incident_report.dart';

void main() {
  test('report draft creates a moderation-safe API payload', () {
    const draft = IncidentReportDraft(
      hazard: HazardType.flood,
      description: 'Water rising near the bridge',
      latitude: 28.6139,
      longitude: 77.2090,
    );

    expect(draft.guidance.dos, isNotEmpty);
    expect(draft.guidance.donts, isNotEmpty);
    expect(draft.toJson(), {
      'hazard': 'flood',
      'description': 'Water rising near the bridge',
      'latitude': 28.6139,
      'longitude': 77.2090,
    });
  });
}
