import '../../../../core/database/app_database.dart';
import '../../domain/entities/timeline_item_entity.dart';

class TimelineItemModel extends TimelineItemEntity {
  const TimelineItemModel({
    required super.id,
    required super.time,
    required super.title,
    required super.category,
    required super.colorValue,
    required super.iconCodePoint,
    required super.isDone,
    required super.action,
    required super.date,
  });

  factory TimelineItemModel.fromDrift(TimelineItem row) {
    return TimelineItemModel(
      id: row.id,
      time: row.time,
      title: row.title,
      category: row.category,
      colorValue: row.colorValue,
      iconCodePoint: row.iconCodePoint,
      isDone: row.isDone,
      action: row.action,
      date: row.date,
    );
  }

  factory TimelineItemModel.fromEntity(TimelineItemEntity entity) {
    return TimelineItemModel(
      id: entity.id,
      time: entity.time,
      title: entity.title,
      category: entity.category,
      colorValue: entity.colorValue,
      iconCodePoint: entity.iconCodePoint,
      isDone: entity.isDone,
      action: entity.action,
      date: entity.date,
    );
  }
}
