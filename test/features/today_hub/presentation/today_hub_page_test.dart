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

  testWidgets('Today Hub renders modernized Header, Momentum Ring, and Live Glance',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TodayHubPage(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify User Profile Monogram and Full Date Header
    final now = DateTime.now();
    final expectedDate = DateFormat('EEEE, d MMMM').format(now).toUpperCase();
    expect(find.text('A'), findsOneWidget); // Monogram
    expect(find.textContaining(expectedDate), findsOneWidget);
    expect(find.textContaining('Aarav'), findsOneWidget);
    expect(find.text(StringConstants.playBriefing), findsOneWidget);

    // 2. Verify Hero Banner & Momentum Score Ring
    expect(find.text('Daily Life OS Active'), findsOneWidget);
    expect(find.text('Time, Money & Mind in Sync'), findsOneWidget);
    expect(find.text('MOMENTUM'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    // 3. Verify Live Daily Glance Capsules
    expect(find.text('Habits Done'), findsOneWidget);
    expect(find.text('Tasks Pending'), findsOneWidget);
    expect(find.text('Safe Spend'), findsOneWidget);

    // 4. Verify Safe-to-Spend Meter and Habits Strip with Add Habit entry point
    expect(find.text('Safe-to-Spend Today'), findsOneWidget);
    expect(find.text(StringConstants.habitsAndRoutines), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Add Habit'), findsOneWidget);
    expect(find.text(StringConstants.timelineFeed), findsOneWidget);
  });

  testWidgets('Tapping Add Habit header button opens HabitFormSheet in create mode',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TodayHubPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on the "+ Add" header chip
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Verify HabitFormSheet opens with create mode elements
    expect(find.text('Add New Habit'), findsOneWidget);
    expect(find.text('Create a micro-routine for daily momentum'), findsOneWidget);
    expect(find.text('QUICK TEMPLATES'), findsOneWidget);
    expect(find.text('HABIT NAME'), findsOneWidget);
    expect(find.text('CHOOSE ICON'), findsOneWidget);
    expect(find.text('COLOR ACCENT'), findsOneWidget);
    expect(find.text('Create Habit'), findsOneWidget);
  });

  testWidgets('Long pressing a habit bubble opens HabitFormSheet in edit/delete mode',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: TodayHubPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Find first habit bubble (seeded: "Drink 3L Water") and long press
    final habitBubble = find.text('Drink 3L Water');
    expect(habitBubble, findsOneWidget);

    await tester.longPress(habitBubble);
    await tester.pumpAndSettle();

    // Verify Edit sheet opens
    expect(find.text('Edit Habit'), findsOneWidget);
    expect(find.text('Adjust streak, icon, or remove habit'), findsOneWidget);
    expect(find.text('Current Streak'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });
}
