import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'config/routes/app_router.dart';
import 'config/theme/app_theme.dart';
import 'core/constants/string_constants.dart';
import 'core/database/app_database.dart';
import 'core/database/database_seeder.dart';
import 'di/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Fallback if .env is not found or fails to load
  }

  // Initialize Dependency Injection
  await initDependencies();

  // Seed database with demo data on first launch
  try {
    final db = sl<AppDatabase>();
    await DatabaseSeeder.seedIfEmpty(db);
  } catch (e, stack) {
    debugPrint('Database seeding notice/error: $e\n$stack');
  }

  runApp(DailyLifeOSApp(router: createRouter()));
}

class DailyLifeOSApp extends StatelessWidget {
  final GoRouter? router;

  const DailyLifeOSApp({super.key, this.router});

  @override
  Widget build(BuildContext context) {
    final effectiveRouter = router ?? createRouter();

    return MaterialApp.router(
      title: StringConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: effectiveRouter,
    );
  }
}
