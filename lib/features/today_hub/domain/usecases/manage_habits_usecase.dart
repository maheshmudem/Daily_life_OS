import '../entities/habit_entity.dart';
import '../entities/timeline_item_entity.dart';
import '../repositories/today_hub_repository.dart';

class AddHabitUseCase {
  final TodayHubRepository _repository;
  const AddHabitUseCase(this._repository);

  Future<HabitEntity> call(HabitEntity habit) => _repository.addHabit(habit);
}

class UpdateHabitUseCase {
  final TodayHubRepository _repository;
  const UpdateHabitUseCase(this._repository);

  Future<void> call(HabitEntity habit) => _repository.updateHabit(habit);
}

class DeleteHabitUseCase {
  final TodayHubRepository _repository;
  const DeleteHabitUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteHabit(id);
}

class SkipHabitUseCase {
  final TodayHubRepository _repository;
  const SkipHabitUseCase(this._repository);

  Future<void> call(int id) => _repository.skipHabit(id);
}

class ToggleHabitDateUseCase {
  final TodayHubRepository _repository;
  const ToggleHabitDateUseCase(this._repository);

  Future<void> call(int id, String isoDate) =>
      _repository.toggleHabitDate(id, isoDate);
}

class AddTimelineItemUseCase {
  final TodayHubRepository _repository;
  const AddTimelineItemUseCase(this._repository);

  Future<TimelineItemEntity> call(TimelineItemEntity item) =>
      _repository.addTimelineItem(item);
}

class UpdateTimelineItemUseCase {
  final TodayHubRepository _repository;
  const UpdateTimelineItemUseCase(this._repository);

  Future<void> call(TimelineItemEntity item) =>
      _repository.updateTimelineItem(item);
}

class DeleteTimelineItemUseCase {
  final TodayHubRepository _repository;
  const DeleteTimelineItemUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteTimelineItem(id);
}
