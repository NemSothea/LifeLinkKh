import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';

/// Declarative route table. go_router is here from M2 because M5 opens a specific
/// request from an FCM notification tap — that is a deep link, and retrofitting one
/// onto hand-rolled navigation is the expensive way to do it.
final appRouter = GoRouter(
    initialLocation: '/',
    routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    ],
);
