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
  });
  Future<void> toggleItem(int id);
  Future<void> deleteItem(int id);
}
