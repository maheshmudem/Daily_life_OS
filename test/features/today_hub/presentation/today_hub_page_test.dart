import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/features/today_hub/presentation/pages/today_hub_page.dart';
import '../../../core/notifications/fake_notification_service.dart';

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

  testWidgets(
    'Today Hub renders modernized Header, Momentum Ring, and Live Glance',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: TodayHubPage()));
      await tester.pumpAndSettle();

      // 1. Verify User Profile Monogram and Full Date Header
      final now = DateTime.now();
      final expectedDate = DateFormat('EEEE, d MMMM').format(now);
      expect(find.text('A'), findsOneWidget); // Monogram
      expect(find.textContaining(expectedDate), findsOneWidget);
      expect(find.textContaining('Aarav'), findsOneWidget);
      expect(find.byTooltip(StringConstants.playBriefing), findsOneWidget);

      // 2. Verify Hero Banner & Momentum Score Ring
      expect(find.textContaining('%'), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // 3. Verify Live Daily Glance Capsules
      expect(find.text('Habits Done'), findsOneWidget);
      expect(find.text('Tasks Pending'), findsOneWidget);
      expect(find.text('Safe Spend'), findsOneWidget);

      // 4. Verify Safe-to-Spend Meter and Habits Strip
      expect(find.text('Safe-to-Spend Today'), findsOneWidget);
      expect(find.text(StringConstants.habitsAndRoutines), findsOneWidget);
      expect(find.text(StringConstants.timelineFeed), findsOneWidget);
    },
  );

  testWidgets(
    'Today Hub Habits & Micro-Routines supports creating habits, viewing detail analytics, and Evening Wrap-Up',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: TodayHubPage()));
      await tester.pumpAndSettle();

      // 1. Tap 'Add' to open HabitEditorSheet
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      expect(find.text('New Habit or Micro-Routine'), findsOneWidget);

      // Enter habit title & select category 'Mindfulness'
      await tester.enterText(
        find.widgetWithText(
          TextField,
          'e.g., Drink 3L Water, Read 15 mins, Deep Breathing',
        ),
        'Evening Gratitude Journal',
      );
      await tester.tap(find.text('Mindfulness').last);
      await tester.pumpAndSettle();

      // Tap 'Create Habit'
      await tester.tap(find.text('Create Habit'));
      await tester.pumpAndSettle();

      // Verify newly created habit appears in Today Hub
      expect(find.text('Evening Gratitude Journal'), findsOneWidget);

      // 2. Tap the habit to open HabitDetailSheet
      await tester.tap(find.text('Evening Gratitude Journal'));
      await tester.pumpAndSettle();

      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
      expect(find.text('7-Day Rate'), findsOneWidget);
      expect(find.text('30-Day Rate'), findsOneWidget);
      expect(find.text('LAST 7 DAYS (TAP ANY DAY TO TOGGLE)'), findsOneWidget);

      // Close detail sheet
      Navigator.of(tester.element(find.text('Current Streak'))).pop();
      await tester.pumpAndSettle();

      // 3. Tap Evening Wrap-Up card to open EveningWrapUpSheet
      await tester.tap(find.text(StringConstants.eveningWrapUpTitle));
      await tester.pumpAndSettle();

      expect(find.text('Evening Wrap-Up & Daily Review'), findsOneWidget);
      expect(find.text('Complete Wrap-Up & Save Reflection'), findsOneWidget);
    },
  );

  testWidgets(
    'Manage button (ManageHabitsSheet) renders full habit titles without overflow on 320px viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: TodayHubPage()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The habits card no longer has a footer; the section header's tune
      // button is the single entry point to ManageHabitsSheet.
      final manageButton = find.byTooltip('Manage Habits & Routines');
      await tester.ensureVisible(manageButton);
      await tester.pumpAndSettle();
      await tester.tap(manageButton);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      expect(find.text('Habits & Micro-Routines Studio'), findsOneWidget);
      expect(find.text('Analytics & 30d Log'), findsWidgets);
    },
  );
}
