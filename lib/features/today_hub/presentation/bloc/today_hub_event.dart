import 'package:equatable/equatable.dart';
import '../../domain/entities/habit_entity.dart';

abstract class TodayHubEvent extends Equatable {
  const TodayHubEvent();
  @override
  List<Object?> get props => [];
}

class LoadTodayHub extends TodayHubEvent {
  const LoadTodayHub();
}

class ToggleHabit extends TodayHubEvent {
  final int id;
  const ToggleHabit(this.id);
  @override
  List<Object?> get props => [id];
}

class AddHabit extends TodayHubEvent {
  final HabitEntity habit;
  const AddHabit(this.habit);
  @override
  List<Object?> get props => [habit];
}

class UpdateHabit extends TodayHubEvent {
  final HabitEntity habit;
  const UpdateHabit(this.habit);
  @override
  List<Object?> get props => [habit];
}

class DeleteHabit extends TodayHubEvent {
  final int id;
  const DeleteHabit(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleTimelineItem extends TodayHubEvent {
  final int id;
  const ToggleTimelineItem(this.id);
  @override
  List<Object?> get props => [id];
}
