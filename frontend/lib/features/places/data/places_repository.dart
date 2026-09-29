import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/safe_place.dart';

abstract interface class PlacesRepository {
  Stream<PlaceFeed> watchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  });
}

class PlaceFeed {
  const PlaceFeed({required this.items, required this.limited});
  final List<SafePlace> items;
  final bool limited;
}

class ApiPlacesRepository implements PlacesRepository {
  ApiPlacesRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Stream<PlaceFeed> watchNearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5,
  }) => Stream.fromFuture(
    _load(latitude: latitude, longitude: longitude, radiusKm: radiusKm),
  );

  Future<PlaceFeed> _load({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Sign in to find nearby places.');
    final places = <SafePlace>[];
    String? cursor;
    var limited = false;
    for (var page = 0; page < 5; page++) {
      final uri = Uri.parse('${AppConfig.apiBaseUrl}/v1/places/nearby').replace(
        queryParameters: {
          'lat': '$latitude',
          'lng': '$longitude',
          'radiusKm': '$radiusKm',
          'cursor': ?cursor,
        },
      );
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw StateError('Nearby places could not be loaded.');
      }
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      for (final item in result['items'] as List<dynamic>? ?? const []) {
        final map = Map<String, dynamic>.from(item as Map);
        places.add(SafePlace.fromMap(map['id'] as String, map));
      }
      cursor = result['nextCursor'] as String?;
      if (cursor == null) break;
      if (page == 4) limited = true;
    }
    places.sort(
      (a, b) => a
          .distanceKmFrom(latitude, longitude)
          .compareTo(b.distanceKmFrom(latitude, longitude)),
    );
    return PlaceFeed(items: List.unmodifiable(places), limited: limited);
  }
}
