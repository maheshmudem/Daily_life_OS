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
import 'core/monitoring/app_monitor.dart';
import 'core/notifications/notification_service.dart';
import 'core/utils/currency_utils.dart';
import 'core/widgets/app_user_error_banner.dart';
import 'di/injection_container.dart';
import 'features/profile/presentation/bloc/profile_bloc.dart';

void main() async {
  final bootStopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  // Production crash & platform error boundaries + UI frame jank telemetry
  AppMonitor.instance
    ..installGlobalErrorHandlers()
    ..attachFrameTimingObserver();

  Bloc.observer = const AppBlocObserver();

  // Load environment variables (gracefully ignore if .env missing)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Offline-first fallback
  }

  // Initialize Clean Architecture Service Locator (GetIt)
  await AppMonitor.instance.traceAsync(
    'startup.initDependencies',
    initDependencies,
  );

  // Seed default offline SQLite rows on first run
  await AppMonitor.instance.traceAsync(
    'startup.seedDatabase',
    () => DatabaseSeeder.seedIfEmpty(sl<AppDatabase>()),
  );

  // Local notifications are non-critical on startup — fire-and-forget so
  // cold-start isn't blocked by OS permission channels.
  unawaited(
    sl<NotificationService>().initialize().catchError((Object e, StackTrace s) {
      AppMonitor.instance.recordError(e, s, source: 'notifications.init');
    }),
  );

  bootStopwatch.stop();
  AppMonitor.instance.recordStartupDuration(bootStopwatch.elapsed);

  runApp(const DailyLifeOSApp());
}

class DailyLifeOSApp extends StatefulWidget {
  const DailyLifeOSApp({super.key});

  @override
  State<DailyLifeOSApp> createState() => _DailyLifeOSAppState();
}

class _DailyLifeOSAppState extends State<DailyLifeOSApp> {
  // Created once per app lifetime so theme / locale / currency rebuilds never
  // recreate the router and blow away navigation state.
  late final GoRouter _router = createRouter();

  ThemeMode _resolveThemeMode(String raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
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
        themeAnimationDuration: const Duration(milliseconds: 220),
        themeAnimationCurve: Curves.easeOutCubic,
        builder: (context, child) =>
            AppMonitorUserErrorHost(child: child ?? const SizedBox.shrink()),
        routerConfig: _router,
      );
    }

    final profileBloc = sl<ProfileBloc>();

    return BlocProvider<ProfileBloc>.value(
      value: profileBloc,
      child: BlocBuilder<ProfileBloc, ProfileState>(
        bloc: profileBloc,
        buildWhen: (prev, curr) =>
            prev.profile.themeMode != curr.profile.themeMode ||
            prev.profile.currencyCode != curr.profile.currencyCode,
        builder: (context, profileState) {
          CurrencyUtils.setCurrency(profileState.profile.currencyCode);
          return MaterialApp.router(
            title: StringConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _resolveThemeMode(profileState.profile.themeMode),
            themeAnimationDuration: const Duration(milliseconds: 220),
            themeAnimationCurve: Curves.easeOutCubic,
            builder: (context, child) => AppMonitorUserErrorHost(
              child: child ?? const SizedBox.shrink(),
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
