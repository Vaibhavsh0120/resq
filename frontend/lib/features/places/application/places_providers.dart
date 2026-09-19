import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/places_repository.dart';
import '../domain/safe_place.dart';

typedef NearbyPlacesQuery = ({double latitude, double longitude});

final currentPositionProvider = FutureProvider<Position>((ref) async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationUnavailable(
      'Turn on location services to find nearby safe places.',
    );
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw const LocationUnavailable(
      'Location permission is needed to sort safe places by distance.',
    );
  }
  return Geolocator.getCurrentPosition();
});

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

final placesRepositoryProvider = Provider<PlacesRepository>(
  (ref) => FirestorePlacesRepository(FirebaseFirestore.instance),
);

final nearbyPlacesProvider =
    StreamProvider.family<List<SafePlace>, NearbyPlacesQuery>(
      (ref, location) => ref
          .watch(placesRepositoryProvider)
          .watchNearby(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
    );
