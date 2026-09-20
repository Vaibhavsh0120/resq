import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CircleApi {
  CircleApi({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'RESQ_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  final http.Client _client;

  Future<String> createInvite({
    required String circleId,
    required String contact,
  }) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const CircleApiException('Sign in to invite a member.');
    }
    final isEmail = contact.contains('@');
    final response = await _client.post(
      Uri.parse('$_baseUrl/v1/circles/$circleId/invites'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        if (isEmail) 'email': contact else 'phone_number': contact,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const CircleApiException('The invitation could not be created.');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['invite_url']
        as String;
  }

  Future<void> acceptInvite(String inviteToken) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null ||
        FirebaseAuth.instance.currentUser?.isAnonymous == true) {
      throw const CircleApiException(
        'Sign in with a registered ResQ account to accept this invitation.',
      );
    }
    final response = await _client.post(
      Uri.parse('$_baseUrl/v1/circle-invites/$inviteToken/accept'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const CircleApiException(
        'This invitation is invalid, expired, or already used.',
      );
    }
  }
}

class CircleApiException implements Exception {
  const CircleApiException(this.message);
  final String message;
  @override
  String toString() => message;
}
