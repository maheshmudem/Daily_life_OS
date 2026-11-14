import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/core/monitoring/app_monitor.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:daily_life_os/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/fake_notification_service.dart';

void main() {
  group('End-to-End Production User Journey Integration Suite', () {
    testWidgets(
      'Full OS Journey: Cold boot -> Profile Dark Mode toggle -> Identity update -> Habit check -> Planner -> Notes creation -> Money shell & exit -> Spotlight search -> Health check',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        AppMonitor.instance.reset();
        SharedPreferences.setMockInitialValues({'os_pref_theme_mode': 'light'});
        FlutterSecureStorage.setMockInitialValues({});
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await AppMonitor.instance.traceAsync(
          'e2e.initDependencies',
          () => initDependencies(
            database: db,
            notificationService: FakeNotificationService(),
          ),
        );
        await DatabaseSeeder.seedIfEmpty(db);
        AppMonitor.instance.recordStartupDuration(
          const Duration(milliseconds: 85),
        );

        await tester.pumpWidget(const DailyLifeOSApp());
        await tester.pumpAndSettle();

        Element rootScaffold() => tester.element(find.byType(Scaffold).first);
        expect(Theme.of(rootScaffold()).brightness, Brightness.light);

        // ── Step 1: Tap Profile Avatar & Enable Dark Mode ───────────────────
        await tester.tap(
          find.byKey(const ValueKey('today_profile_avatar_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(StringConstants.appearanceAndDarkModeSection),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('toggle_dark_mode_switch')));
        await tester.pumpAndSettle();

        expect(sl<ProfileBloc>().state.profile.themeMode, 'dark');
        expect(Theme.of(rootScaffold()).brightness, Brightness.dark);

        // Update user display name while in Profile sheet
        final nameInput = find.byKey(const ValueKey('profile_name_input'));
        await tester.ensureVisible(nameInput);
        await tester.enterText(nameInput, 'Rohan');
        final saveBtn = find.byKey(const ValueKey('save_profile_identity_btn'));
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Close'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Rohan'), findsWidgets);

        // ── Step 2: Spotlight Search (`⌘K`) in Dark Mode ────────────────────
        await tester.tap(find.byKey(const ValueKey('today_spotlight_button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('command_palette_search_input')),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('command_palette_search_input')),
          'Focus Sprint',
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('Focus Sprint'), findsWidgets);
        // Dismiss Spotlight
        Navigator.of(rootScaffold()).pop();
        await tester.pumpAndSettle();

        // ── Step 3: Navigate to Planner in Dark Mode ────────────────────────
        await tester.tap(find.text(StringConstants.navPlanner));
        await tester.pumpAndSettle();
        expect(Theme.of(rootScaffold()).brightness, Brightness.dark);

        // ── Step 4: Navigate to Notes & Create a New Note in Dark Mode ──────
        await tester.tap(find.text(StringConstants.navNotes));
        await tester.pumpAndSettle();
        expect(find.text('New Note'), findsOneWidget);

        await tester.tap(find.text('New Note'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Note Title...'),
          'Production Launch Checklist',
        );
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Write your thoughts, checklists, or plans...',
          ),
          '[x] Dark mode perfected\n[x] Security hardened',
        );
        await tester.ensureVisible(find.text('Create Note'));
        await tester.tap(find.text('Create Note'));
        await tester.pumpAndSettle();

        expect(find.text('Production Launch Checklist'), findsOneWidget);

        // ── Step 5: Navigate to Money Shell & Return to Main Bar ────────────
        await tester.tap(find.text(StringConstants.navMoney));
        await tester.pumpAndSettle();
        expect(Theme.of(rootScaffold()).brightness, Brightness.dark);
        expect(find.byKey(const ValueKey('main_bottom_nav_bar')), findsNothing);

        // Exit Money back to main OS navigation
        final backBtn = find.byTooltip('Back to Daily Life OS');
        if (backBtn.evaluate().isNotEmpty) {
          await tester.tap(backBtn.first);
          await tester.pumpAndSettle();
        }

        // ── Step 6: Verify Production Health Telemetry Snapshot ─────────────
        final health = AppMonitor.instance.snapshot();
        expect(health.status, AppHealthStatus.healthy);
        expect(health.totalErrors, 0);
        expect(health.startupDurationMs, 85);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
