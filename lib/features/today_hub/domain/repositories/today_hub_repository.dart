import '../entities/habit_entity.dart';
import '../entities/timeline_item_entity.dart';

abstract class TodayHubRepository {
  Future<List<HabitEntity>> getHabits();
  Future<HabitEntity> addHabit(HabitEntity habit);
  Future<void> updateHabit(HabitEntity habit);
  Future<void> deleteHabit(int id);
  Future<void> toggleHabit(int id);
  Future<void> skipHabit(int id);
  Future<void> toggleHabitDate(int id, String isoDate);

  Future<List<TimelineItemEntity>> getTodayTimeline();
  Future<void> toggleTimelineItem(int id);
  Future<TimelineItemEntity> addTimelineItem(TimelineItemEntity item);
  Future<void> updateTimelineItem(TimelineItemEntity item);
  Future<void> deleteTimelineItem(int id);
}
