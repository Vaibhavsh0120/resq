import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';
import '../../features/family/presentation/circle_invite_accept_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/assistant/presentation/assistant_chat_screen.dart';
import '../../features/assistant/presentation/assistant_voice_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/personal_information_screen.dart';
import '../../features/profile/presentation/privacy_settings_screen.dart';
import '../../features/profile/presentation/sos_history_screen.dart';
import '../../features/readiness/presentation/readiness_screen.dart';
import '../../features/sos/presentation/sos_screen.dart';
import '../../features/sos/presentation/sos_event_detail_screen.dart';
import '../../services/auth_service.dart';

final rootRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(
      path: '/app/:destination',
      builder: (context, state) => AuthGate(
        initialDestination: state.pathParameters['destination'] ?? 'home',
      ),
    ),
    GoRoute(path: '/sos', builder: (context, state) => const SosScreen()),
    GoRoute(
      path: '/sos/:eventId',
      builder: (context, state) =>
          SosEventDetailScreen(eventId: state.pathParameters['eventId']!),
    ),
    GoRoute(
      path: '/readiness',
      builder: (context, state) => ReadinessScreen(
        isGuest: AuthService.instance.currentUser?.isAnonymous ?? true,
      ),
    ),
    GoRoute(
      path: '/assistant/chat',
      builder: (context, state) => AssistantChatScreen(
        conversationId: state.uri.queryParameters['conversationId'],
      ),
    ),
    GoRoute(
      path: '/assistant/voice',
      builder: (context, state) => AssistantVoiceScreen(
        conversationId: state.uri.queryParameters['conversationId'],
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(
        isGuest: AuthService.instance.currentUser?.isAnonymous ?? true,
      ),
    ),
    GoRoute(
      path: '/profile/information',
      builder: (context, state) => const PersonalInformationScreen(),
    ),
    GoRoute(
      path: '/profile/sos-history',
      builder: (context, state) => const SosHistoryScreen(),
    ),
    GoRoute(
      path: '/profile/privacy',
      builder: (context, state) =>
          const PrivacySettingsScreen(notificationsOnly: false),
    ),
    GoRoute(
      path: '/profile/notification-preferences',
      builder: (context, state) =>
          const PrivacySettingsScreen(notificationsOnly: true),
    ),
    GoRoute(
      path: '/invite/:token',
      builder: (context, state) =>
          CircleInviteAcceptScreen(token: state.pathParameters['token']!),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);
