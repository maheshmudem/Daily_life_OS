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

  const TodayHubLoaded({required this.habits, required this.timelineItems});

  int get completedHabits => habits.where((h) => h.isDoneToday).length;

  @override
  List<Object?> get props => [habits, timelineItems];
}

class TodayHubError extends TodayHubState {
  final String message;
  const TodayHubError(this.message);
  @override
  List<Object?> get props => [message];
}
