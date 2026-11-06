import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class HabitEntity extends Equatable {
  final int id;
  final String title;
  final int iconCodePoint;
  final int colorValue;
  final int streakDays;
  final bool isDoneToday;
  final String? lastCompletedDate;
  final String createdAt;

  // Extended Habit & Micro-Routine fields
  final String description;
  final String category;
  final String scheduleType; // 'daily', 'weekdays', 'weekends', 'custom'
  final String repeatDays; // e.g. '1,2,3,4,5,6,7' (1 = Mon .. 7 = Sun)
  final bool reminderEnabled;
  final String? reminderTime; // e.g. '07:30 AM'
  final bool isSkippedToday;
  final List<String> completedDates; // ISO 'yyyy-MM-dd'
  final List<String> skippedDates; // ISO 'yyyy-MM-dd'
  final int bestStreak;

  const HabitEntity({
    required this.id,
    required this.title,
    required this.iconCodePoint,
    required this.colorValue,
    required this.streakDays,
    required this.isDoneToday,
    this.lastCompletedDate,
    required this.createdAt,
    this.description = '',
    this.category = 'Morning',
    this.scheduleType = 'daily',
    this.repeatDays = '1,2,3,4,5,6,7',
    this.reminderEnabled = false,
    this.reminderTime,
    this.isSkippedToday = false,
    this.completedDates = const [],
    this.skippedDates = const [],
    this.bestStreak = 0,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  int get effectiveBestStreak =>
      bestStreak > streakDays ? bestStreak : streakDays;

  Set<int> get scheduledWeekdays {
    switch (scheduleType) {
      case 'weekdays':
        return const {1, 2, 3, 4, 5};
      case 'weekends':
        return const {6, 7};
      case 'custom':
        final parsed = repeatDays
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .where((d) => d >= 1 && d <= 7)
            .toSet();
        return parsed.isEmpty ? const {1, 2, 3, 4, 5, 6, 7} : parsed;
      case 'daily':
      default:
        return const {1, 2, 3, 4, 5, 6, 7};
    }
  }

  bool isScheduledForDay(DateTime day) {
    return scheduledWeekdays.contains(day.weekday);
  }

  String get scheduleLabel {
    switch (scheduleType) {
      case 'weekdays':
        return 'Weekdays';
      case 'weekends':
        return 'Weekends';
      case 'custom':
        final set = scheduledWeekdays;
        final days = set.toList()..sort();
        if (days.length == 7) return 'Every day';
        if (days.length == 5 && set.containsAll(const [1, 2, 3, 4, 5])) {
          return 'Weekdays';
        }
        if (days.length == 2 && set.containsAll(const [6, 7])) {
          return 'Weekends';
        }
        const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days.map((d) => names[d - 1]).join(', ');
      case 'daily':
      default:
        return 'Every day';
    }
  }

  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool isCompletedOn(DateTime day) {
    final iso = _isoDate(day);
    final todayIso = _isoDate(DateTime.now());
    if (iso == todayIso && isDoneToday) return true;
    return completedDates.contains(iso);
  }

  bool isSkippedOn(DateTime day) {
    final iso = _isoDate(day);
    final todayIso = _isoDate(DateTime.now());
    if (iso == todayIso && isSkippedToday) return true;
    return skippedDates.contains(iso);
  }

  /// Completion rate over the last [days] days (0.0 to 1.0).
  double completionRateForDays(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int scheduledCount = 0;
    int completedCount = 0;

    for (int i = 0; i < days; i++) {
      final d = today.subtract(Duration(days: i));
      final completed = isCompletedOn(d);
      final skipped = isSkippedOn(d);
      if (completed) {
        completedCount++;
        scheduledCount++;
      } else if (!skipped && isScheduledForDay(d)) {
        scheduledCount++;
      }
    }
    if (scheduledCount == 0) return isDoneToday ? 1.0 : 0.0;
    return (completedCount / scheduledCount).clamp(0.0, 1.0);
  }

  double get weeklyCompletionRate => completionRateForDays(7);
  double get monthlyCompletionRate => completionRateForDays(30);

  HabitEntity copyWith({
    int? id,
    String? title,
    int? iconCodePoint,
    int? colorValue,
    int? streakDays,
    bool? isDoneToday,
    String? lastCompletedDate,
    String? createdAt,
    String? description,
    String? category,
    String? scheduleType,
    String? repeatDays,
    bool? reminderEnabled,
    String? reminderTime,
    bool clearReminderTime = false,
    bool? isSkippedToday,
    List<String>? completedDates,
    List<String>? skippedDates,
    int? bestStreak,
  }) {
    return HabitEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      streakDays: streakDays ?? this.streakDays,
      isDoneToday: isDoneToday ?? this.isDoneToday,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduleType: scheduleType ?? this.scheduleType,
      repeatDays: repeatDays ?? this.repeatDays,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: clearReminderTime
          ? null
          : (reminderTime ?? this.reminderTime),
      isSkippedToday: isSkippedToday ?? this.isSkippedToday,
      completedDates: completedDates ?? this.completedDates,
      skippedDates: skippedDates ?? this.skippedDates,
      bestStreak: bestStreak ?? this.bestStreak,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    iconCodePoint,
    colorValue,
    streakDays,
    isDoneToday,
    lastCompletedDate,
    createdAt,
    description,
    category,
    scheduleType,
    repeatDays,
    reminderEnabled,
    reminderTime,
    isSkippedToday,
    completedDates,
    skippedDates,
    bestStreak,
  ];
}
