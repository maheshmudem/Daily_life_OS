import '../repositories/today_hub_repository.dart';

class ToggleHabitUseCase {
  final TodayHubRepository _repository;

  const ToggleHabitUseCase(this._repository);

  Future<void> call(int id) => _repository.toggleHabit(id);
}
