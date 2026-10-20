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
  }) =>
      _localDataSource.addItem(
        title: title,
        date: date,
        startTime: startTime,
        endTime: endTime,
        category: category,
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
      );

  @override
  Future<void> toggleItem(int id) => _localDataSource.toggleItem(id);

  @override
  Future<void> deleteItem(int id) => _localDataSource.deleteItem(id);
}
