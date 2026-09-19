import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AssistantApi {
  AssistantApi({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = String.fromEnvironment(
    'RESQ_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  final http.Client _client;

  Future<String> createConversation() async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/v1/ai/conversations'),
      headers: await _headers(),
      body: jsonEncode({'language': 'en'}),
    );
    _ensureSuccess(response);
    return jsonDecode(response.body)['id'] as String;
  }

  Stream<String> streamMessage({
    required String conversationId,
    required String text,
  }) async* {
    final request =
        http.Request(
            'POST',
            Uri.parse(
              '$_baseUrl/v1/ai/conversations/$conversationId/messages:stream',
            ),
          )
          ..headers.addAll(await _headers())
          ..body = jsonEncode({'text': text, 'consent_categories': <String>[]});
    final response = await _client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AssistantApiException(
        'Assistant request failed (${response.statusCode}).',
      );
    }

    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (!line.startsWith('data: ')) continue;
      final payload = jsonDecode(line.substring(6)) as Map<String, dynamic>;
      final delta = payload['delta'] as String?;
      if (delta != null) yield delta;
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const AssistantApiException('Sign in to use the assistant.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    };
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AssistantApiException(
        'Assistant request failed (${response.statusCode}).',
      );
    }
  }
}

class AssistantApiException implements Exception {
  const AssistantApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
