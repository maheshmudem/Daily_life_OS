import '../entities/planner_item_entity.dart';
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
    String repeatType = 'none',
    String repeatDays = '',
    String? endDate,
    String priority = 'medium',
    int reminderOffsetMinutes = 0,
    List<ChecklistItem> checklist = const [],
    String notes = '',
  }) =>
      _repository.addItem(
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        category: category,
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
        repeatType: repeatType,
        repeatDays: repeatDays,
        endDate: endDate,
        priority: priority,
        reminderOffsetMinutes: reminderOffsetMinutes,
        checklist: checklist,
        notes: notes,
      );
}

class TogglePlannerItemUseCase {
  final PlannerRepository _repository;

  const TogglePlannerItemUseCase(this._repository);

  Future<void> call(int id, {String? targetDate}) =>
      _repository.toggleItem(id, targetDate: targetDate);
}

class DeletePlannerItemUseCase {
  final PlannerRepository _repository;

  const DeletePlannerItemUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteItem(id);
}

class UpdatePlannerItemUseCase {
  final PlannerRepository _repository;

  const UpdatePlannerItemUseCase(this._repository);

  Future<void> call({
    required int id,
    required String title,
    required String date,
    String? startTime,
    String? endTime,
    required String category,
    required int colorValue,
    required int iconCodePoint,
    String repeatType = 'none',
    String repeatDays = '',
    String? endDate,
    String priority = 'medium',
    int reminderOffsetMinutes = 0,
    List<ChecklistItem> checklist = const [],
    String notes = '',
  }) =>
      _repository.updateItem(
        id: id,
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        category: category,
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
        repeatType: repeatType,
        repeatDays: repeatDays,
        endDate: endDate,
        priority: priority,
        reminderOffsetMinutes: reminderOffsetMinutes,
        checklist: checklist,
        notes: notes,
      );
}

class ClearCompletedPlannerItemsUseCase {
  final PlannerRepository _repository;

  ClearCompletedPlannerItemsUseCase(this._repository);

  Future<void> call() => _repository.clearCompletedItems();
}
