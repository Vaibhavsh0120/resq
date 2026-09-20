import 'dart:async';
import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'assistant_api.dart';

class RealtimeVoiceClient {
  RealtimeVoiceClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  MediaStream? _localStream;
  final RTCVideoRenderer _remoteAudio = RTCVideoRenderer();
  bool _rendererInitialized = false;

  RTCVideoRenderer get remoteRenderer => _remoteAudio;

  Future<void> connect({
    required VoiceSession session,
    required VoidCallback onConnected,
    required void Function(String message) onError,
    required ValueChanged<String> onUserTranscript,
    required ValueChanged<String> onAssistantTranscript,
  }) async {
    final token = session.ephemeralToken;
    if (session.transport != 'webrtc' || token == null || token.isEmpty) {
      throw const RealtimeVoiceException(
        'Realtime voice is not configured on this server.',
      );
    }

    try {
      await _remoteAudio.initialize();
      _rendererInitialized = true;
      final peer = await createPeerConnection({'sdpSemantics': 'unified-plan'});
      _peerConnection = peer;
      peer.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          _remoteAudio.srcObject = event.streams.first;
        }
      };
      peer.onConnectionState = (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          onError('The voice connection was interrupted.');
        }
      };

      final localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });
      _localStream = localStream;
      for (final track in localStream.getAudioTracks()) {
        await peer.addTrack(track, localStream);
      }

      final channel = await peer.createDataChannel(
        'oai-events',
        RTCDataChannelInit()..ordered = true,
      );
      _dataChannel = channel;
      channel.onDataChannelState = (state) {
        if (state == RTCDataChannelState.RTCDataChannelOpen) onConnected();
      };
      var assistantTranscript = '';
      channel.onMessage = (message) {
        if (message.isBinary) return;
        try {
          final event = jsonDecode(message.text) as Map<String, dynamic>;
          final type = event['type'] as String? ?? '';
          if (type == 'conversation.item.input_audio_transcription.completed') {
            final transcript = event['transcript'] as String?;
            if (transcript != null && transcript.trim().isNotEmpty) {
              onUserTranscript(transcript.trim());
            }
          } else if (type == 'response.audio_transcript.delta' ||
              type == 'response.output_audio_transcript.delta') {
            assistantTranscript += event['delta'] as String? ?? '';
          } else if (type == 'response.audio_transcript.done' ||
              type == 'response.output_audio_transcript.done') {
            final transcript =
                event['transcript'] as String? ?? assistantTranscript;
            if (transcript.trim().isNotEmpty) {
              onAssistantTranscript(transcript.trim());
            }
            assistantTranscript = '';
          } else if (type == 'error') {
            final error = Map<String, dynamic>.from(
              event['error'] as Map? ?? const {},
            );
            onError(error['message'] as String? ?? 'Voice service error.');
          }
        } catch (_) {
          // Ignore forward-compatible events that this client does not use.
        }
      };

      final offer = await peer.createOffer({'offerToReceiveAudio': true});
      await peer.setLocalDescription(offer);
      await _waitForIceGathering(peer);
      final localDescription = await peer.getLocalDescription();
      final response = await _http.post(
        Uri.parse(AppConfig.realtimeApiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/sdp',
        },
        body: localDescription?.sdp ?? offer.sdp,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RealtimeVoiceException(
          'Voice negotiation failed (${response.statusCode}).',
        );
      }
      await peer.setRemoteDescription(
        RTCSessionDescription(response.body, 'answer'),
      );
    } catch (_) {
      await close();
      rethrow;
    }
  }

  Future<void> _waitForIceGathering(RTCPeerConnection peer) async {
    if (await peer.getIceGatheringState() ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      return;
    }
    final completer = Completer<void>();
    peer.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !completer.isCompleted) {
        completer.complete();
      }
    };
    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  void setMuted(bool muted) {
    for (final track
        in _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> close() async {
    for (final track
        in _localStream?.getTracks() ?? const <MediaStreamTrack>[]) {
      await track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    await _dataChannel?.close();
    _dataChannel = null;
    await _peerConnection?.close();
    _peerConnection = null;
    if (_rendererInitialized) {
      _remoteAudio.srcObject = null;
      await _remoteAudio.dispose();
      _rendererInitialized = false;
    }
  }
}

class RealtimeVoiceException implements Exception {
  const RealtimeVoiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

typedef VoidCallback = void Function();
typedef ValueChanged<T> = void Function(T value);
