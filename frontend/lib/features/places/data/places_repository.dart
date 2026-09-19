import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/safe_place.dart';

abstract interface class PlacesRepository {
  Stream<List<SafePlace>> watchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  });
}

class FirestorePlacesRepository implements PlacesRepository {
  FirestorePlacesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<SafePlace>> watchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  }) {
    return _firestore
        .collection('safePlaces')
        .where('verified', isEqualTo: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final places = snapshot.docs
              .map((doc) => SafePlace.fromMap(doc.id, doc.data()))
              .where(
                (place) =>
                    place.distanceKmFrom(latitude, longitude) <= radiusKm,
              )
              .toList();
          places.sort(
            (a, b) => a
                .distanceKmFrom(latitude, longitude)
                .compareTo(b.distanceKmFrom(latitude, longitude)),
          );
          return places;
        });
  }
}
