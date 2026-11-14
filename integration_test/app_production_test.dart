import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/core/monitoring/app_monitor.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:daily_life_os/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/core/notifications/fake_notification_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Real Device Integration Test: Launch OS, open Profile Sheet, toggle Dark Mode, and navigate modules',
    (tester) async {
      AppMonitor.instance.reset();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('os_pref_theme_mode', 'light');

      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await initDependencies(
        database: db,
        notificationService: FakeNotificationService(),
      );
      await DatabaseSeeder.seedIfEmpty(db);

      await tester.pumpWidget(const DailyLifeOSApp());
      await tester.pumpAndSettle();

      Element rootScaffold() => tester.element(find.byType(Scaffold).first);
      expect(Theme.of(rootScaffold()).brightness, Brightness.light);

      // Tap Profile Avatar on Today Hub
      await tester.tap(
        find.byKey(const ValueKey('today_profile_avatar_button')),
      );
      await tester.pumpAndSettle();

      // Toggle Dark Mode ON from Profile Sheet
      final darkSwitch = find.byKey(const ValueKey('toggle_dark_mode_switch'));
      expect(darkSwitch, findsOneWidget);
      await tester.tap(darkSwitch);
      await tester.pumpAndSettle();

      expect(sl<ProfileBloc>().state.profile.themeMode, 'dark');
      expect(Theme.of(rootScaffold()).brightness, Brightness.dark);

      // Close sheet & verify Planner, Notes, Vault in Dark Mode on device
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      for (final tab in [
        StringConstants.navPlanner,
        StringConstants.navNotes,
        StringConstants.navVault,
        StringConstants.navTodayTab,
      ]) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(Theme.of(rootScaffold()).brightness, Brightness.dark);
      }

      expect(AppMonitor.instance.snapshot().totalErrors, 0);
    },
  );
}
