import 'package:equatable/equatable.dart';

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
  const TogglePlannerItem(this.id);
  @override
  List<Object?> get props => [id];
}

class DeletePlannerItem extends PlannerEvent {
  final int id;
  const DeletePlannerItem(this.id);
  @override
  List<Object?> get props => [id];
}

class AddPlannerItem extends PlannerEvent {
  final String title;
  final String date;
  final String? startTime;
  final String? endTime;
  final String category;
  final int colorValue;
  final int iconCodePoint;

  const AddPlannerItem({
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    required this.category,
    required this.colorValue,
    required this.iconCodePoint,
  });

  @override
  List<Object?> get props => [title, date];
}
