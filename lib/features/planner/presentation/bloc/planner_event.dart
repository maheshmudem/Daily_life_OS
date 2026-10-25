import 'package:equatable/equatable.dart';
import '../../domain/entities/planner_item_entity.dart';

abstract class PlannerEvent extends Equatable {
  const PlannerEvent();
  @override
  List<Object?> get props => [];
}

class LoadPlanner extends PlannerEvent {
  final String date;
  const LoadPlanner(this.date);
  @override
  List<Object?> get props => [date];
}

class TogglePlannerItem extends PlannerEvent {
  final int id;
  final String? targetDate;
  const TogglePlannerItem(this.id, {this.targetDate});
  @override
  List<Object?> get props => [id, targetDate];
}

class DeletePlannerItem extends PlannerEvent {
  final int id;
  const DeletePlannerItem(this.id);
  @override
  List<Object?> get props => [id];
}

class ClearCompletedPlannerItems extends PlannerEvent {
  const ClearCompletedPlannerItems();
}

class AddPlannerItem extends PlannerEvent {
  final String title;
  final String date;
  final String? startTime;
  final String? endTime;
  final String category;
  final int colorValue;
  final int iconCodePoint;
  final String repeatType;
  final String repeatDays;
  final String? endDate;
  final String priority;
  final int reminderOffsetMinutes;
  final List<ChecklistItem> checklist;
  final String notes;

  const AddPlannerItem({
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
    this.repeatType = 'none',
    this.repeatDays = '',
    this.endDate,
    this.priority = 'medium',
    this.reminderOffsetMinutes = 0,
    this.checklist = const [],
    this.notes = '',
  });

  @override
  List<Object?> get props => [title, date, repeatType, repeatDays, endDate, priority];
}

class UpdatePlannerItem extends PlannerEvent {
  final int id;
  final String title;
  final String date;
  final String? startTime;
  final String? endTime;
  final String category;
  final int colorValue;
  final int iconCodePoint;
  final String repeatType;
  final String repeatDays;
  final String? endDate;
  final String priority;
  final int reminderOffsetMinutes;
  final List<ChecklistItem> checklist;
  final String notes;

  const UpdatePlannerItem({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
    this.repeatType = 'none',
    this.repeatDays = '',
    this.endDate,
    this.priority = 'medium',
    this.reminderOffsetMinutes = 0,
    this.checklist = const [],
    this.notes = '',
  });

  @override
  List<Object?> get props => [id, title, date, startTime, category, repeatType, repeatDays, endDate, priority];
}
