import '../../domain/entities/planner_item_entity.dart';
import '../../domain/repositories/planner_repository.dart';
import '../datasources/planner_local_datasource.dart';

class PlannerRepositoryImpl implements PlannerRepository {
  final PlannerLocalDataSource _localDataSource;

  PlannerRepositoryImpl(this._localDataSource);

  @override
  Future<List<PlannerItemEntity>> getItemsForDate(String isoDate) =>
      _localDataSource.getItemsForDate(isoDate);

  @override
  Future<void> addItem({
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
  }) => _localDataSource.addItem(
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

  @override
  Future<void> updateItem({
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
  }) => _localDataSource.updateItem(
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

  @override
  Future<void> toggleItem(int id, {String? targetDate}) =>
      _localDataSource.toggleItem(id, targetDate: targetDate);

  @override
  Future<void> deleteItem(int id) => _localDataSource.deleteItem(id);

  @override
  Future<void> clearCompletedItems() => _localDataSource.clearCompletedItems();
}
