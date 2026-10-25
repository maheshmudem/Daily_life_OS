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
    super.repeatType,
    super.repeatDays,
    super.endDate,
    super.priority,
    super.reminderOffsetMinutes,
    super.checklist,
    super.completedDates,
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
      repeatType: row.repeatType,
      repeatDays: row.repeatDays,
      endDate: row.endDate,
      priority: row.priority,
      reminderOffsetMinutes: row.reminderOffsetMinutes,
      checklist: PlannerItemEntity.parseChecklistJson(row.checklistJson),
      completedDates: row.completedDates,
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
      repeatType: entity.repeatType,
      repeatDays: entity.repeatDays,
      endDate: entity.endDate,
      priority: entity.priority,
      reminderOffsetMinutes: entity.reminderOffsetMinutes,
      checklist: entity.checklist,
      completedDates: entity.completedDates,
    );
  }
}
