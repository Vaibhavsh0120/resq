enum HazardType {
  flood('Flood'),
  fire('Fire'),
  earthquake('Earthquake'),
  landslide('Landslide'),
  roadBlock('Road block'),
  severeWeather('Severe weather'),
  infrastructureDamage('Infrastructure damage'),
  other('Other');

  const HazardType(this.label);
  final String label;

  String get apiValue => switch (this) {
    HazardType.roadBlock => 'road_block',
    HazardType.severeWeather => 'severe_weather',
    HazardType.infrastructureDamage => 'infrastructure_damage',
    _ => name,
  };
}

class HazardGuidance {
  const HazardGuidance({required this.dos, required this.donts});

  final List<String> dos;
  final List<String> donts;
}

class IncidentReportDraft {
  const IncidentReportDraft({
    required this.hazard,
    required this.description,
    this.latitude,
    this.longitude,
    this.photoPath,
  });

  final HazardType hazard;
  final String description;
  final double? latitude;
  final double? longitude;
  final String? photoPath;

  HazardGuidance get guidance => guidanceFor(hazard);

  Map<String, dynamic> toJson() => {
    'hazard': hazard.apiValue,
    'description': description.trim(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}

HazardGuidance guidanceFor(HazardType hazard) => switch (hazard) {
  HazardType.flood => const HazardGuidance(
    dos: ['Move to higher ground', 'Switch off electricity if it is safe'],
    donts: ['Do not walk or drive through flood water'],
  ),
  HazardType.fire => const HazardGuidance(
    dos: ['Leave by the nearest safe exit', 'Stay low below smoke'],
    donts: ['Do not use lifts or return for belongings'],
  ),
  HazardType.earthquake => const HazardGuidance(
    dos: [
      'Drop, cover, and hold on',
      'Move away from damaged buildings after shaking',
    ],
    donts: ['Do not run outside while the ground is shaking'],
  ),
  HazardType.landslide => const HazardGuidance(
    dos: [
      'Move away from the slide path',
      'Listen for unusual cracking or rumbling',
    ],
    donts: ['Do not cross active debris or unstable slopes'],
  ),
  HazardType.roadBlock => const HazardGuidance(
    dos: [
      'Use a marked alternate route',
      'Follow traffic and police instructions',
    ],
    donts: ['Do not move barriers or enter the closed road'],
  ),
  HazardType.severeWeather => const HazardGuidance(
    dos: ['Move indoors and away from windows', 'Charge essential devices'],
    donts: ['Do not shelter below trees or weak structures'],
  ),
  HazardType.infrastructureDamage => const HazardGuidance(
    dos: [
      'Keep a safe distance',
      'Warn people nearby without approaching the damage',
    ],
    donts: ['Do not touch fallen wires, leaking pipes, or unstable structures'],
  ),
  HazardType.other => const HazardGuidance(
    dos: [
      'Move away from immediate danger',
      'Follow verified local instructions',
    ],
    donts: ['Do not enter damaged or restricted areas'],
  ),
};
