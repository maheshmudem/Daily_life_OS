import 'package:go_router/go_router.dart';
import '../../features/navigation/presentation/pages/main_navigation_shell.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'main',
        builder: (context, state) => const MainNavigationShell(),
      ),
    ],
  );
}
