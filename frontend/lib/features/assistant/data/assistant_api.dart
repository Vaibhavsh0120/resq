import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class AssistantApi {
  AssistantApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<AssistantConversation>> listConversations() async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/v1/ai/conversations'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map(
          (item) => AssistantConversation.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  Future<AssistantConversationDetail> getConversation(String id) async {
    final response = await _client.get(
      Uri.parse('${AppConfig.apiBaseUrl}/v1/ai/conversations/$id'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    return AssistantConversationDetail.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<String> createConversation({String language = 'en'}) async {
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/v1/ai/conversations'),
      headers: await _headers(),
      body: jsonEncode({'language': language}),
    );
    _ensureSuccess(response);
    return jsonDecode(response.body)['id'] as String;
  }

  Future<VoiceSession> createVoiceSession({
    String? conversationId,
    String language = 'en',
  }) async {
    final id = conversationId ?? await createConversation(language: language);
    final response = await _client.post(
      Uri.parse('${AppConfig.apiBaseUrl}/v1/ai/voice/sessions'),
      headers: await _headers(),
      body: jsonEncode({
        'conversation_id': id,
        'language': language,
        'consent_categories': await _consentCategories(),
      }),
    );
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return VoiceSession(
      conversationId: json['conversation_id'] as String,
      transport: json['transport'] as String,
      ephemeralToken: json['ephemeral_token'] as String?,
    );
  }

  Future<void> saveVoiceTranscript({
    required String conversationId,
    String? userText,
    String? assistantText,
  }) async {
    if ((userText == null || userText.trim().isEmpty) &&
        (assistantText == null || assistantText.trim().isEmpty)) {
      return;
    }
    final response = await _client.post(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/v1/ai/conversations/$conversationId/voice-transcript',
      ),
      headers: await _headers(),
      body: jsonEncode({
        'user_text': userText,
        'assistant_text': assistantText,
      }),
    );
    _ensureSuccess(response);
  }

  Stream<String> streamMessage({
    required String conversationId,
    required String text,
    List<AssistantPromptMessage> history = const [],
    void Function(AssistantCitation citation)? onCitation,
  }) async* {
    final request =
        http.Request(
            'POST',
            Uri.parse(
              '${AppConfig.apiBaseUrl}/v1/ai/conversations/$conversationId/messages:stream',
            ),
          )
          ..headers.addAll(await _headers())
          ..body = jsonEncode({
            'text': text,
            'history': history
                .skip(history.length > 20 ? history.length - 20 : 0)
                .map((message) => message.toJson())
                .toList(growable: false),
            'consent_categories': await _consentCategories(),
          });
    final response = await _client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AssistantApiException(
        'Assistant request failed (${response.statusCode}).',
      );
    }

    String? eventType;
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (line.startsWith('event: ')) {
        eventType = line.substring(7);
        continue;
      }
      if (!line.startsWith('data: ')) continue;
      final payload = jsonDecode(line.substring(6)) as Map<String, dynamic>;
      if (eventType == 'citation') {
        onCitation?.call(AssistantCitation.fromJson(payload));
        continue;
      }
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

  Future<List<String>> _consentCategories() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return const [];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('app')
          .get();
      final consent = Map<String, dynamic>.from(
        snapshot.data()?['aiConsent'] as Map? ?? const {},
      );
      final result = <String>[];
      if (consent['readiness'] == true) result.add('readiness');
      if (consent['coarseLocation'] == true) result.add('coarse_location');
      if (consent['preciseLocation'] == true) result.add('precise_location');
      if (consent['medical'] == true) result.add('medical');
      if (consent['family'] == true) result.add('family');
      return result;
    } catch (_) {
      return const [];
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AssistantApiException(
        'Assistant request failed (${response.statusCode}).',
      );
    }
  }
}

class AssistantPromptMessage {
  const AssistantPromptMessage({required this.role, required this.text});

  final String role;
  final String text;

  Map<String, String> toJson() => {'role': role, 'text': text};
}

class AssistantApiException implements Exception {
  const AssistantApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class VoiceSession {
  const VoiceSession({
    required this.conversationId,
    required this.transport,
    this.ephemeralToken,
  });

  final String conversationId;
  final String transport;
  final String? ephemeralToken;
}

class AssistantConversation {
  const AssistantConversation({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime updatedAt;

  factory AssistantConversation.fromJson(Map<String, dynamic> json) =>
      AssistantConversation(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'New conversation',
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.inputType,
    this.citations = const [],
  });

  final String id;
  final String role;
  final String text;
  final String inputType;
  final List<AssistantCitation> citations;

  bool get isUser => role == 'user';

  factory AssistantMessage.fromJson(Map<String, dynamic> json) =>
      AssistantMessage(
        id: json['id'] as String,
        role: json['role'] as String? ?? 'assistant',
        text: json['text'] as String? ?? '',
        inputType: json['input_type'] as String? ?? 'text',
        citations: (json['citations'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map(
              (item) =>
                  AssistantCitation.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false),
      );
}

class AssistantCitation {
  const AssistantCitation({
    required this.title,
    required this.url,
    this.freshness = '',
  });

  final String title;
  final String url;
  final String freshness;

  factory AssistantCitation.fromJson(Map<String, dynamic> json) =>
      AssistantCitation(
        title: json['title'] as String? ?? 'Source',
        url: json['url'] as String? ?? '',
        freshness: json['freshness'] as String? ?? '',
      );
}

class AssistantConversationDetail extends AssistantConversation {
  const AssistantConversationDetail({
    required super.id,
    required super.title,
    required super.updatedAt,
    required this.messages,
  });

  final List<AssistantMessage> messages;

  factory AssistantConversationDetail.fromJson(Map<String, dynamic> json) =>
      AssistantConversationDetail(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'New conversation',
        updatedAt:
            DateTime.tryParse(json['updated_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        messages: (json['messages'] as List<dynamic>? ?? const [])
            .map(
              (message) => AssistantMessage.fromJson(
                Map<String, dynamic>.from(message as Map),
              ),
            )
            .toList(growable: false),
      );
}
