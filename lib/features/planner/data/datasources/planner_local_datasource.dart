import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/app_database.dart';
import '../models/planner_item_model.dart';

abstract class PlannerLocalDataSource {
  Future<List<PlannerItemModel>> getItemsForDate(String isoDate);
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

class PlannerLocalDataSourceImpl implements PlannerLocalDataSource {
  final AppDatabase _db;

  PlannerLocalDataSourceImpl(this._db);

  @override
  Future<List<PlannerItemModel>> getItemsForDate(String isoDate) async {
    final dateOnly = isoDate.substring(0, 10);
    final rows = await (_db.select(_db.plannerItems)
          ..where((t) => t.date.equals(dateOnly))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
    return rows.map(PlannerItemModel.fromDrift).toList();
  }

  @override
  Future<void> addItem({
    required String title,
    required String date,
    String? startTime,
    String? endTime,
    required String category,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    await _db.into(_db.plannerItems).insert(
          PlannerItemsCompanion.insert(
            title: title,
            date: date.substring(0, 10),
            startTime: Value(startTime),
            endTime: Value(endTime),
            category: category,
            colorValue: colorValue,
            iconCodePoint: iconCodePoint,
          ),
        );
  }

  @override
  Future<void> toggleItem(int id) async {
    final item = await (_db.select(_db.plannerItems)..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(_db.plannerItems)..where((t) => t.id.equals(id))).write(
      PlannerItemsCompanion(isDone: Value(!item.isDone)),
    );
  }

  @override
  Future<void> deleteItem(int id) async {
    await (_db.delete(_db.plannerItems)..where((t) => t.id.equals(id))).go();
  }
}
