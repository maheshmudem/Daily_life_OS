import '../../../../core/database/app_database.dart';
import '../../domain/entities/habit_entity.dart';

class HabitModel extends HabitEntity {
  const HabitModel({
    required super.id,
    required super.title,
    required super.iconCodePoint,
    required super.colorValue,
    required super.streakDays,
    required super.isDoneToday,
    super.lastCompletedDate,
    required super.createdAt,
    super.description,
    super.category,
    super.scheduleType,
    super.repeatDays,
    super.reminderEnabled,
    super.reminderTime,
    super.isSkippedToday,
    super.completedDates,
    super.skippedDates,
    super.bestStreak,
  });

  factory HabitModel.fromDrift(
    Habit row, {
    String? description,
    String? category,
    String? scheduleType,
    String? repeatDays,
    bool? reminderEnabled,
    String? reminderTime,
    bool? isSkippedToday,
    List<String>? completedDates,
    List<String>? skippedDates,
    int? bestStreak,
  }) {
    final defaultCat = _inferDefaultCategory(row.title);
    final defaultDesc = _inferDefaultDescription(row.title);
    final effectiveCompleted = List<String>.from(completedDates ?? const []);
    final todayIso = DateTime.now().toIso8601String().substring(0, 10);

    if (row.isDoneToday && !effectiveCompleted.contains(todayIso)) {
      effectiveCompleted.add(todayIso);
    } else if (row.lastCompletedDate != null &&
        row.lastCompletedDate!.isNotEmpty &&
        !effectiveCompleted.contains(row.lastCompletedDate!)) {
      effectiveCompleted.add(row.lastCompletedDate!);
    }

    // Seed historical streak dates if completedDates only has 0-1 entries but streakDays > 1
    if (effectiveCompleted.length <= 1 && row.streakDays > 1) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOffset = row.isDoneToday ? 0 : 1;
      for (
        int i = startOffset;
        i < startOffset + row.streakDays && i < 30;
        i++
      ) {
        final d = today.subtract(Duration(days: i));
        final iso =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (!effectiveCompleted.contains(iso)) {
          effectiveCompleted.add(iso);
        }
      }
    }

    final effectiveSkipped = List<String>.from(skippedDates ?? const []);
    final skippedToday = isSkippedToday ?? effectiveSkipped.contains(todayIso);

    final computedBest = (bestStreak ?? 0) > row.streakDays
        ? (bestStreak ?? 0)
        : row.streakDays;

    return HabitModel(
      id: row.id,
      title: row.title,
      iconCodePoint: row.iconCodePoint,
      colorValue: row.colorValue,
      streakDays: row.streakDays,
      isDoneToday: row.isDoneToday,
      lastCompletedDate: row.lastCompletedDate,
      createdAt: row.createdAt,
      description: description ?? defaultDesc,
      category: category ?? defaultCat,
      scheduleType: scheduleType ?? 'daily',
      repeatDays: repeatDays ?? '1,2,3,4,5,6,7',
      reminderEnabled: reminderEnabled ?? false,
      reminderTime: reminderTime,
      isSkippedToday: skippedToday,
      completedDates: effectiveCompleted,
      skippedDates: effectiveSkipped,
      bestStreak: computedBest,
    );
  }

  static String _inferDefaultCategory(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('water') ||
        lower.contains('vitamin') ||
        lower.contains('gym') ||
        lower.contains('workout')) {
      return 'Health';
    }
    if (lower.contains('meditat') ||
        lower.contains('breath') ||
        lower.contains('journal')) {
      return 'Mindfulness';
    }
    if (lower.contains('read') ||
        lower.contains('study') ||
        lower.contains('focus') ||
        lower.contains('code')) {
      return 'Deep Work';
    }
    if (lower.contains('sleep') ||
        lower.contains('evening') ||
        lower.contains('night')) {
      return 'Evening';
    }
    return 'Morning';
  }

  static String _inferDefaultDescription(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('water')) {
      return 'Stay hydrated throughout the day with steady water intake.';
    }
    if (lower.contains('vitamin')) {
      return 'Take daily micronutrients after breakfast.';
    }
    if (lower.contains('read')) {
      return 'Focused non-fiction or deep reading without distractions.';
    }
    if (lower.contains('meditat')) {
      return 'Mindful breathing and mental reset session.';
    }
    return 'Consistent daily micro-routine for long-term momentum.';
  }

  factory HabitModel.fromEntity(HabitEntity entity) {
    return HabitModel(
      id: entity.id,
      title: entity.title,
      iconCodePoint: entity.iconCodePoint,
      colorValue: entity.colorValue,
      streakDays: entity.streakDays,
      isDoneToday: entity.isDoneToday,
      lastCompletedDate: entity.lastCompletedDate,
      createdAt: entity.createdAt,
      description: entity.description,
      category: entity.category,
      scheduleType: entity.scheduleType,
      repeatDays: entity.repeatDays,
      reminderEnabled: entity.reminderEnabled,
      reminderTime: entity.reminderTime,
      isSkippedToday: entity.isSkippedToday,
      completedDates: entity.completedDates,
      skippedDates: entity.skippedDates,
      bestStreak: entity.bestStreak,
    );
  }
}
