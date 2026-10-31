import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/features/planner/data/datasources/planner_local_datasource.dart';

void main() {
  late AppDatabase db;
  late PlannerLocalDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = PlannerLocalDataSourceImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'PlannerLocalDataSource can insert, query, toggle, and delete items',
    () async {
      const today = '2026-10-21';

      // 1. Initial items should be empty
      final initial = await dataSource.getItemsForDate(today);
      expect(initial, isEmpty);

      // 2. Add item
      await dataSource.addItem(
        title: 'Review PR & Deploy',
        date: today,
        startTime: '10:00 AM',
        category: 'Work',
        colorValue: 0xFF3B82F6,
        iconCodePoint: 12345,
      );

      // 3. Query items
      final items = await dataSource.getItemsForDate(today);
      expect(items.length, 1);
      expect(items.first.title, 'Review PR & Deploy');
      expect(items.first.category, 'Work');
      expect(items.first.isDone, false);

      // 4. Update item
      await dataSource.updateItem(
        id: items.first.id,
        title: 'Review PR & Deploy to Production',
        date: '2026-10-22',
        startTime: '11:00 AM',
        category: 'Important',
        colorValue: 0xFFEF4444,
        iconCodePoint: 54321,
      );
      final updatedList = await dataSource.getItemsForDate('2026-10-22');
      expect(updatedList.length, 1);
      expect(updatedList.first.title, 'Review PR & Deploy to Production');
      expect(updatedList.first.startTime, '11:00 AM');
      expect(updatedList.first.category, 'Important');

      // 5. Toggle item done
      await dataSource.toggleItem(updatedList.first.id);
      final toggled = await dataSource.getItemsForDate('2026-10-22');
      expect(toggled.first.isDone, true);

      // 6. Delete item
      await dataSource.deleteItem(updatedList.first.id);
      final remaining = await dataSource.getItemsForDate('2026-10-22');
      expect(remaining, isEmpty);
    },
  );

  test(
    'PlannerLocalDataSource recurrence evaluation & per-date completion',
    () async {
      // 2026-10-26 is a Monday
      const monday = '2026-10-26';
      // 2026-10-27 is a Tuesday
      const tuesday = '2026-10-27';
      // 2026-10-31 is a Saturday
      const saturday = '2026-10-31';

      // 1. Add Daily reminder with end date
      await dataSource.addItem(
        title: 'Drink 2L Water',
        date: monday,
        startTime: '08:00 AM',
        category: 'Health',
        colorValue: 0xFF10B981,
        iconCodePoint: 100,
        repeatType: 'daily',
        endDate: '2026-10-28',
      );

      // 2. Add Weekdays reminder
      await dataSource.addItem(
        title: 'Standup Sync',
        date: monday,
        startTime: '09:30 AM',
        category: 'Work',
        colorValue: 0xFF6366F1,
        iconCodePoint: 101,
        repeatType: 'weekdays',
      );

      // 3. Add Weekly reminder on Mon & Wed (1,3)
      await dataSource.addItem(
        title: 'Gym Session',
        date: monday,
        startTime: '06:00 PM',
        category: 'Health',
        colorValue: 0xFFF97316,
        iconCodePoint: 102,
        repeatType: 'weekly',
        repeatDays: '1,3',
      );

      // Monday should have all 3 reminders
      final mondayItems = await dataSource.getItemsForDate(monday);
      expect(mondayItems.length, 3);

      // Tuesday should have Daily & Weekdays, but NOT Gym (1,3)
      final tuesdayItems = await dataSource.getItemsForDate(tuesday);
      expect(tuesdayItems.length, 2);
      expect(tuesdayItems.any((i) => i.title == 'Gym Session'), isFalse);

      // Saturday should have NO weekdays reminder
      final saturdayItems = await dataSource.getItemsForDate(saturday);
      expect(saturdayItems.any((i) => i.title == 'Standup Sync'), isFalse);

      // Past end date (2026-10-29 is Thursday > 2026-10-28)
      final thursdayItems = await dataSource.getItemsForDate('2026-10-29');
      expect(thursdayItems.any((i) => i.title == 'Drink 2L Water'), isFalse);

      // 4. Test per-date recurring completion:
      // Mark 'Drink 2L Water' done on Monday
      final waterReminder = mondayItems.firstWhere(
        (i) => i.title == 'Drink 2L Water',
      );
      await dataSource.toggleItem(waterReminder.id, targetDate: monday);

      final mondayRefreshed = await dataSource.getItemsForDate(monday);
      expect(
        mondayRefreshed.firstWhere((i) => i.id == waterReminder.id).isDone,
        isTrue,
      );

      // Tuesday should STILL be uncompleted!
      final tuesdayRefreshed = await dataSource.getItemsForDate(tuesday);
      expect(
        tuesdayRefreshed.firstWhere((i) => i.id == waterReminder.id).isDone,
        isFalse,
      );

      // 5. Test querying 'all' items returns all items without date restriction
      final allItems = await dataSource.getItemsForDate('all');
      expect(allItems.length, 3);
    },
  );

  test(
    'PlannerLocalDataSource clearCompletedItems deletes completed one-off items',
    () async {
      const date = '2026-10-25';

      // 1. One-off completed item
      await dataSource.addItem(
        title: 'Buy Milk',
        date: date,
        category: 'Personal',
        colorValue: 0xFF10B981,
        iconCodePoint: 100,
      );
      // 2. One-off pending item
      await dataSource.addItem(
        title: 'Call Accountant',
        date: date,
        category: 'Finance',
        colorValue: 0xFF3B82F6,
        iconCodePoint: 101,
      );
      // 3. Recurring completed item
      await dataSource.addItem(
        title: 'Morning Yoga',
        date: date,
        category: 'Health',
        colorValue: 0xFFF97316,
        iconCodePoint: 102,
        repeatType: 'daily',
      );

      final allBefore = await dataSource.getItemsForDate('all');
      final buyMilk = allBefore.firstWhere((i) => i.title == 'Buy Milk');
      final morningYoga = allBefore.firstWhere(
        (i) => i.title == 'Morning Yoga',
      );

      // Mark Buy Milk and Morning Yoga as done
      await dataSource.toggleItem(buyMilk.id);
      await dataSource.toggleItem(morningYoga.id, targetDate: date);

      // Call clearCompletedItems
      await dataSource.clearCompletedItems();

      final allAfter = await dataSource.getItemsForDate('all');
      // 'Buy Milk' should be removed
      expect(allAfter.any((i) => i.title == 'Buy Milk'), isFalse);
      // 'Call Accountant' should still be there
      expect(allAfter.any((i) => i.title == 'Call Accountant'), isTrue);
      // 'Morning Yoga' (recurring) should be preserved
      expect(allAfter.any((i) => i.title == 'Morning Yoga'), isTrue);
    },
  );
}
