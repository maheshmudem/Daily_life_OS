import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/features/today_hub/data/datasources/today_hub_local_datasource.dart';
import 'package:daily_life_os/features/today_hub/domain/entities/habit_entity.dart';

void main() {
  late AppDatabase db;
  late TodayHubLocalDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = TodayHubLocalDataSourceImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'TodayHubLocalDataSource can get and toggle habits and timeline items',
    () async {
      final now = DateTime.now().toIso8601String();
      final today = now.substring(0, 10);

      // 1. Insert a habit
      final habitId = await db
          .into(db.habits)
          .insert(
            HabitsCompanion.insert(
              title: 'Drink 3L Water',
              iconCodePoint: 123,
              colorValue: 0xFF3B82F6,
              streakDays: const Value(5),
              isDoneToday: const Value(false),
              createdAt: now,
            ),
          );

      // 2. Fetch habits
      final habits = await dataSource.getHabits();
      expect(habits.length, 1);
      expect(habits.first.title, 'Drink 3L Water');
      expect(habits.first.isDoneToday, false);
      expect(habits.first.streakDays, 5);

      // 3. Toggle habit -> streak should increment to 6 and isDoneToday true
      await dataSource.toggleHabit(habitId);
      final toggledHabits = await dataSource.getHabits();
      expect(toggledHabits.first.isDoneToday, true);
      expect(toggledHabits.first.streakDays, 6);

      // 4. Insert a timeline item
      final timelineId = await db
          .into(db.timelineItems)
          .insert(
            TimelineItemsCompanion.insert(
              time: '09:00 AM',
              title: 'Daily Standup',
              category: 'Work',
              colorValue: 0xFF10B981,
              iconCodePoint: 456,
              isDone: const Value(false),
              action: 'Done',
              date: today,
            ),
          );

      // 5. Fetch today timeline items
      final timeline = await dataSource.getTodayTimeline();
      expect(timeline.length, 1);
      expect(timeline.first.title, 'Daily Standup');
      expect(timeline.first.isDone, false);

      // 6. Toggle timeline item
      await dataSource.toggleTimelineItem(timelineId);
      final toggledTimeline = await dataSource.getTodayTimeline();
      expect(toggledTimeline.first.isDone, true);

      // 7. Test addHabit
      await dataSource.addHabit(
        HabitEntity(
          id: 0,
          title: 'Morning Yoga',
          iconCodePoint: 789,
          colorValue: 0xFF14B8A6,
          streakDays: 0,
          isDoneToday: false,
          createdAt: now,
        ),
      );
      var allHabits = await dataSource.getHabits();
      expect(allHabits.length, 2);
      final addedHabit = allHabits.firstWhere((h) => h.title == 'Morning Yoga');
      expect(addedHabit.streakDays, 0);

      // 8. Test updateHabit
      await dataSource.updateHabit(
        addedHabit.copyWith(title: 'Power Yoga', streakDays: 7),
      );
      allHabits = await dataSource.getHabits();
      final updatedHabit = allHabits.firstWhere((h) => h.id == addedHabit.id);
      expect(updatedHabit.title, 'Power Yoga');
      expect(updatedHabit.streakDays, 7);

      // 9. Test deleteHabit
      await dataSource.deleteHabit(addedHabit.id);
      allHabits = await dataSource.getHabits();
      expect(allHabits.length, 1);
      expect(allHabits.any((h) => h.id == addedHabit.id), false);
    },
  );
}
