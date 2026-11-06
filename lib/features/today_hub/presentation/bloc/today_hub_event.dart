import 'package:equatable/equatable.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/timeline_item_entity.dart';

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

class SkipHabit extends TodayHubEvent {
  final int id;
  const SkipHabit(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleHabitDate extends TodayHubEvent {
  final int id;
  final String isoDate;
  const ToggleHabitDate({required this.id, required this.isoDate});
  @override
  List<Object?> get props => [id, isoDate];
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

class SelectHabitCategory extends TodayHubEvent {
  final String category;
  const SelectHabitCategory(this.category);
  @override
  List<Object?> get props => [category];
}

class ToggleTimelineItem extends TodayHubEvent {
  final int id;
  const ToggleTimelineItem(this.id);
  @override
  List<Object?> get props => [id];
}

class AddTimelineItem extends TodayHubEvent {
  final TimelineItemEntity item;
  const AddTimelineItem(this.item);
  @override
  List<Object?> get props => [item];
}

class UpdateTimelineItem extends TodayHubEvent {
  final TimelineItemEntity item;
  const UpdateTimelineItem(this.item);
  @override
  List<Object?> get props => [item];
}

class DeleteTimelineItem extends TodayHubEvent {
  final int id;
  const DeleteTimelineItem(this.id);
  @override
  List<Object?> get props => [id];
}
