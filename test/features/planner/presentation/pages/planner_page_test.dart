import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/features/planner/presentation/pages/planner_page.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/planner_hero_card.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/planner_item_card.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/planner_matrix_view.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/planner_timeline_view.dart';
import 'package:daily_life_os/features/planner/presentation/widgets/planner_week_strip.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/notifications/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationService notificationService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    notificationService = FakeNotificationService();
    await initDependencies(
      database: db,
      notificationService: notificationService,
    );
    await DatabaseSeeder.seedIfEmpty(db);
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp({ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: const PlannerPage(),
    );
  }

  group('PlannerPage Command Deck, Multi-Lens Workspace & Feature Suite', () {
    testWidgets(
      'supports Command Hero, 7-day week horizon filtering, date-targeted quick add, snooze sheet, and 1-tap Focus Sprint bridge',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // 1. Unified Command Hero & Embedded Glass Week Strip rendered
        expect(find.byType(PlannerHeroCard), findsOneWidget);
        expect(find.byType(PlannerWeekStrip), findsOneWidget);
        expect(
          find.byKey(const ValueKey('planner_all_dates_chip')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('planner_metric_active')),
          findsOneWidget,
        );

        // 2. Select today's cell on the Week Strip, verify active filter, then reset via All Dates
        final now = DateTime.now();
        final todayIso = PlannerWeekStrip.toIsoDate(now);
        await tester.tap(find.byKey(ValueKey('planner_day_$todayIso')));
        await tester.pumpAndSettle();

        // Quick-add a task while today's date is selected
        await tester.enterText(
          find.widgetWithText(TextField, StringConstants.reminderHint),
          'Prepare Architecture Deck',
        );
        await tester.tap(
          find
              .descendant(
                of: find.byType(FilledButton),
                matching: find.text(StringConstants.setReminder),
              )
              .first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Prepare Architecture Deck'), findsOneWidget);

        // Reset back to All Dates
        await tester.tap(find.byKey(const ValueKey('planner_all_dates_chip')));
        await tester.pumpAndSettle();
        expect(find.text('Prepare Architecture Deck'), findsOneWidget);

        // 3. Test Snooze Sheet on the newly created task
        final targetCard = find.ancestor(
          of: find.text('Prepare Architecture Deck'),
          matching: find.byType(PlannerItemCard),
        );
        await tester.tap(
          find.descendant(of: targetCard, matching: find.text('Snooze +15m')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Snooze Reminder'), findsOneWidget);
        expect(find.text('15 Minutes'), findsOneWidget);
        expect(find.text('1 Hour'), findsOneWidget);
        expect(find.text('Tomorrow Morning'), findsOneWidget);

        await tester.tap(find.text('15 Minutes'));
        await tester.pumpAndSettle();
        expect(find.text('Snooze Reminder'), findsNothing);

        // 4. Test 1-tap Start Focus Sprint bridge -> switches to Pomodoro Focus tab with task linked
        await tester.tap(
          find.descendant(
            of: targetCard,
            matching: find.byTooltip('Start Focus Sprint'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Start Focus'), findsOneWidget);
        expect(find.textContaining('Prepare Architecture Deck'), findsWidgets);
      },
    );

    testWidgets(
      'supports 3-mode Workspace Switcher (Agenda, Day Flow Timeline with live NOW needle, and 2x2 Priority Matrix)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Switch to Day Flow Timeline view
        await tester.tap(find.byKey(const ValueKey('planner_view_timeline')));
        await tester.pumpAndSettle();

        expect(find.byType(PlannerTimelineView), findsOneWidget);
        expect(find.text('Day-Flow Rhythm'), findsOneWidget);
        expect(find.text('NOW'), findsOneWidget);

        // Switch to 2x2 Eisenhower Priority Matrix view
        await tester.tap(find.byKey(const ValueKey('planner_view_matrix')));
        await tester.pumpAndSettle();

        expect(find.byType(PlannerMatrixView), findsOneWidget);
        expect(find.text('Do First'), findsOneWidget);
        expect(find.text('Schedule'), findsOneWidget);
        expect(find.text('Focus Plan'), findsOneWidget);
        expect(find.text('Light / Later'), findsOneWidget);

        // Tap '+' inside the Do First (urgent) quadrant to add a task directly
        await tester.tap(find.byKey(const ValueKey('matrix_add_urgent')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, StringConstants.reminderHint).last,
          'Production Hotfix Review',
        );
        final submitBtn = find
            .descendant(
              of: find.byType(FilledButton),
              matching: find.text(StringConstants.setReminder),
            )
            .last;
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        expect(find.text('Production Hotfix Review'), findsOneWidget);

        // Switch back to Agenda view
        await tester.tap(find.byKey(const ValueKey('planner_view_agenda')));
        await tester.pumpAndSettle();
        expect(find.text('Production Hotfix Review'), findsOneWidget);
      },
    );

    testWidgets(
      'supports inline subtask checklist progress and Digital Milestone CountdownSpotlightCard',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // 1. Open Full options sheet and create a task with 2 subtasks
        await tester.tap(find.text('Full options'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, StringConstants.reminderHint).last,
          'Quarterly Tax Filing',
        );

        final subtaskInput = find.widgetWithText(TextField, 'Add a subtask...');
        await tester.ensureVisible(subtaskInput);
        await tester.enterText(subtaskInput, 'Download bank statements');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        await tester.enterText(subtaskInput, 'Verify GST invoices');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        final submitBtn = find
            .descendant(
              of: find.byType(FilledButton),
              matching: find.text(StringConstants.setReminder),
            )
            .last;
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Subtasks auto-expand when <= 3 items
        expect(find.text('Quarterly Tax Filing'), findsOneWidget);
        expect(find.text('0/2'), findsWidgets);
        expect(find.text('Download bank statements'), findsOneWidget);

        // Toggle subtask inline on PlannerItemCard
        await tester.tap(find.text('Download bank statements'));
        await tester.pumpAndSettle();
        expect(find.text('1/2'), findsWidgets);

        // 2. Switch to Countdowns tab & verify Digital Milestone CountdownSpotlightCard
        await tester.tap(find.text('Countdowns'));
        await tester.pumpAndSettle();

        expect(find.text('Upcoming'), findsOneWidget);
        expect(find.text('Next 30d'), findsOneWidget);
        expect(find.text('Alerts On'), findsOneWidget);
        expect(find.text('Next In'), findsOneWidget);
        expect(find.text('DAYS'), findsOneWidget);
        expect(find.text('HRS'), findsOneWidget);
        expect(find.text('MIN'), findsOneWidget);
        expect(
          find.textContaining("Next Up · Sarah's 28th Birthday"),
          findsOneWidget,
        );
      },
    );

    for (final entry in [
      ('Light', AppTheme.lightTheme),
      ('Dark', AppTheme.darkTheme),
    ]) {
      testWidgets(
        'renders zero layout overflow on 320px narrow viewport across all 3 tabs and all 3 view lenses (${entry.$1}) + 1280px desktop',
        (tester) async {
          // 1. Ultra-narrow 320px phone viewport
          tester.view.physicalSize = const Size(320, 640);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(buildTestApp(theme: entry.$2));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Verify Day Flow Timeline at 320px
          final timelineBtn = find.byKey(
            const ValueKey('planner_view_timeline'),
          );
          await tester.ensureVisible(timelineBtn);
          await tester.pumpAndSettle();
          await tester.tap(timelineBtn);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Verify Priority Matrix at 320px
          final matrixBtn = find.byKey(const ValueKey('planner_view_matrix'));
          await tester.ensureVisible(matrixBtn);
          await tester.pumpAndSettle();
          await tester.tap(matrixBtn);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Switch back to Agenda
          final agendaBtn = find.byKey(const ValueKey('planner_view_agenda'));
          await tester.ensureVisible(agendaBtn);
          await tester.pumpAndSettle();
          await tester.tap(agendaBtn);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Switch to Pomodoro Focus tab at 320px
          await tester.tap(find.text('Pomodoro Focus'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // Switch to Countdowns tab at 320px
          await tester.tap(find.text('Countdowns'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          // 2. Wide 1280px 2-column desktop viewport across all 3 tabs + Matrix
          tester.view.physicalSize = const Size(1280, 900);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Pomodoro Focus'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Reminders'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.tap(find.byKey(const ValueKey('planner_view_matrix')));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
