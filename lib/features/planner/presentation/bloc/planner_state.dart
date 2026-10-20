import 'package:equatable/equatable.dart';
import '../../domain/entities/planner_item_entity.dart';

abstract class PlannerState extends Equatable {
  const PlannerState();
  @override
  List<Object?> get props => [];
}

class PlannerInitial extends PlannerState {}

class PlannerLoading extends PlannerState {}

class PlannerLoaded extends PlannerState {
  final List<PlannerItemEntity> items;
  final String date;

  const PlannerLoaded({required this.items, required this.date});

  int get completedCount => items.where((i) => i.isDone).length;

  @override
  List<Object?> get props => [items, date];
}

class PlannerError extends PlannerState {
  final String message;
  const PlannerError(this.message);
  @override
  List<Object?> get props => [message];
}
