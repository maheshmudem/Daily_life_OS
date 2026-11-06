import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/features/today_hub/data/datasources/today_hub_local_datasource.dart';
import 'package:daily_life_os/features/today_hub/domain/entities/habit_entity.dart';
import 'package:daily_life_os/features/today_hub/domain/entities/timeline_item_entity.dart';

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
    },
  );

  test(
    'TodayHubLocalDataSource supports full CRUD, schedules, reminders, skip, and date tracking for habits and timeline',
    () async {
      final now = DateTime.now().toIso8601String();
      final today = now.substring(0, 10);

      // 1. Create a habit with rich metadata
      final created = await dataSource.addHabit(
        HabitEntity(
          id: 0,
          title: 'Deep Work Sprint',
          iconCodePoint: 0xe3af,
          colorValue: 0xFF6366F1,
          streakDays: 3,
          isDoneToday: false,
          createdAt: now,
          description: '90 minutes of distraction-free coding',
          category: 'Deep Work',
          scheduleType: 'weekdays',
          repeatDays: '1,2,3,4,5',
          reminderEnabled: true,
          reminderTime: '08:30 AM',
          bestStreak: 7,
        ),
      );

      expect(created.id, greaterThan(0));
      expect(created.title, 'Deep Work Sprint');
      expect(created.category, 'Deep Work');
      expect(created.scheduleType, 'weekdays');
      expect(created.scheduleLabel, 'Weekdays');
      expect(created.reminderEnabled, true);
      expect(created.reminderTime, '08:30 AM');
      expect(created.effectiveBestStreak, 7);

      // 2. Skip habit today
      await dataSource.skipHabit(created.id);
      var list = await dataSource.getHabits();
      expect(list.first.isSkippedToday, true);
      expect(list.first.skippedDates.contains(today), true);

      // 3. Toggle habit today -> unskips and marks completed
      await dataSource.toggleHabit(created.id);
      list = await dataSource.getHabits();
      expect(list.first.isDoneToday, true);
      expect(list.first.isSkippedToday, false);
      expect(list.first.completedDates.contains(today), true);

      // 4. Update habit details
      await dataSource.updateHabit(
        list.first.copyWith(
          title: 'Morning Deep Work',
          reminderTime: '07:45 AM',
        ),
      );
      list = await dataSource.getHabits();
      expect(list.first.title, 'Morning Deep Work');
      expect(list.first.reminderTime, '07:45 AM');

      // 5. Delete habit
      await dataSource.deleteHabit(created.id);
      list = await dataSource.getHabits();
      expect(list, isEmpty);

      // 6. Add, update, and delete Timeline Item
      final addedTask = await dataSource.addTimelineItem(
        TimelineItemEntity(
          id: 0,
          time: '02:00 PM',
          title: 'Architecture Review',
          category: 'Time',
          colorValue: 0xFF3B82F6,
          iconCodePoint: 0xe3af,
          isDone: false,
          action: 'Done',
          date: today,
        ),
      );
      expect(addedTask.title, 'Architecture Review');

      await dataSource.updateTimelineItem(
        addedTask.copyWith(title: 'Updated Architecture Review', isDone: true),
      );
      var timeline = await dataSource.getTodayTimeline();
      expect(timeline.first.title, 'Updated Architecture Review');
      expect(timeline.first.isDone, true);

      await dataSource.deleteTimelineItem(addedTask.id);
      timeline = await dataSource.getTodayTimeline();
      expect(timeline, isEmpty);
    },
  );
}
