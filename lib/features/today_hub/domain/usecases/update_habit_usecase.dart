import '../entities/habit_entity.dart';
import '../repositories/today_hub_repository.dart';

class UpdateHabitUseCase {
  final TodayHubRepository _repository;

  const UpdateHabitUseCase(this._repository);

  Future<void> call(HabitEntity habit) => _repository.updateHabit(habit);
}

