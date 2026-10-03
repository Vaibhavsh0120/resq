import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/public_alert.dart';

class AlertFeed {
  const AlertFeed({
    this.items = const [],
    this.coverage = 'unknown',
    this.sources = const [],
    this.homeLatitude,
    this.homeLongitude,
  });

  final List<PublicAlert> items;
  final String coverage;
  final List<AlertSourceHealth> sources;
  final double? homeLatitude;
  final double? homeLongitude;
}

class AlertSourceHealth {
  const AlertSourceHealth({
    required this.source,
    required this.status,
    this.lastCheckedAt,
    this.truncated = false,
  });

  final String source;
  final String status;
  final DateTime? lastCheckedAt;
  final bool truncated;
}

abstract interface class AlertsRepository {
  Stream<AlertFeed> watchActive();
}

class ApiAlertsRepository implements AlertsRepository {
  ApiAlertsRepository({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Stream<AlertFeed> watchActive() => Stream.fromFuture(_load());

  Future<AlertFeed> _load() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Sign in to see local alerts.');
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/v1/alerts/nearby'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('Alerts could not be loaded.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map((item) => PublicAlert.fromMap(item['id'] as String, item))
        .where((item) => item.isActiveAt(DateTime.now()))
        .toList();
    items.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    final sources = (data['sourceHealth'] as List<dynamic>? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .map(
          (item) => AlertSourceHealth(
            source: item['source'] as String? ?? 'Source',
            status: item['status'] as String? ?? 'unknown',
            lastCheckedAt: DateTime.tryParse(
              item['lastCheckedAt'] as String? ?? '',
            ),
            truncated: item['truncated'] as bool? ?? false,
          ),
        )
        .toList();
    return AlertFeed(
      items: List.unmodifiable(items),
      coverage: data['coverage'] as String? ?? 'unknown',
      sources: List.unmodifiable(sources),
      homeLatitude: (data['homeCenter'] as Map?)?['latitude'] is num
          ? ((data['homeCenter'] as Map)['latitude'] as num).toDouble()
          : null,
      homeLongitude: (data['homeCenter'] as Map?)?['longitude'] is num
          ? ((data['homeCenter'] as Map)['longitude'] as num).toDouble()
          : null,
    );
  }
}
