import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

class AdminApi {
  AdminApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('Sign in as an administrator.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}/v1/admin/$path');

  Future<List<Map<String, dynamic>>> list(String path) async {
    final response = await _client.get(_uri(path), headers: await _headers());
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<Uint8List> photo(String reportId) async {
    final response = await _client.get(
      _uri('reports/$reportId/photo'),
      headers: await _headers(),
    );
    _check(response);
    return response.bodyBytes;
  }

  Future<void> post(String path, Map<String, dynamic> body) async {
    final response = await _client.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    _check(response);
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Admin request failed (${response.statusCode}).');
    }
  }
}
