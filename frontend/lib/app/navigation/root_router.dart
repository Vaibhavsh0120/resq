import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';
import '../../features/family/presentation/circle_invite_accept_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

final rootRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
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
