import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/sos_event.dart';

class SosApi {
  SosApi({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = AppConfig.apiBaseUrl;

  final http.Client _client;

  Future<SosCreatedEvent> create(SosCreatePayload payload) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const SosFanoutException();
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/v1/sos'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload.toMap()),
        )
        .timeout(const Duration(seconds: 90));
    if (response.statusCode != 201) throw const SosFanoutException();
    return SosCreatedEvent.fromMap(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<String> fanOut(String eventId) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return 'pending';
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/v1/sos/$eventId/fanout'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SosFanoutException();
    }
    return (jsonDecode(response.body)
                as Map<String, dynamic>)['delivery_status']
            as String? ??
        'pending';
  }
}

class SosFanoutException implements Exception {
  const SosFanoutException();
}
