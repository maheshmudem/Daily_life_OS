import '../entities/planner_item_entity.dart';

abstract class PlannerRepository {
  Future<List<PlannerItemEntity>> getItemsForDate(String isoDate);
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
  });
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
  });
  Future<void> toggleItem(int id, {String? targetDate});
  Future<void> deleteItem(int id);
  Future<void> clearCompletedItems();
}
