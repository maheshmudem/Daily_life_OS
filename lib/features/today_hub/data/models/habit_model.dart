import '../../../../core/database/app_database.dart';
import '../../domain/entities/habit_entity.dart';

class HabitModel extends HabitEntity {
  const HabitModel({
    required super.id,
    required super.title,
    required super.iconCodePoint,
    required super.colorValue,
    required super.streakDays,
    required super.isDoneToday,
    super.lastCompletedDate,
    required super.createdAt,
  });

  factory HabitModel.fromDrift(Habit row) {
    return HabitModel(
      id: row.id,
      title: row.title,
      iconCodePoint: row.iconCodePoint,
      colorValue: row.colorValue,
      streakDays: row.streakDays,
      isDoneToday: row.isDoneToday,
      lastCompletedDate: row.lastCompletedDate,
      createdAt: row.createdAt,
    );
  }

  factory HabitModel.fromEntity(HabitEntity entity) {
    return HabitModel(
      id: entity.id,
      title: entity.title,
      iconCodePoint: entity.iconCodePoint,
      colorValue: entity.colorValue,
      streakDays: entity.streakDays,
      isDoneToday: entity.isDoneToday,
      lastCompletedDate: entity.lastCompletedDate,
      createdAt: entity.createdAt,
    );
  }
}
