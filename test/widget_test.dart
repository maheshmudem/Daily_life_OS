import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/main.dart';
import 'package:daily_life_os/core/constants/string_constants.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/di/injection_container.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await initDependencies(database: db);
    await DatabaseSeeder.seedIfEmpty(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('Daily Life OS App 5-Tab Navigation & Today Hub smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DailyLifeOSApp());
    await tester.pumpAndSettle();

    // 1. Verify 5 Navigation Tabs exist in BottomNavigationBar
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Planner'), findsOneWidget);
    expect(find.text('Money'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(find.text('Vault'), findsOneWidget);

    // 2. Verify Persistent Floating Quick-Capture Bar exists
    expect(find.text(StringConstants.holdToSpeak), findsOneWidget);
    expect(find.text(StringConstants.quickType), findsOneWidget);

    // 3. Verify Today Hub Header & Audio Briefing Pill
    expect(find.text(StringConstants.playBriefing), findsOneWidget);
    expect(find.textContaining('Alex'), findsOneWidget);
    expect(find.text(StringConstants.habitsAndRoutines), findsOneWidget);

    // 4. Verify Tab switching works (Tap 'Planner')
    await tester.tap(find.text('Planner'));
    await tester.pumpAndSettle();
    expect(find.text('Pomodoro Focus'), findsOneWidget);
    expect(find.text('Countdowns'), findsOneWidget);

    // 5. Verify Tab switching works (Tap 'Money')
    await tester.tap(find.text('Money'));
    await tester.pumpAndSettle();
    expect(find.text('Subscriptions'), findsOneWidget);

    // 6. Verify Tab switching works (Tap 'Vault')
    await tester.tap(find.text('Vault'));
    await tester.pumpAndSettle();
    expect(find.text('Warranty Locker'), findsOneWidget);
  });
}
