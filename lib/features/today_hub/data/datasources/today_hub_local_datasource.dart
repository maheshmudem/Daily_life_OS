import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/app_database.dart';
import '../../domain/entities/habit_entity.dart';
import '../models/habit_model.dart';
import '../models/timeline_item_model.dart';

abstract class TodayHubLocalDataSource {
  Future<List<HabitModel>> getHabits();
  Future<void> toggleHabit(int id);
  Future<void> addHabit(HabitEntity habit);
  Future<void> updateHabit(HabitEntity habit);
  Future<void> deleteHabit(int id);
  Future<List<TimelineItemModel>> getTodayTimeline();
  Future<void> toggleTimelineItem(int id);
}

class TodayHubLocalDataSourceImpl implements TodayHubLocalDataSource {
  final AppDatabase _db;

  TodayHubLocalDataSourceImpl(this._db);

  @override
  Future<List<HabitModel>> getHabits() async {
    final rows = await _db.select(_db.habits).get();
    return rows.map(HabitModel.fromDrift).toList();
  }

  @override
  Future<void> toggleHabit(int id) async {
    final habit = await (_db.select(
      _db.habits,
    )..where((t) => t.id.equals(id))).getSingle();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final wasDone = habit.isDoneToday;
    final newStreak = wasDone
        ? (habit.streakDays > 0 ? habit.streakDays - 1 : 0)
        : habit.streakDays + 1;

    await (_db.update(_db.habits)..where((t) => t.id.equals(id))).write(
      HabitsCompanion(
        isDoneToday: Value(!wasDone),
        streakDays: Value(newStreak),
        lastCompletedDate: Value(wasDone ? null : today),
      ),
    );
  }

  @override
  Future<void> addHabit(HabitEntity habit) async {
    final now = DateTime.now().toIso8601String();
    await _db.into(_db.habits).insert(
      HabitsCompanion.insert(
        title: habit.title,
        iconCodePoint: habit.iconCodePoint,
        colorValue: habit.colorValue,
        streakDays: Value(habit.streakDays),
        isDoneToday: Value(habit.isDoneToday),
        lastCompletedDate: Value(habit.lastCompletedDate),
        createdAt: habit.createdAt.isEmpty ? now : habit.createdAt,
      ),
    );
  }

  @override
  Future<void> updateHabit(HabitEntity habit) async {
    await (_db.update(_db.habits)..where((t) => t.id.equals(habit.id))).write(
      HabitsCompanion(
        title: Value(habit.title),
        iconCodePoint: Value(habit.iconCodePoint),
        colorValue: Value(habit.colorValue),
        streakDays: Value(habit.streakDays),
        isDoneToday: Value(habit.isDoneToday),
        lastCompletedDate: Value(habit.lastCompletedDate),
      ),
    );
  }

  @override
  Future<void> deleteHabit(int id) async {
    await (_db.delete(_db.habits)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<List<TimelineItemModel>> getTodayTimeline() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows =
        await (_db.select(_db.timelineItems)
              ..where((t) => t.date.equals(today))
              ..orderBy([(t) => OrderingTerm.asc(t.time)]))
            .get();
    return rows.map(TimelineItemModel.fromDrift).toList();
  }

  @override
  Future<void> toggleTimelineItem(int id) async {
    final item = await (_db.select(
      _db.timelineItems,
    )..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(_db.timelineItems)..where((t) => t.id.equals(id))).write(
      TimelineItemsCompanion(isDone: Value(!item.isDone)),
    );
  }
}
