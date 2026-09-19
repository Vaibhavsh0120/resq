import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';

final rootRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
  ],
);
