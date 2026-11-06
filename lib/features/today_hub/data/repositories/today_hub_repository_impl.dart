import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/timeline_item_entity.dart';
import '../../domain/repositories/today_hub_repository.dart';
import '../datasources/today_hub_local_datasource.dart';

class TodayHubRepositoryImpl implements TodayHubRepository {
  final TodayHubLocalDataSource _localDataSource;

  TodayHubRepositoryImpl(this._localDataSource);

  @override
  Future<List<HabitEntity>> getHabits() => _localDataSource.getHabits();

  @override
  Future<HabitEntity> addHabit(HabitEntity habit) =>
      _localDataSource.addHabit(habit);

  @override
  Future<void> updateHabit(HabitEntity habit) =>
      _localDataSource.updateHabit(habit);

  @override
  Future<void> deleteHabit(int id) => _localDataSource.deleteHabit(id);

  @override
  Future<void> toggleHabit(int id) => _localDataSource.toggleHabit(id);

  @override
  Future<void> skipHabit(int id) => _localDataSource.skipHabit(id);

  @override
  Future<void> toggleHabitDate(int id, String isoDate) =>
      _localDataSource.toggleHabitDate(id, isoDate);

  @override
  Future<List<TimelineItemEntity>> getTodayTimeline() =>
      _localDataSource.getTodayTimeline();

  @override
  Future<void> toggleTimelineItem(int id) =>
      _localDataSource.toggleTimelineItem(id);

  @override
  Future<TimelineItemEntity> addTimelineItem(TimelineItemEntity item) =>
      _localDataSource.addTimelineItem(item);

  @override
  Future<void> updateTimelineItem(TimelineItemEntity item) =>
      _localDataSource.updateTimelineItem(item);

  @override
  Future<void> deleteTimelineItem(int id) =>
      _localDataSource.deleteTimelineItem(id);
}
