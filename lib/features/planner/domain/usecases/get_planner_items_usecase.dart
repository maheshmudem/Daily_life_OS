import '../entities/planner_item_entity.dart';
import '../repositories/planner_repository.dart';

class GetPlannerItemsUseCase {
  final PlannerRepository _repository;

  const GetPlannerItemsUseCase(this._repository);

  Future<List<PlannerItemEntity>> call(String isoDate) =>
      _repository.getItemsForDate(isoDate);
}
