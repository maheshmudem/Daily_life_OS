import '../../../../core/database/app_database.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerItemModel extends PlannerItemEntity {
  const PlannerItemModel({
    required super.id,
    required super.title,
    required super.date,
    super.startTime,
    super.endTime,
    required super.category,
    required super.colorValue,
    required super.iconCodePoint,
    required super.isDone,
    required super.notes,
  });

  factory PlannerItemModel.fromDrift(PlannerItem row) {
    return PlannerItemModel(
      id: row.id,
      title: row.title,
      date: row.date,
      startTime: row.startTime,
      endTime: row.endTime,
      category: row.category,
      colorValue: row.colorValue,
      iconCodePoint: row.iconCodePoint,
      isDone: row.isDone,
      notes: row.notes,
    );
  }

  factory PlannerItemModel.fromEntity(PlannerItemEntity entity) {
    return PlannerItemModel(
      id: entity.id,
      title: entity.title,
      date: entity.date,
      startTime: entity.startTime,
      endTime: entity.endTime,
      category: entity.category,
      colorValue: entity.colorValue,
      iconCodePoint: entity.iconCodePoint,
      isDone: entity.isDone,
      notes: entity.notes,
    );
  }
}
