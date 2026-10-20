import '../entities/timeline_item_entity.dart';
import '../repositories/today_hub_repository.dart';

class GetTodayTimelineUseCase {
  final TodayHubRepository _repository;

  const GetTodayTimelineUseCase(this._repository);

  Future<List<TimelineItemEntity>> call() => _repository.getTodayTimeline();
}
