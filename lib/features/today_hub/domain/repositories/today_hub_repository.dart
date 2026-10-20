import '../entities/habit_entity.dart';
import '../entities/timeline_item_entity.dart';

abstract class TodayHubRepository {
  Future<List<HabitEntity>> getHabits();
  Future<void> toggleHabit(int id);
  Future<List<TimelineItemEntity>> getTodayTimeline();
  Future<void> toggleTimelineItem(int id);
}
