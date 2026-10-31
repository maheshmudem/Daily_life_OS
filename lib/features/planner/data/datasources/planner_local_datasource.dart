import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/app_database.dart';
import '../../domain/entities/planner_item_entity.dart';
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

class PlannerLocalDataSourceImpl implements PlannerLocalDataSource {
  final AppDatabase _db;

  PlannerLocalDataSourceImpl(this._db);

  @override
  Future<List<PlannerItemModel>> getItemsForDate(String isoDate) async {
    if (isoDate == 'all' || isoDate.trim().isEmpty) {
      final rows =
          await (_db.select(_db.plannerItems)..orderBy([
                (t) => OrderingTerm.asc(t.date),
                (t) => OrderingTerm.asc(t.startTime),
              ]))
              .get();
      return rows.map((row) => PlannerItemModel.fromDrift(row)).toList();
    }

    final dateOnly = isoDate.substring(0, 10);
    final targetDateTime = DateTime.tryParse(dateOnly);
    if (targetDateTime == null) return [];

    // Query all items that start on or before target date
    final rows =
        await (_db.select(_db.plannerItems)
              ..where((t) => t.date.isSmallerOrEqualValue(dateOnly))
              ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
            .get();

    final result = <PlannerItemModel>[];

    for (final row in rows) {
      // 1. Check end date
      if (row.endDate != null && row.endDate!.isNotEmpty) {
        if (dateOnly.compareTo(row.endDate!) > 0) {
          continue; // Expired
        }
      }

      // 2. Evaluate recurrence
      bool matches = false;
      final repeat = row.repeatType;

      if (repeat == 'none' || repeat.isEmpty) {
        matches = row.date == dateOnly;
      } else if (repeat == 'daily') {
        matches = true;
      } else if (repeat == 'weekdays') {
        matches = targetDateTime.weekday >= 1 && targetDateTime.weekday <= 5;
      } else if (repeat == 'weekly') {
        if (row.repeatDays.isNotEmpty) {
          final days = row.repeatDays
              .split(',')
              .map((s) => int.tryParse(s.trim()))
              .whereType<int>()
              .toSet();
          matches = days.contains(targetDateTime.weekday);
        } else {
          final startDt = DateTime.tryParse(row.date);
          matches = startDt?.weekday == targetDateTime.weekday;
        }
      } else if (repeat == 'monthly') {
        final startDt = DateTime.tryParse(row.date);
        matches = startDt?.day == targetDateTime.day;
      }

      if (matches) {
        // Resolve isDone for this specific date
        final isCompletedForDate = (repeat != 'none' && repeat.isNotEmpty)
            ? row.completedDates
                  .split(',')
                  .map((s) => s.trim())
                  .contains(dateOnly)
            : row.isDone;

        final model = PlannerItemModel(
          id: row.id,
          title: row.title,
          date: row.date,
          startTime: row.startTime,
          endTime: row.endTime,
          category: row.category,
          colorValue: row.colorValue,
          iconCodePoint: row.iconCodePoint,
          isDone: isCompletedForDate,
          notes: row.notes,
          repeatType: row.repeatType,
          repeatDays: row.repeatDays,
          endDate: row.endDate,
          priority: row.priority,
          reminderOffsetMinutes: row.reminderOffsetMinutes,
          checklist: PlannerItemEntity.parseChecklistJson(row.checklistJson),
          completedDates: row.completedDates,
        );
        result.add(model);
      }
    }

    return result;
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
    String repeatType = 'none',
    String repeatDays = '',
    String? endDate,
    String priority = 'medium',
    int reminderOffsetMinutes = 0,
    List<ChecklistItem> checklist = const [],
    String notes = '',
  }) async {
    await _db
        .into(_db.plannerItems)
        .insert(
          PlannerItemsCompanion.insert(
            title: title,
            date: date.substring(0, 10),
            startTime: Value(startTime),
            endTime: Value(endTime),
            category: category,
            colorValue: colorValue,
            iconCodePoint: iconCodePoint,
            repeatType: Value(repeatType),
            repeatDays: Value(repeatDays),
            endDate: Value(
              endDate?.isNotEmpty == true ? endDate!.substring(0, 10) : null,
            ),
            priority: Value(priority),
            reminderOffsetMinutes: Value(reminderOffsetMinutes),
            checklistJson: Value(
              PlannerItemEntity.serializeChecklist(checklist),
            ),
            notes: Value(notes),
          ),
        );
  }

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
  }) async {
    await (_db.update(_db.plannerItems)..where((t) => t.id.equals(id))).write(
      PlannerItemsCompanion(
        title: Value(title),
        date: Value(date.substring(0, 10)),
        startTime: Value(startTime),
        endTime: Value(endTime),
        category: Value(category),
        colorValue: Value(colorValue),
        iconCodePoint: Value(iconCodePoint),
        repeatType: Value(repeatType),
        repeatDays: Value(repeatDays),
        endDate: Value(
          endDate?.isNotEmpty == true ? endDate!.substring(0, 10) : null,
        ),
        priority: Value(priority),
        reminderOffsetMinutes: Value(reminderOffsetMinutes),
        checklistJson: Value(PlannerItemEntity.serializeChecklist(checklist)),
        notes: Value(notes),
      ),
    );
  }

  @override
  Future<void> toggleItem(int id, {String? targetDate}) async {
    final item = await (_db.select(
      _db.plannerItems,
    )..where((t) => t.id.equals(id))).getSingle();
    final dateKey =
        (targetDate != null && targetDate != 'all' && targetDate.length >= 10)
        ? targetDate.substring(0, 10)
        : (item.repeatType != 'none' && item.repeatType.isNotEmpty
              ? DateTime.now().toIso8601String().substring(0, 10)
              : null);

    if (item.repeatType != 'none' &&
        item.repeatType.isNotEmpty &&
        dateKey != null) {
      final set = item.completedDates
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet();
      if (set.contains(dateKey)) {
        set.remove(dateKey);
      } else {
        set.add(dateKey);
      }
      await (_db.update(_db.plannerItems)..where((t) => t.id.equals(id))).write(
        PlannerItemsCompanion(completedDates: Value(set.join(','))),
      );
    } else {
      await (_db.update(_db.plannerItems)..where((t) => t.id.equals(id))).write(
        PlannerItemsCompanion(isDone: Value(!item.isDone)),
      );
    }
  }

  @override
  Future<void> deleteItem(int id) async {
    await (_db.delete(_db.plannerItems)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> clearCompletedItems() async {
    await (_db.delete(_db.plannerItems)..where(
          (t) =>
              t.isDone.equals(true) &
              (t.repeatType.equals('none') | t.repeatType.equals('')),
        ))
        .go();
  }
}
