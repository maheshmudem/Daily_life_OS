import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_life_os/main.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/core/widgets/app_dropdown_menu.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'core/notifications/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationService notificationService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
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

  testWidgets('Daily Life OS App 5-Tab Navigation & Today Hub smoke test',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DailyLifeOSApp());
    await tester.pumpAndSettle();

    // 1. Verify 5 Navigation Tabs exist in BottomNavigationBar
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Today')), findsOneWidget);
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Planner')), findsOneWidget);
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Money')), findsOneWidget);
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Notes')), findsOneWidget);
    expect(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Vault')), findsOneWidget);

    // 2. Verify Persistent Floating Quick-Capture Bar exists
    expect(find.text(StringConstants.holdToSpeak), findsOneWidget);
    expect(find.text(StringConstants.quickType), findsOneWidget);

    // 3. Verify Today Hub Header & Audio Briefing Pill
    expect(find.text(StringConstants.playBriefing), findsOneWidget);
    expect(find.textContaining('Alex'), findsOneWidget);
    expect(find.text(StringConstants.habitsAndRoutines), findsOneWidget);

    // 4. Verify Tab switching works (Tap 'Planner')
    await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Planner')));
    await tester.pumpAndSettle();
    expect(find.text('Pomodoro Focus'), findsOneWidget);
    expect(find.text('Countdowns'), findsOneWidget);

    // 4a. Verify Set Reminder Section & Quick Add
    expect(find.text(StringConstants.setReminder.toUpperCase()), findsOneWidget);
    expect(find.text(StringConstants.reminderHint), findsOneWidget);

    // Enter reminder title in the quick set reminder card
    final reminderInputFinder = find.widgetWithText(TextField, StringConstants.reminderHint);
    await tester.enterText(reminderInputFinder, 'Pick up laundry');
    await tester.pumpAndSettle();

    // Tap quick Set Reminder button
    final quickSetButton = find.descendant(
      of: find.byType(FilledButton),
      matching: find.text(StringConstants.setReminder),
    );
    await tester.tap(quickSetButton.first);
    await tester.pumpAndSettle();

    // Verify reminder appears in list
    expect(find.text('Pick up laundry'), findsOneWidget);

    // 4b. Verify 'Full Options' opens Set Reminder Modal Sheet
    final fullOptionsFinder = find.text('Full Options');
    expect(fullOptionsFinder, findsOneWidget);
    await tester.tap(fullOptionsFinder);
    await tester.pumpAndSettle();

    // Verify Modal sheet opened
    expect(find.text('Schedule:'), findsOneWidget);
    expect(find.text('Category:'), findsOneWidget);

    final sheetTitleFinder = find.widgetWithText(TextField, StringConstants.reminderHint);
    await tester.enterText(sheetTitleFinder.last, 'Team Standup meeting');
    await tester.pumpAndSettle();

    // Tap submit button in sheet
    final sheetSubmitBtn = find.descendant(
      of: find.byType(FilledButton),
      matching: find.text(StringConstants.setReminder),
    );
    await tester.tap(sheetSubmitBtn.last);
    await tester.pumpAndSettle();

    // Verify reminder from sheet appears in list
    expect(find.text('Team Standup meeting'), findsOneWidget);

    // 5. Verify Tab switching works (Tap 'Money')
    await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Money')));
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions'), findsOneWidget);

    // 6. Verify Tab switching works (Tap 'Vault')
    await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Vault')));
    await tester.pumpAndSettle();
    expect(find.text('Warranty Locker'), findsOneWidget);

    // 7. Verify Notes Tab and tapping New Note
    await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text('Notes')));
    await tester.pumpAndSettle();
    expect(find.text('New Note'), findsWidgets);

    // Tap the FAB 'New Note'
    await tester.tap(find.text('New Note').first);
    await tester.pumpAndSettle();

    // Verify Note Editor sheet opened cleanly
    expect(find.text('Create New Note'), findsOneWidget);
    expect(find.text('Color Accent: '), findsOneWidget);

    // Enter title & content
    final titleFinder = find.widgetWithText(TextField, 'Note Title...');
    final contentFinder = find.widgetWithText(TextField, 'Write your thoughts, checklists, or plans...');
    await tester.enterText(titleFinder, 'Grocery Shopping List');
    await tester.enterText(contentFinder, 'Milk, Eggs, Bread, Butter');
    await tester.pumpAndSettle();

    // Tap 'Create Note'
    await tester.ensureVisible(find.text('Create Note'));
    await tester.tap(find.text('Create Note'));
    await tester.pumpAndSettle();

    expect(find.text('Create New Note'), findsNothing);
    expect(find.text('Grocery Shopping List'), findsOneWidget);

    // 8. Verify Daily Scratchpad UI & Tokens
    expect(find.text(StringConstants.dailyScratchpad.toUpperCase()), findsOneWidget);
    expect(find.text(StringConstants.scratchpadHint), findsOneWidget);

    // Type into Scratchpad and Save as Note
    final scratchpadFinder = find.widgetWithText(TextField, StringConstants.scratchpadHint);
    await tester.enterText(scratchpadFinder, 'Remember to pick up dry cleaning');
    await tester.pumpAndSettle();

    // Verify Save button appeared
    expect(find.text(StringConstants.save), findsOneWidget);
    await tester.tap(find.text(StringConstants.save));
    await tester.pumpAndSettle();

    // Verify new note was created from scratchpad
    expect(find.text('Remember to pick up dry cleaning'), findsWidgets);

    // 9. Verify Note Card Dropdown Popup Menu
    final moreButtonFinder = find.byIcon(Icons.more_horiz_rounded).first;
    expect(moreButtonFinder, findsWidgets);

    // Tap more button to open dropdown
    await tester.tap(moreButtonFinder);
    await tester.pumpAndSettle();

    // Verify all dropdown menu items are present
    expect(
        find.widgetWithText(AppDropdownItem<String>, StringConstants.edit),
        findsOneWidget);
    final hasUnpin = find.text('Unpin').evaluate().isNotEmpty;
    final pinLabel = hasUnpin ? 'Unpin' : 'Pin to Top';
    expect(find.text(pinLabel), findsOneWidget);
    expect(find.text('Copy Text'), findsOneWidget);
    expect(find.text('Add to Planner'), findsOneWidget);
    expect(find.text(StringConstants.delete), findsOneWidget);

    // Tap pin toggle action
    await tester.tap(find.text(pinLabel));
    await tester.pumpAndSettle();

    // Open dropdown again and test Delete Note
    await tester.tap(find.byIcon(Icons.more_horiz_rounded).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text(StringConstants.delete));
    await tester.pumpAndSettle();

    // Verify Confirmation Dialog popped up
    expect(find.text('Delete Note?'), findsOneWidget);
    expect(find.text('Delete'), findsWidgets);

    // Confirm deletion
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete')));
    await tester.pumpAndSettle();

    // Note is cleanly deleted
    expect(find.text('Delete Note?'), findsNothing);
  });

  testWidgets(
      'Planner Pomodoro Focus & Countdowns rich interactive features test',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DailyLifeOSApp());
    await tester.pumpAndSettle();

    // 1. Switch to Planner tab
    await tester.tap(find.descendant(
        of: find.byType(BottomNavigationBar), matching: find.text('Planner')));
    await tester.pumpAndSettle();

    // 2. Tap 'Pomodoro Focus' tab
    await tester.tap(find.text('Pomodoro Focus'));
    await tester.pumpAndSettle();

    // Verify Pomodoro Elements
    expect(find.text('Start Focus'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);
    expect(find.textContaining('Focusing on:'), findsOneWidget);
    expect(find.text('Focus Presets & Custom Time'), findsOneWidget);
    expect(find.text('Focus Ambience & Sounds'), findsOneWidget);
    expect(find.text('Daily Focus Activity'), findsOneWidget);

    // Test preset chip '45m Deep Work'
    await tester.tap(find.text('45m Deep Work'));
    await tester.pumpAndSettle();
    expect(find.text('45:00'), findsOneWidget);

    // Test Start Focus / Pause
    await tester.tap(find.text('Start Focus'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Pause'), findsOneWidget);

    // Test Pause Focus
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Start Focus'), findsOneWidget);

    // Test Mode Switch to 'Break'
    await tester.tap(find.textContaining('Break (5m)'));
    await tester.pumpAndSettle();
    expect(find.text('05:00'), findsOneWidget);

    // 3. Tap 'Countdowns' tab
    await tester.tap(find.text('Countdowns'));
    await tester.pumpAndSettle();

    // Verify Countdowns Elements
    expect(find.text('Important Countdowns'), findsOneWidget);
    expect(find.text('Add Event'), findsOneWidget);
    expect(find.text("Sarah's 28th Birthday"), findsOneWidget);
    expect(find.text('Car Insurance Renewal'), findsOneWidget);

    // Test Filter Chip 'Renewal'
    await tester.tap(find.widgetWithText(FilterChip, 'Renewal'));
    await tester.pumpAndSettle();
    expect(find.text('Car Insurance Renewal'), findsOneWidget);
    expect(find.text("Sarah's 28th Birthday"), findsNothing);

    // Reset Filter to 'All'
    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();
    expect(find.text("Sarah's 28th Birthday"), findsOneWidget);

    // Test 'Add Event' modal sheet
    await tester.tap(find.text('Add Event'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Create Countdown'), findsOneWidget);
    expect(find.text('Target Event Date:'), findsOneWidget);

    // Enter title & notes
    final titleFinder = find.widgetWithText(
        TextField, 'e.g., Mom\'s 50th Birthday, Trip to Paris');
    await tester.enterText(titleFinder, 'Graduation Ceremony');

    // Tap 'Create Countdown'
    await tester.tap(find.widgetWithText(FilledButton, 'Create Countdown'));
    await tester.pumpAndSettle();

    // Verify newly added countdown appears in list
    expect(find.text('Graduation Ceremony'), findsOneWidget);

    // Verify local notification was scheduled for the newly added countdown
    expect(
      notificationService.scheduledNotifications
          .any((n) => n.title.contains('Graduation Ceremony')),
      isTrue,
    );
  });
}
