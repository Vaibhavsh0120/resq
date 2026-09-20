import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../app/navigation/root_router.dart';

Map<String, String> buildDeviceRegistrationPayload({
  required String token,
  required String platform,
}) => {'token': token, 'platform': platform};

class PushNotificationService {
  PushNotificationService._();

  static final instance = PushNotificationService._();

  static const _baseUrl = String.fromEnvironment(
    'RESQ_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const _webVapidKey = String.fromEnvironment('RESQ_FCM_VAPID_KEY');

  final _client = http.Client();
  bool _configured = false;

  bool get isSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  Future<void> configure() async {
    if (_configured || !isSupported) return;
    _configured = true;
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && !user.isAnonymous) {
        unawaited(_syncIfAuthorized());
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      unawaited(_registerTokenSafely(token));
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_openInbox);
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _openInbox(initialMessage);
    await _syncIfAuthorized();
  }

  Future<AuthorizationStatus> permissionStatus() async {
    if (!isSupported) return AuthorizationStatus.denied;
    return (await FirebaseMessaging.instance.getNotificationSettings())
        .authorizationStatus;
  }

  Future<bool> enable() async {
    if (!isSupported) return false;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    final allowed =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (allowed) await _syncToken();
    return allowed;
  }

  Future<void> _syncIfAuthorized() async {
    try {
      final status = await permissionStatus();
      if (status == AuthorizationStatus.authorized ||
          status == AuthorizationStatus.provisional) {
        await _syncToken();
      }
    } catch (_) {
      // Registration is retried on auth changes and FCM token refresh.
    }
  }

  Future<void> _registerTokenSafely(String token) async {
    try {
      await _registerToken(token);
    } catch (_) {
      // A durable inbox remains available even when push registration fails.
    }
  }

  Future<void> _syncToken() async {
    if (_isApplePlatform &&
        await FirebaseMessaging.instance.getAPNSToken() == null) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey: kIsWeb && _webVapidKey.isNotEmpty ? _webVapidKey : null,
    );
    if (token != null) await _registerToken(token);
  }

  Future<void> _registerToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !_hasSupportedPlatformName) return;
    final idToken = await user.getIdToken();
    if (idToken == null) return;
    final response = await _client.post(
      Uri.parse('$_baseUrl/v1/devices:register'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        buildDeviceRegistrationPayload(token: token, platform: _platformName),
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const PushRegistrationException();
    }
  }

  void _openInbox(RemoteMessage _) => rootRouter.go('/notifications');

  bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  bool get _hasSupportedPlatformName =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      _ => 'unsupported',
    };
  }
}

class PushRegistrationException implements Exception {
  const PushRegistrationException();
}
