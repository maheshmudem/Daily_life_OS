import 'package:equatable/equatable.dart';

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

class ToggleTimelineItem extends TodayHubEvent {
  final int id;
  const ToggleTimelineItem(this.id);
  @override
  List<Object?> get props => [id];
}
