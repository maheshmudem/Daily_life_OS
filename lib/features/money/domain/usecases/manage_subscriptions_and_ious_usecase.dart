import '../entities/subscription_entity.dart';
import '../repositories/money_repository.dart';

class GetSubscriptionsUseCase {
  final MoneyRepository _repository;

  const GetSubscriptionsUseCase(this._repository);

  Future<List<SubscriptionEntity>> call() => _repository.getSubscriptions();
}

class ToggleAutoKillUseCase {
  final MoneyRepository _repository;

  const ToggleAutoKillUseCase(this._repository);

  Future<void> call(int id) => _repository.toggleAutoKill(id);
}

class GetIousUseCase {
  final MoneyRepository _repository;

  const GetIousUseCase(this._repository);

  Future<List<IouEntity>> call() => _repository.getIous();
}

class SettleIouUseCase {
  final MoneyRepository _repository;

  const SettleIouUseCase(this._repository);

  Future<void> call(int id) => _repository.settleIou(id);
}

class AddIouUseCase {
  final MoneyRepository _repository;

  const AddIouUseCase(this._repository);

  Future<void> call({
    required String person,
    required double amount,
    required String type,
    required String note,
  }) =>
      _repository.addIou(
        person: person,
        amount: amount,
        type: type,
        note: note,
      );
}
