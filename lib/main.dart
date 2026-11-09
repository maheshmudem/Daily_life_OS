import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'core/constants/string_constants.dart';
import 'core/database/app_database.dart';
import 'core/database/database_seeder.dart';
import 'core/notifications/notification_service.dart';
import 'di/injection_container.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Centralised BLoC error logging (and debug-only transition tracing)
  Bloc.observer = const AppBlocObserver();

  // Load environment variables safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Fallback if .env is not found or fails to load
  }

  // Initialize Dependency Injection
  await initDependencies();

  // Seed database with demo data on first launch (guarded by timeout so UI never hangs)
  try {
    final db = sl<AppDatabase>();
    await DatabaseSeeder.seedIfEmpty(db).timeout(const Duration(seconds: 4));
    await DatabaseSeeder.clearMoneyDemoDataOnce(
      db,
    ).timeout(const Duration(seconds: 2));
  } catch (e, stack) {
    debugPrint('Database seeding notice/error: $e\n$stack');
  }

  runApp(DailyLifeOSApp(router: createRouter()));

  // Initialize Notification Service & permissions asynchronously after UI mounts
  unawaited(_initNotificationsSafely());
}

Future<void> _initNotificationsSafely() async {
  try {
    final notificationService = sl<NotificationService>();
    await notificationService.initialize();
    await notificationService.requestPermissions();
  } catch (e, stack) {
    debugPrint('Notification service initialization notice/error: $e\n$stack');
  }
}

class DailyLifeOSApp extends StatefulWidget {
  final GoRouter? router;

  const DailyLifeOSApp({super.key, this.router});

  @override
  State<DailyLifeOSApp> createState() => _DailyLifeOSAppState();
}

class _DailyLifeOSAppState extends State<DailyLifeOSApp> {
  late final GoRouter _effectiveRouter;

  @override
  void initState() {
    super.initState();
    _effectiveRouter = widget.router ?? createRouter();
  }

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<ProfileBloc>()) {
      return MaterialApp.router(
        title: StringConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _effectiveRouter,
      );
    }

    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: sl<ProfileBloc>(),
      buildWhen: (prev, curr) =>
          prev.profile.themeMode != curr.profile.themeMode ||
          prev.profile.currencyCode != curr.profile.currencyCode,
      builder: (context, profileState) {
        final mode = switch (profileState.profile.themeMode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
        return MaterialApp.router(
          title: StringConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          routerConfig: _effectiveRouter,
        );
      },
    );
  }
}
