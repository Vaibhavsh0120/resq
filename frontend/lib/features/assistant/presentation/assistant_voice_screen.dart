import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../data/assistant_api.dart';
import '../domain/voice_turn_policy.dart';

class AssistantVoiceScreen extends ConsumerStatefulWidget {
  const AssistantVoiceScreen({super.key, this.conversationId});

  final String? conversationId;

  @override
  ConsumerState<AssistantVoiceScreen> createState() =>
      _AssistantVoiceScreenState();
}

class _AssistantVoiceScreenState extends ConsumerState<AssistantVoiceScreen> {
  final _api = AssistantApi();
  final _speech = SpeechToText();
  final _tts = FlutterTts();
  final _history = <AssistantPromptMessage>[];
  String? _conversationId;
  String? _error;
  String? _userTranscript;
  String? _assistantTranscript;
  bool _active = false;
  bool _listening = false;
  bool _processing = false;
  bool _speaking = false;
  bool _headphonesMode = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
  }

  Future<void> _start() async {
    if (_active) return;
    setState(() => _error = null);
    try {
      final available = await _speech.initialize(
        onError: (error) {
          if (mounted && _active && error.permanent) {
            setState(() {
              _error = 'Speech recognition is unavailable. Use the keyboard to continue.';
              _active = false;
              _listening = false;
            });
          }
        },
        onStatus: (status) {
          if (!mounted || !_active) return;
          if (status == 'done' || status == 'notListening') {
            setState(() => _listening = false);
            if (!_processing && !_speaking) {
              Future.delayed(const Duration(milliseconds: 350), () {
                if (mounted &&
                    _active &&
                    !_processing &&
                    !_speaking &&
                    !_listening) {
                  unawaited(_listen());
                }
              });
            }
          }
        },
      );
      if (!available) throw StateError('Speech recognition unavailable');
      await _tts.awaitSpeakCompletion(true);
      if (!mounted) return;
      setState(() => _active = true);
      await _listen();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Voice is unavailable on this device. Use the keyboard to continue.',
        );
      }
    }
  }

  Future<void> _listen() async {
    if (!_active ||
        _listening ||
        _processing ||
        (_speaking &&
            !canListenDuringSpeech(headphonesMode: _headphonesMode))) {
      return;
    }
    try {
      await _speech.listen(
        onResult: (result) {
          if (!mounted || !_active) return;
          final words = result.recognizedWords.trim();
          if (words.isNotEmpty) {
            setState(() => _userTranscript = words);
            if (_speaking && _headphonesMode) {
              unawaited(_tts.stop());
              setState(() => _speaking = false);
            }
          }
          if (result.finalResult && words.isNotEmpty) {
            unawaited(_answer(words));
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenFor: const Duration(seconds: 25),
          pauseFor: const Duration(seconds: 3),
          localeId: Localizations.localeOf(context).languageCode == 'hi'
              ? 'hi_IN'
              : 'en_IN',
        ),
      );
      if (mounted && _active) setState(() => _listening = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _active = false;
          _listening = false;
          _error = 'Microphone access failed. Use the keyboard to continue.';
        });
      }
    }
  }

  Future<void> _answer(String words) async {
    if (!_active || _processing) return;
    final languageCode = Localizations.localeOf(context).languageCode;
    final generation = ++_generation;
    setState(() {
      _processing = true;
      _listening = false;
      _speaking = false;
      _assistantTranscript = null;
    });
    await _speech.stop();
    await _tts.stop();
    try {
      final id =
          _conversationId ??
          await _api.createConversation(language: languageCode);
      _conversationId = id;
      final answer = StringBuffer();
      await for (final delta in _api.streamMessage(
        conversationId: id,
        text: words,
        inputType: 'voice',
        history: _history,
      )) {
        if (!mounted || !_active || generation != _generation) return;
        answer.write(delta);
        setState(() => _assistantTranscript = answer.toString());
      }
      if (!mounted || !_active || generation != _generation) return;
      final response = answer.toString().trim();
      if (response.isEmpty) throw StateError('Empty assistant response');
      _history.addAll([
        AssistantPromptMessage(role: 'user', text: words),
        AssistantPromptMessage(role: 'assistant', text: response),
      ]);
      setState(() {
        _processing = false;
        _speaking = true;
      });
      await _tts.setLanguage(languageCode == 'hi' ? 'hi-IN' : 'en-IN');
      final speaking = _tts.speak(response);
      if (canListenDuringSpeech(headphonesMode: _headphonesMode)) {
        unawaited(_listen());
      }
      await speaking;
      if (!mounted || !_active || generation != _generation) return;
      setState(() => _speaking = false);
      if (!_listening) await _listen();
    } catch (error) {
      if (!mounted || !_active || generation != _generation) return;
      final strings = AppLocalizations.of(context);
      final status = error is AssistantApiException ? error.statusCode : null;
      setState(() {
        _processing = false;
        _speaking = false;
        _error = status == 429
            ? strings.assistantDailyLimit
            : status == 503
            ? strings.assistantUnavailable
            : 'The assistant could not respond. You can try again or use the keyboard.';
        if (status == 429) _active = false;
      });
      if (_active) await _listen();
    }
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();
    if (!mounted || !_active) return;
    setState(() => _speaking = false);
    await _listen();
  }

  Future<void> _end() async {
    _generation++;
    setState(() {
      _active = false;
      _listening = false;
      _processing = false;
      _speaking = false;
    });
    await _speech.cancel();
    await _tts.stop();
  }

  Future<void> _openKeyboard() async {
    await _end();
    if (!mounted) return;
    final id = _conversationId;
    context.replace(
      Uri(
        path: '/assistant/chat',
        queryParameters: id == null ? null : {'conversationId': id},
      ).toString(),
    );
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_speech.cancel());
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _processing
        ? 'Thinking'
        : _speaking
        ? 'Speaking'
        : _listening
        ? 'Listening'
        : _active
        ? 'Ready to listen'
        : 'Voice is off';
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).voiceAssistant),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.graphic_eq_rounded,
                size: 76,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                liveRegion: true,
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error ?? 'Speak a short question. ResQ will answer aloud and listen again.',
                textAlign: TextAlign.center,
              ),
              if (_userTranscript != null || _assistantTranscript != null) ...[
                const SizedBox(height: AppSpacing.lg),
                if (_userTranscript != null) Text('You: $_userTranscript'),
                if (_assistantTranscript != null)
                  Text('ResQ: $_assistantTranscript'),
              ],
              const Spacer(),
              SwitchListTile(
                title: const Text('Headphones mode'),
                subtitle: const Text(
                  'Allows spoken interruption while ResQ speaks.',
                ),
                value: _headphonesMode,
                onChanged: (value) => setState(() => _headphonesMode = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!_active)
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Start voice'),
                )
              else ...[
                if (_speaking)
                  FilledButton.tonalIcon(
                    onPressed: _stopSpeaking,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop speaking'),
                  ),
                OutlinedButton.icon(
                  onPressed: _end,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('End voice'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
