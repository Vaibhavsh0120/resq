import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/india_event.dart';

class IndiaEventFeed {
  const IndiaEventFeed({
    this.items = const [],
    this.status = 'not_run',
    this.lastCheckedAt,
    this.truncated = false,
  });

  final List<IndiaEvent> items;
  final String status;
  final DateTime? lastCheckedAt;
  final bool truncated;
}

abstract interface class IndiaEventsRepository {
  Stream<IndiaEventFeed> watchRecent();
}

class ApiIndiaEventsRepository implements IndiaEventsRepository {
  ApiIndiaEventsRepository({http.Client? client})
    : _client = client ?? http.Client();
  final http.Client _client;

  @override
  Stream<IndiaEventFeed> watchRecent() => Stream.fromFuture(_load());

  Future<IndiaEventFeed> _load() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw StateError('Sign in to see India-wide events.');
    }
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/v1/alerts/india'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw StateError('India events could not be loaded.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => IndiaEvent.fromMap(Map<String, dynamic>.from(item)))
        .whereType<IndiaEvent>()
        .take(50)
        .toList();
    final health = Map<String, dynamic>.from(
      data['sourceHealth'] as Map? ?? const {},
    );
    return IndiaEventFeed(
      items: List.unmodifiable(items),
      status: health['status'] as String? ?? 'not_run',
      lastCheckedAt: DateTime.tryParse(
        health['lastCheckedAt'] as String? ?? '',
      ),
      truncated: health['truncated'] as bool? ?? false,
    );
  }
}
