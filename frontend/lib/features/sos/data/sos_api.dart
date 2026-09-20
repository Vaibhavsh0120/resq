import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class SosApi {
  SosApi({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = AppConfig.apiBaseUrl;

  final http.Client _client;

  Future<void> fanOut(String eventId) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;
    final response = await _client.post(
      Uri.parse('$_baseUrl/v1/sos/$eventId/fanout'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const SosFanoutException();
    }
  }
}

class SosFanoutException implements Exception {
  const SosFanoutException();
}
