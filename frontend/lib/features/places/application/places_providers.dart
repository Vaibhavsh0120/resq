import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/places_repository.dart';

typedef NearbyPlacesQuery = ({double latitude, double longitude});

final currentPositionProvider = FutureProvider<Position>((ref) async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationUnavailable(
      'services_off',
    );
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw const LocationUnavailable(
      'permission_denied',
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
  (ref) => ApiPlacesRepository(),
);

final nearbyPlacesProvider =
    StreamProvider.family<PlaceFeed, NearbyPlacesQuery>(
      (ref, location) => ref
          .watch(placesRepositoryProvider)
          .watchNearby(
            latitude: location.latitude,
            longitude: location.longitude,
          ),
    );
