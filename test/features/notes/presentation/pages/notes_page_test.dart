import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/core/widgets/app_dropdown_menu.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/features/notes/presentation/pages/notes_page.dart';
import 'package:daily_life_os/features/notes/presentation/widgets/note_card_widget.dart';
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
      home: const NotesPage(),
    );
  }

  group('NotesPage Editorial Redesign & Feature Suite', () {
    testWidgets(
      'supports full composer, scratchpad auto-save, sort/grid toggles, and card overflow menu',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // 1. Header & Overview Strip rendered
        expect(find.text('New Note'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Lists'), findsOneWidget);
        expect(find.text('@Tags'), findsOneWidget);

        // 2. Open Note Editor Sheet & create a new note with checklist
        await tester.tap(find.text('New Note'));
        await tester.pumpAndSettle();

        expect(find.text('Create New Note'), findsOneWidget);
        expect(find.text('Color Accent: '), findsOneWidget);

        final titleFinder = find.widgetWithText(TextField, 'Note Title...');
        final contentFinder = find.widgetWithText(
          TextField,
          'Write your thoughts, checklists, or plans...',
        );
        await tester.enterText(titleFinder, 'Grocery Shopping List');
        await tester.enterText(
          contentFinder,
          '[ ] Milk & Eggs\n[ ] Wholegrain Bread',
        );
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Create Note'));
        await tester.tap(find.text('Create Note'));
        await tester.pumpAndSettle();

        expect(find.text('Create New Note'), findsNothing);
        expect(find.text('Grocery Shopping List'), findsOneWidget);
        expect(find.text('0/2'), findsOneWidget);

        // 3. Inline checklist toggle directly on NoteCardWidget
        await tester.tap(find.text('Milk & Eggs'));
        await tester.pumpAndSettle();
        expect(find.text('1/2'), findsOneWidget);

        // 4. Daily Scratchpad UI, quick-insert tokens, and Save as Note
        expect(
          find.text(StringConstants.dailyScratchpad.toUpperCase()),
          findsOneWidget,
        );
        expect(find.text('Instant auto-save'), findsOneWidget);
        expect(find.text(StringConstants.scratchpadHint), findsOneWidget);

        final scratchpadFinder = find.widgetWithText(
          TextField,
          StringConstants.scratchpadHint,
        );
        await tester.enterText(
          scratchpadFinder,
          'Remember to pick up dry cleaning',
        );
        await tester.pumpAndSettle();

        expect(find.text(StringConstants.save), findsOneWidget);
        await tester.tap(find.text(StringConstants.save));
        await tester.pumpAndSettle();

        expect(find.text('Remember to pick up dry cleaning'), findsWidgets);

        // 5. Sort cycling & Masonry Grid view toggle
        expect(find.byKey(const ValueKey('toggle_notes_sort')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('toggle_notes_view_mode')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('toggle_notes_sort')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('toggle_notes_sort')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('toggle_notes_sort')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('toggle_notes_view_mode')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('toggle_notes_view_mode')));
        await tester.pumpAndSettle();

        // 6. Card Overflow Menu (Edit, Pin, Duplicate, Copy, Planner, Timeline, Expense, Delete)
        await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(AppDropdownItem<String>, StringConstants.edit),
          findsOneWidget,
        );
        final hasUnpin = find.text('Unpin').evaluate().isNotEmpty;
        final pinLabel = hasUnpin ? 'Unpin' : 'Pin to Top';
        expect(find.text(pinLabel), findsOneWidget);
        expect(find.text('Duplicate'), findsOneWidget);
        expect(find.text('Copy Text'), findsOneWidget);
        expect(find.text('Add to Planner'), findsOneWidget);
        expect(find.text(StringConstants.pushToTodayTimeline), findsOneWidget);
        expect(find.text(StringConstants.convertToExpense), findsOneWidget);
        expect(find.text(StringConstants.delete), findsOneWidget);

        // Toggle Pin
        await tester.tap(find.text(pinLabel));
        await tester.pumpAndSettle();

        // Duplicate note
        await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Duplicate'));
        await tester.pumpAndSettle();
        expect(find.textContaining('(Copy)'), findsOneWidget);

        // Delete Note with ConfirmationDialog
        await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text(StringConstants.delete));
        await tester.pumpAndSettle();

        expect(find.text('Delete Note?'), findsOneWidget);
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Delete'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Delete Note?'), findsNothing);
      },
    );

    testWidgets(
      'converts notes to Planner tasks, Today Timeline items, and Money expenses',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Create a note with an embedded amount for smart expense extraction
        await tester.tap(find.text('New Note'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Note Title...'),
          'Team Coffee Run',
        );
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Write your thoughts, checklists, or plans...',
          ),
          'Paid 340 for espresso and croissants',
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Create Note'));
        await tester.tap(find.text('Create Note'));
        await tester.pumpAndSettle();

        final coffeeCard = find.ancestor(
          of: find.text('Team Coffee Run'),
          matching: find.byType(NoteCardWidget),
        );
        expect(coffeeCard, findsOneWidget);

        // 1. Convert to Planner task via footer button
        final beforePlanner = await db.select(db.plannerItems).get();
        await tester.tap(
          find.descendant(of: coffeeCard, matching: find.text('+ Task')),
        );
        await tester.pumpAndSettle();
        final afterPlanner = await db.select(db.plannerItems).get();
        expect(afterPlanner.length, beforePlanner.length + 1);

        // 2. Push to Today's Timeline via dropdown
        final beforeTimeline = await db.select(db.timelineItems).get();
        await tester.tap(
          find.descendant(
            of: coffeeCard,
            matching: find.byIcon(Icons.more_horiz_rounded),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(StringConstants.pushToTodayTimeline));
        await tester.pumpAndSettle();
        final afterTimeline = await db.select(db.timelineItems).get();
        expect(afterTimeline.length, beforeTimeline.length + 1);

        // 3. Convert to Expense via NoteExpenseConverterSheet
        final beforeTx = await db.select(db.transactions).get();
        await tester.tap(
          find.descendant(of: coffeeCard, matching: find.text('Expense')),
        );
        await tester.pumpAndSettle();

        expect(find.text(StringConstants.convertToExpense), findsOneWidget);
        expect(find.widgetWithText(TextField, '340'), findsOneWidget);

        await tester.tap(find.text(StringConstants.save));
        await tester.pumpAndSettle();

        final afterTx = await db.select(db.transactions).get();
        expect(afterTx.length, beforeTx.length + 1);
        expect(afterTx.any((t) => t.amount == 340), isTrue);
      },
    );

    testWidgets(
      'renders cleanly with zero overflow on 320px narrow viewport in List, Grid, and Dark mode',
      (tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Seed a long-title note with checklist and multiple tags
        await db
            .into(db.notes)
            .insert(
              NotesCompanion.insert(
                title:
                    'Comprehensive Quarterly Product & Architecture Roadmap Review Notes',
                content:
                    '[ ] Finalize database schema v3\n[x] Ship editorial Notes redesign\nLong body paragraph verifying narrow viewport text wrapping.',
                colorValue: 0xFF0EA5E9,
                createdAt: DateTime.now().toIso8601String(),
                updatedAt: DateTime.now().toIso8601String(),
              ),
            );

        // Light mode List + Masonry Grid at 320px
        await tester.pumpWidget(buildTestApp(theme: AppTheme.lightTheme));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const ValueKey('toggle_notes_view_mode')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Dark mode at 320px
        await tester.pumpWidget(buildTestApp(theme: AppTheme.darkTheme));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
