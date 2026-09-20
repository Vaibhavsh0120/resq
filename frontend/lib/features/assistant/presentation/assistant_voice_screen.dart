import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../data/assistant_api.dart';
import '../data/realtime_voice_client.dart';

class AssistantVoiceScreen extends StatefulWidget {
  const AssistantVoiceScreen({super.key, this.conversationId});

  final String? conversationId;

  @override
  State<AssistantVoiceScreen> createState() => _AssistantVoiceScreenState();
}

class _AssistantVoiceScreenState extends State<AssistantVoiceScreen> {
  final _api = AssistantApi();
  final _voiceClient = RealtimeVoiceClient();
  String? _conversationId;
  bool _connecting = true;
  bool _connected = false;
  bool _muted = false;
  String? _error;
  String? _userTranscript;
  String? _assistantTranscript;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    await _voiceClient.close();
    if (!mounted) return;
    setState(() {
      _connecting = true;
      _connected = false;
      _muted = false;
      _error = null;
    });
    try {
      final session = await _api.createVoiceSession(
        conversationId: _conversationId ?? widget.conversationId,
        language: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = session.conversationId;
      });
      await _voiceClient.connect(
        session: session,
        onConnected: () {
          if (!mounted) return;
          setState(() {
            _connecting = false;
            _connected = true;
          });
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _connecting = false;
            _connected = false;
            _error = message;
          });
        },
        onUserTranscript: (transcript) {
          if (!mounted) return;
          setState(() => _userTranscript = transcript);
          unawaited(
            _api.saveVoiceTranscript(
              conversationId: session.conversationId,
              userText: transcript,
            ),
          );
        },
        onAssistantTranscript: (transcript) {
          if (!mounted) return;
          setState(() => _assistantTranscript = transcript);
          unawaited(
            _api.saveVoiceTranscript(
              conversationId: session.conversationId,
              assistantText: transcript,
            ),
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = 'Voice could not connect. You can continue this conversation with the keyboard.';
      });
    }
  }

  Future<void> _openKeyboard() async {
    await _voiceClient.close();
    if (!mounted) return;
    final id = _conversationId ?? widget.conversationId;
    context.replace(
      Uri(
        path: '/assistant/chat',
        queryParameters: id == null ? null : {'conversationId': id},
      ).toString(),
    );
  }

  Future<void> _end() async {
    await _voiceClient.close();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    unawaited(_voiceClient.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.voiceAssistant),
        actions: [
          IconButton(
            tooltip: 'Switch to keyboard',
            onPressed: _openKeyboard,
            icon: const Icon(Icons.keyboard_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              if (_connected)
                SizedBox.square(
                  dimension: 1,
                  child: RTCVideoView(_voiceClient.remoteRenderer),
                ),
              const Spacer(),
              Container(
                width: 156,
                height: 156,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.secondary
                      .withValues(alpha: .14),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _connecting
                    ? 'Connecting…'
                    : _error != null
                    ? 'Voice unavailable'
                    : _muted
                    ? 'Microphone muted'
                    : _connected
                    ? 'Listening'
                    : 'Starting voice session…',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error ?? 'Speak to ResQ. Switch to keyboard anytime.',
                textAlign: TextAlign.center,
              ),
              if (_userTranscript != null || _assistantTranscript != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 620),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(AppRadius.base),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_userTranscript != null)
                          Text('You: ${_userTranscript!}'),
                        if (_assistantTranscript != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text('ResQ: ${_assistantTranscript!}'),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _connect,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try voice again'),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: !_connected || _error != null
                        ? null
                        : () {
                            setState(() => _muted = !_muted);
                            _voiceClient.setMuted(_muted);
                          },
                    tooltip: _muted ? 'Unmute microphone' : 'Mute microphone',
                    icon: Icon(
                      _muted ? Icons.mic_rounded : Icons.mic_off_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  IconButton.filled(
                    onPressed: _end,
                    tooltip: 'End voice',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
