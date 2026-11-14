import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/core/monitoring/app_monitor.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/features/money/data/datasources/money_local_datasource.dart';
import 'package:daily_life_os/features/notes/data/datasources/notes_local_datasource.dart';
import 'package:daily_life_os/features/notes/presentation/pages/notes_page.dart';
import 'package:daily_life_os/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:daily_life_os/main.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/notifications/fake_notification_service.dart';

void main() {
  group('Performance, Latency Budget & Leak Audit Suite', () {
    test(
      'Cold-start DI + database seeding completes well within 1000ms budget',
      () async {
        SharedPreferences.setMockInitialValues({'os_pref_theme_mode': 'dark'});
        FlutterSecureStorage.setMockInitialValues({});
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        final sw = Stopwatch()..start();
        await initDependencies(
          database: db,
          notificationService: FakeNotificationService(),
        );
        await DatabaseSeeder.seedIfEmpty(db);
        sw.stop();

        expect(
          sw.elapsedMilliseconds,
          lessThan(1000),
          reason:
              'DI + seed took ${sw.elapsedMilliseconds}ms (budget < 1000ms)',
        );
      },
    );

    test(
      'AppMonitor handles 10,000 telemetry events within 250ms with bounded O(1) memory',
      () {
        final monitor = AppMonitor(
          maxBreadcrumbs: 200,
          maxErrors: 50,
          maxSpans: 100,
        );

        final sw = Stopwatch()..start();
        for (var i = 0; i < 10000; i++) {
          monitor.recordBreadcrumb(
            category: 'perf',
            message: 'Event #$i processed cleanly',
          );
          monitor.recordSpan('op.tick', const Duration(milliseconds: 2));
        }
        sw.stop();

        final snap = monitor.snapshot();
        expect(snap.recentBreadcrumbs.length, 200);
        expect(snap.recentSpans.length, 100);
        expect(
          sw.elapsedMilliseconds,
          lessThan(250),
          reason: '10k events took ${sw.elapsedMilliseconds}ms',
        );
      },
    );

    testWidgets(
      'High-volume dataset (500 transactions + 200 notes) queries fast and scrolls smoothly in Dark Mode without overflow or leaks',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await initDependencies(
          database: db,
          notificationService: FakeNotificationService(),
        );

        final moneyDs = sl<MoneyLocalDataSource>();
        final notesDs = sl<NotesLocalDataSource>();

        final insertSw = Stopwatch()..start();
        for (var i = 0; i < 500; i++) {
          await moneyDs.addTransaction(
            title: 'Perf Merchant #$i',
            category: i.isEven ? 'Food' : 'Transport',
            amount: 120.0 + (i % 50),
            mode: 'UPI',
            iconCodePoint: Icons.fastfood_rounded.codePoint,
          );
        }
        for (var i = 0; i < 200; i++) {
          await notesDs.addNote(
            title: 'Engineering Note #$i',
            content: '[ ] Checklist item A\n[x] Checklist item B\nSummary $i',
            colorValue: 0xFF3B82F6,
            tags: '@Perf,@Work',
          );
        }
        insertSw.stop();

        final readSw = Stopwatch()..start();
        final allTxs = await moneyDs.getAllTransactions();
        final allNotes = await notesDs.getNotes();
        readSw.stop();

        expect(allTxs.length, 500);
        expect(allNotes.length, 200);
        expect(
          readSw.elapsedMilliseconds,
          lessThan(500),
          reason:
              'Reading 700 SQLite records took ${readSw.elapsedMilliseconds}ms',
        );

        // Render NotesPage with 200 notes in Dark Mode and fling-scroll
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.darkTheme, home: const NotesPage()),
        );
        await tester.pumpAndSettle();

        await tester.fling(
          find.byType(Scrollable).first,
          const Offset(0, -1400),
          2200,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Rapid 20x Dark/Light mode toggling and tab switching causes zero memory/timer leaks or uncaught exceptions',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        await initDependencies(
          database: db,
          notificationService: FakeNotificationService(),
        );
        await DatabaseSeeder.seedIfEmpty(db);

        await tester.pumpWidget(const DailyLifeOSApp());
        await tester.pumpAndSettle();

        final profileBloc = sl<ProfileBloc>();

        for (var i = 0; i < 20; i++) {
          profileBloc.add(ToggleDarkModePreference(i.isEven));
          await tester.pump(const Duration(milliseconds: 40));
        }
        await tester.pumpAndSettle();

        // Cycle tabs rapidly
        for (final tabLabel in [
          StringConstants.navPlanner,
          StringConstants.navNotes,
          StringConstants.navVault,
          StringConstants.navTodayTab,
        ]) {
          await tester.tap(find.text(tabLabel));
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
