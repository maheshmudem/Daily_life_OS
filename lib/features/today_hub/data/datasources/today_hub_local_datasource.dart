import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/timeline_item_entity.dart';
import '../models/habit_model.dart';
import '../models/timeline_item_model.dart';

abstract class TodayHubLocalDataSource {
  Future<List<HabitModel>> getHabits();
  Future<HabitModel> addHabit(HabitEntity habit);
  Future<void> updateHabit(HabitEntity habit);
  Future<void> deleteHabit(int id);
  Future<void> toggleHabit(int id);
  Future<void> skipHabit(int id);
  Future<void> toggleHabitDate(int id, String isoDate);

  Future<List<TimelineItemModel>> getTodayTimeline();
  Future<void> toggleTimelineItem(int id);
  Future<TimelineItemModel> addTimelineItem(TimelineItemEntity item);
  Future<void> updateTimelineItem(TimelineItemEntity item);
  Future<void> deleteTimelineItem(int id);
}

class TodayHubLocalDataSourceImpl implements TodayHubLocalDataSource {
  final AppDatabase _db;
  bool _detailsTableInitialized = false;

  TodayHubLocalDataSourceImpl(this._db);

  String get _todayIso => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _ensureDetailsTable() async {
    if (_detailsTableInitialized) return;
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS habit_details (
        habit_id INTEGER PRIMARY KEY NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        category TEXT NOT NULL DEFAULT 'Morning',
        schedule_type TEXT NOT NULL DEFAULT 'daily',
        repeat_days TEXT NOT NULL DEFAULT '1,2,3,4,5,6,7',
        reminder_enabled INTEGER NOT NULL DEFAULT 0,
        reminder_time TEXT,
        completed_dates TEXT NOT NULL DEFAULT '',
        skipped_dates TEXT NOT NULL DEFAULT '',
        best_streak INTEGER NOT NULL DEFAULT 0
      )
    ''');
    _detailsTableInitialized = true;
  }

  List<String> _parseCsvDates(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  String _encodeCsvDates(Iterable<String> dates) {
    final sorted =
        dates.map((s) => s.trim()).where((s) => s.isNotEmpty).toSet().toList()
          ..sort();
    return sorted.join(',');
  }

  Future<Map<int, QueryRow>> _fetchDetailsMap() async {
    await _ensureDetailsTable();
    final rows = await _db.customSelect('SELECT * FROM habit_details').get();
    return {for (final r in rows) r.read<int>('habit_id'): r};
  }

  Future<void> _upsertDetails({
    required int habitId,
    required String description,
    required String category,
    required String scheduleType,
    required String repeatDays,
    required bool reminderEnabled,
    required String? reminderTime,
    required Iterable<String> completedDates,
    required Iterable<String> skippedDates,
    required int bestStreak,
  }) async {
    await _ensureDetailsTable();
    await _db.customStatement(
      '''
      INSERT INTO habit_details (
        habit_id, description, category, schedule_type, repeat_days,
        reminder_enabled, reminder_time, completed_dates, skipped_dates, best_streak
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(habit_id) DO UPDATE SET
        description = excluded.description,
        category = excluded.category,
        schedule_type = excluded.schedule_type,
        repeat_days = excluded.repeat_days,
        reminder_enabled = excluded.reminder_enabled,
        reminder_time = excluded.reminder_time,
        completed_dates = excluded.completed_dates,
        skipped_dates = excluded.skipped_dates,
        best_streak = excluded.best_streak
      ''',
      [
        habitId,
        description,
        category,
        scheduleType,
        repeatDays,
        reminderEnabled ? 1 : 0,
        reminderTime,
        _encodeCsvDates(completedDates),
        _encodeCsvDates(skippedDates),
        bestStreak,
      ],
    );
  }

  @override
  Future<List<HabitModel>> getHabits() async {
    await _ensureDetailsTable();
    final today = _todayIso;
    var rows = await _db.select(_db.habits).get();

    // Daily boundary reset: if a habit was marked done on an earlier date, reset isDoneToday for the new day
    bool didResetAny = false;
    for (final row in rows) {
      if (row.isDoneToday &&
          row.lastCompletedDate != null &&
          row.lastCompletedDate!.isNotEmpty &&
          row.lastCompletedDate != today) {
        await (_db.update(_db.habits)..where((h) => h.id.equals(row.id))).write(
          const HabitsCompanion(isDoneToday: Value(false)),
        );
        didResetAny = true;
      }
    }
    if (didResetAny) {
      rows = await _db.select(_db.habits).get();
    }

    final detailsMap = await _fetchDetailsMap();

    return rows.map((row) {
      final detail = detailsMap[row.id];
      if (detail == null) {
        return HabitModel.fromDrift(row);
      }
      final completed = _parseCsvDates(
        detail.readNullable<String>('completed_dates'),
      );
      final skipped = _parseCsvDates(
        detail.readNullable<String>('skipped_dates'),
      );
      return HabitModel.fromDrift(
        row,
        description: detail.read<String>('description'),
        category: detail.read<String>('category'),
        scheduleType: detail.read<String>('schedule_type'),
        repeatDays: detail.read<String>('repeat_days'),
        reminderEnabled: detail.read<int>('reminder_enabled') == 1,
        reminderTime: detail.readNullable<String>('reminder_time'),
        isSkippedToday: skipped.contains(today) && !row.isDoneToday,
        completedDates: completed,
        skippedDates: skipped,
        bestStreak: detail.read<int>('best_streak'),
      );
    }).toList();
  }

  @override
  Future<HabitModel> addHabit(HabitEntity habit) async {
    await _ensureDetailsTable();
    final nowIso = DateTime.now().toIso8601String();
    final today = _todayIso;

    final insertedId = await _db
        .into(_db.habits)
        .insert(
          HabitsCompanion.insert(
            title: habit.title,
            iconCodePoint: habit.iconCodePoint,
            colorValue: habit.colorValue,
            streakDays: Value(habit.streakDays),
            isDoneToday: Value(habit.isDoneToday),
            lastCompletedDate: Value(
              habit.isDoneToday ? today : habit.lastCompletedDate,
            ),
            createdAt: habit.createdAt.isEmpty ? nowIso : habit.createdAt,
          ),
        );

    final completed = <String>{
      ...habit.completedDates,
      if (habit.isDoneToday) today,
    };
    final skipped = <String>{
      ...habit.skippedDates,
      if (habit.isSkippedToday && !habit.isDoneToday) today,
    };
    final best = habit.bestStreak > habit.streakDays
        ? habit.bestStreak
        : habit.streakDays;

    await _upsertDetails(
      habitId: insertedId,
      description: habit.description,
      category: habit.category,
      scheduleType: habit.scheduleType,
      repeatDays: habit.repeatDays,
      reminderEnabled: habit.reminderEnabled,
      reminderTime: habit.reminderTime,
      completedDates: completed,
      skippedDates: skipped,
      bestStreak: best,
    );

    final all = await getHabits();
    return all.firstWhere((h) => h.id == insertedId);
  }

  @override
  Future<void> updateHabit(HabitEntity habit) async {
    await _ensureDetailsTable();
    final today = _todayIso;

    await (_db.update(_db.habits)..where((h) => h.id.equals(habit.id))).write(
      HabitsCompanion(
        title: Value(habit.title),
        iconCodePoint: Value(habit.iconCodePoint),
        colorValue: Value(habit.colorValue),
        streakDays: Value(habit.streakDays),
        isDoneToday: Value(habit.isDoneToday),
        lastCompletedDate: Value(
          habit.isDoneToday ? today : habit.lastCompletedDate,
        ),
      ),
    );

    final completed = <String>{
      ...habit.completedDates,
      if (habit.isDoneToday) today,
    };
    if (!habit.isDoneToday) {
      completed.remove(today);
    }
    final skipped = <String>{
      ...habit.skippedDates,
      if (habit.isSkippedToday && !habit.isDoneToday) today,
    };
    if (!habit.isSkippedToday || habit.isDoneToday) {
      skipped.remove(today);
    }
    final best = habit.bestStreak > habit.streakDays
        ? habit.bestStreak
        : habit.streakDays;

    await _upsertDetails(
      habitId: habit.id,
      description: habit.description,
      category: habit.category,
      scheduleType: habit.scheduleType,
      repeatDays: habit.repeatDays,
      reminderEnabled: habit.reminderEnabled,
      reminderTime: habit.reminderTime,
      completedDates: completed,
      skippedDates: skipped,
      bestStreak: best,
    );
  }

  @override
  Future<void> deleteHabit(int id) async {
    await _ensureDetailsTable();
    await (_db.delete(_db.habits)..where((h) => h.id.equals(id))).go();
    await _db.customStatement('DELETE FROM habit_details WHERE habit_id = ?', [
      id,
    ]);
  }

  @override
  Future<void> toggleHabit(int id) async {
    await _ensureDetailsTable();
    final habits = await getHabits();
    final idx = habits.indexWhere((h) => h.id == id);
    if (idx < 0) return;
    final current = habits[idx];

    final newDone = !current.isDoneToday;
    final newStreak = newDone
        ? current.streakDays + 1
        : (current.streakDays > 0 ? current.streakDays - 1 : 0);
    final today = _todayIso;

    await (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(
        isDoneToday: Value(newDone),
        streakDays: Value(newStreak),
        lastCompletedDate: Value(newDone ? today : current.lastCompletedDate),
      ),
    );

    final completed = <String>{...current.completedDates};
    final skipped = <String>{...current.skippedDates};
    if (newDone) {
      completed.add(today);
      skipped.remove(today);
    } else {
      completed.remove(today);
    }
    final best = newStreak > current.bestStreak
        ? newStreak
        : current.bestStreak;

    await _upsertDetails(
      habitId: id,
      description: current.description,
      category: current.category,
      scheduleType: current.scheduleType,
      repeatDays: current.repeatDays,
      reminderEnabled: current.reminderEnabled,
      reminderTime: current.reminderTime,
      completedDates: completed,
      skippedDates: skipped,
      bestStreak: best,
    );
  }

  @override
  Future<void> skipHabit(int id) async {
    await _ensureDetailsTable();
    final habits = await getHabits();
    final idx = habits.indexWhere((h) => h.id == id);
    if (idx < 0) return;
    final current = habits[idx];
    final today = _todayIso;

    final nextSkipped = !current.isSkippedToday;
    var nextStreak = current.streakDays;

    if (nextSkipped && current.isDoneToday) {
      nextStreak = current.streakDays > 0 ? current.streakDays - 1 : 0;
      await (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
        HabitsCompanion(
          isDoneToday: const Value(false),
          streakDays: Value(nextStreak),
        ),
      );
    }

    final completed = <String>{...current.completedDates};
    final skipped = <String>{...current.skippedDates};
    if (nextSkipped) {
      skipped.add(today);
      completed.remove(today);
    } else {
      skipped.remove(today);
    }

    await _upsertDetails(
      habitId: id,
      description: current.description,
      category: current.category,
      scheduleType: current.scheduleType,
      repeatDays: current.repeatDays,
      reminderEnabled: current.reminderEnabled,
      reminderTime: current.reminderTime,
      completedDates: completed,
      skippedDates: skipped,
      bestStreak: current.bestStreak,
    );
  }

  @override
  Future<void> toggleHabitDate(int id, String isoDate) async {
    final today = _todayIso;
    if (isoDate == today) {
      await toggleHabit(id);
      return;
    }

    await _ensureDetailsTable();
    final habits = await getHabits();
    final idx = habits.indexWhere((h) => h.id == id);
    if (idx < 0) return;
    final current = habits[idx];

    final completed = <String>{...current.completedDates};
    final skipped = <String>{...current.skippedDates};

    final wasDoneOnDate = completed.contains(isoDate);
    int nextStreak = current.streakDays;
    if (wasDoneOnDate) {
      completed.remove(isoDate);
      if (nextStreak > 0) nextStreak--;
    } else {
      completed.add(isoDate);
      skipped.remove(isoDate);
      nextStreak++;
    }

    await (_db.update(_db.habits)..where((h) => h.id.equals(id))).write(
      HabitsCompanion(streakDays: Value(nextStreak)),
    );

    final best = nextStreak > current.bestStreak
        ? nextStreak
        : current.bestStreak;

    await _upsertDetails(
      habitId: id,
      description: current.description,
      category: current.category,
      scheduleType: current.scheduleType,
      repeatDays: current.repeatDays,
      reminderEnabled: current.reminderEnabled,
      reminderTime: current.reminderTime,
      completedDates: completed,
      skippedDates: skipped,
      bestStreak: best,
    );
  }

  @override
  Future<List<TimelineItemModel>> getTodayTimeline() async {
    final today = _todayIso;
    final rows = await (_db.select(
      _db.timelineItems,
    )..where((t) => t.date.equals(today))).get();
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

  @override
  Future<TimelineItemModel> addTimelineItem(TimelineItemEntity item) async {
    final today = _todayIso;
    final effectiveDate = item.date.isEmpty ? today : item.date;
    final id = await _db
        .into(_db.timelineItems)
        .insert(
          TimelineItemsCompanion.insert(
            time: item.time,
            title: item.title,
            category: item.category,
            colorValue: item.colorValue,
            iconCodePoint: item.iconCodePoint,
            isDone: Value(item.isDone),
            action: item.action,
            date: effectiveDate,
          ),
        );
    final row = await (_db.select(
      _db.timelineItems,
    )..where((t) => t.id.equals(id))).getSingle();
    return TimelineItemModel.fromDrift(row);
  }

  @override
  Future<void> updateTimelineItem(TimelineItemEntity item) async {
    await (_db.update(
      _db.timelineItems,
    )..where((t) => t.id.equals(item.id))).write(
      TimelineItemsCompanion(
        time: Value(item.time),
        title: Value(item.title),
        category: Value(item.category),
        colorValue: Value(item.colorValue),
        iconCodePoint: Value(item.iconCodePoint),
        isDone: Value(item.isDone),
        action: Value(item.action),
        date: Value(item.date),
      ),
    );
  }

  @override
  Future<void> deleteTimelineItem(int id) async {
    await (_db.delete(_db.timelineItems)..where((t) => t.id.equals(id))).go();
  }
}
