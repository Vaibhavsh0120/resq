class AppConfig {
  const AppConfig._();

  static const environment = String.fromEnvironment(
    'RESQ_APP_ENV',
    defaultValue: 'development',
  );
  static const apiBaseUrl = String.fromEnvironment(
    'RESQ_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
  static const useFirebaseEmulators = bool.fromEnvironment(
    'RESQ_USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  static const firebaseEmulatorHost = String.fromEnvironment(
    'RESQ_FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );
  static const fcmVapidKey = String.fromEnvironment('RESQ_FCM_VAPID_KEY');
  static const realtimeApiUrl = String.fromEnvironment(
    'RESQ_REALTIME_API_URL',
    defaultValue: 'https://api.openai.com/v1/realtime/calls',
  );

  static bool get isProduction => environment == 'production';
}
