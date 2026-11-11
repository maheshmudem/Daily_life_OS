import '../repositories/today_hub_repository.dart';

class DeleteHabitUseCase {
  final TodayHubRepository _repository;

  const DeleteHabitUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteHabit(id);
}

