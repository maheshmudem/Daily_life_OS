import '../repositories/planner_repository.dart';

class AddPlannerItemUseCase {
  final PlannerRepository _repository;

  const AddPlannerItemUseCase(this._repository);

  Future<void> call({
    required String title,
    required String date,
    String? startTime,
    String? endTime,
    required String category,
    required int colorValue,
    required int iconCodePoint,
  }) =>
      _repository.addItem(
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        category: category,
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
      );
}

class TogglePlannerItemUseCase {
  final PlannerRepository _repository;

  const TogglePlannerItemUseCase(this._repository);

  Future<void> call(int id) => _repository.toggleItem(id);
}

class DeletePlannerItemUseCase {
  final PlannerRepository _repository;

  const DeletePlannerItemUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteItem(id);
}
