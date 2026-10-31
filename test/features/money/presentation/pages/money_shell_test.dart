import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_life_os/config/theme/app_theme.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/core/database/database_seeder.dart';
import 'package:daily_life_os/di/injection_container.dart';
import 'package:daily_life_os/features/navigation/presentation/pages/main_navigation_shell.dart';
import '../../../../core/notifications/fake_notification_service.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    await initDependencies(
      database: db,
      notificationService: FakeNotificationService(),
    );
    await DatabaseSeeder.seedIfEmpty(db);
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'Money tab hides main nav bar, shows Money nav bar (Overview/Activity/Add/Budgets/Insights), and Back restores main nav bar',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationShell(),
        ),
      );
      await tester.pumpAndSettle();

      // Main bottom bar is initially visible
      expect(find.byKey(const ValueKey('main_bottom_nav_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('money_bottom_nav_bar')), findsNothing);

      // Tap 'Money' on the main bottom navigation bar
      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavigationBar),
          matching: find.text('Money'),
        ),
      );
      await tester.pumpAndSettle();

      // Main bottom bar & floating quick capture bar are hidden; Money bottom bar is shown
      expect(find.byKey(const ValueKey('main_bottom_nav_bar')), findsNothing);
      expect(
        find.byKey(const ValueKey('money_bottom_nav_bar')),
        findsOneWidget,
      );
      expect(find.text('SAFE-TO-SPEND TODAY'), findsOneWidget);
      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('Subscriptions'), findsOneWidget);

      // Switch to Budgets tab on Money bottom bar
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('money_bottom_nav_bar')),
          matching: find.text('Budgets'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Budgets'),
        ),
        findsOneWidget,
      );
      expect(find.text('Category Limits'), findsOneWidget);

      // Switch to Insights tab on Money bottom bar
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('money_bottom_nav_bar')),
          matching: find.text('Insights'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Total Assets'), findsOneWidget);

      // Switch to Activity tab on Money bottom bar
      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('money_bottom_nav_bar')),
          matching: find.text('Activity'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('All time'), findsOneWidget);

      // First Back from inner tab ('Activity') returns to 'Overview'
      await tester.tap(find.byTooltip('Back').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('money_bottom_nav_bar')),
        findsOneWidget,
      );

      // Second Back from 'Overview' exits Money mode and restores the main bar
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('main_bottom_nav_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('money_bottom_nav_bar')), findsNothing);
    },
  );
}
