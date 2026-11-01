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

    // 4. Verify Safe-to-Spend Meter and Habits Strip
    expect(find.text('Safe-to-Spend Today'), findsOneWidget);
    expect(find.text(StringConstants.habitsAndRoutines), findsOneWidget);
    expect(find.text(StringConstants.timelineFeed), findsOneWidget);
  });
}
