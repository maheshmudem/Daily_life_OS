import '../repositories/today_hub_repository.dart';

class ToggleTimelineItemUseCase {
  final TodayHubRepository _repository;

  const ToggleTimelineItemUseCase(this._repository);

  Future<void> call(int id) => _repository.toggleTimelineItem(id);
}
