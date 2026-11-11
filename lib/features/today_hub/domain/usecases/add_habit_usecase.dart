import '../entities/habit_entity.dart';
import '../repositories/today_hub_repository.dart';

class AddHabitUseCase {
  final TodayHubRepository _repository;

  const AddHabitUseCase(this._repository);

  Future<void> call(HabitEntity habit) => _repository.addHabit(habit);
}

