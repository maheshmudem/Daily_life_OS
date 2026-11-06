import 'package:equatable/equatable.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/timeline_item_entity.dart';

abstract class TodayHubState extends Equatable {
  const TodayHubState();
  @override
  List<Object?> get props => [];
}

class TodayHubInitial extends TodayHubState {}

class TodayHubLoading extends TodayHubState {}

class TodayHubLoaded extends TodayHubState {
  final List<HabitEntity> habits;
  final List<TimelineItemEntity> timelineItems;
  final String selectedHabitCategory;

  const TodayHubLoaded({
    required this.habits,
    required this.timelineItems,
    this.selectedHabitCategory = 'All',
  });

  int get completedHabits => habits.where((h) => h.isDoneToday).length;

  int get skippedHabits =>
      habits.where((h) => h.isSkippedToday && !h.isDoneToday).length;

  int get longestActiveStreak => habits.isEmpty
      ? 0
      : habits.map((h) => h.streakDays).reduce((a, b) => a > b ? a : b);

  double get overallWeeklyConsistency {
    if (habits.isEmpty) return 0.0;
    final total = habits.fold<double>(
      0.0,
      (sum, h) => sum + h.weeklyCompletionRate,
    );
    return (total / habits.length).clamp(0.0, 1.0);
  }

  List<String> get availableCategories {
    final cats = <String>{'All'};
    for (final h in habits) {
      if (h.category.trim().isNotEmpty) {
        cats.add(h.category.trim());
      }
    }
    return cats.toList();
  }

  List<HabitEntity> get filteredHabits {
    if (selectedHabitCategory == 'All') return habits;
    return habits
        .where(
          (h) =>
              h.category.toLowerCase() == selectedHabitCategory.toLowerCase(),
        )
        .toList();
  }

  TodayHubLoaded copyWith({
    List<HabitEntity>? habits,
    List<TimelineItemEntity>? timelineItems,
    String? selectedHabitCategory,
  }) {
    return TodayHubLoaded(
      habits: habits ?? this.habits,
      timelineItems: timelineItems ?? this.timelineItems,
      selectedHabitCategory:
          selectedHabitCategory ?? this.selectedHabitCategory,
    );
  }

  @override
  List<Object?> get props => [habits, timelineItems, selectedHabitCategory];
}

class TodayHubError extends TodayHubState {
  final String message;
  const TodayHubError(this.message);
  @override
  List<Object?> get props => [message];
}
