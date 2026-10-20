import '../entities/habit_entity.dart';
import '../repositories/today_hub_repository.dart';

class GetHabitsUseCase {
  final TodayHubRepository _repository;

  const GetHabitsUseCase(this._repository);

  Future<List<HabitEntity>> call() => _repository.getHabits();
}
