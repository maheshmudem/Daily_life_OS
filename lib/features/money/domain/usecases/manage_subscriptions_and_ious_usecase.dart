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
  }) => _repository.addIou(
    person: person,
    amount: amount,
    type: type,
    note: note,
  );
}

class AddSubscriptionUseCase {
  final MoneyRepository _repository;

  const AddSubscriptionUseCase(this._repository);

  Future<void> call({
    required String name,
    required double amount,
    required DateTime renewalDate,
    required int iconCodePoint,
    bool autoKillEnabled = false,
  }) => _repository.addSubscription(
    name: name,
    amount: amount,
    renewalDate: renewalDate,
    iconCodePoint: iconCodePoint,
    autoKillEnabled: autoKillEnabled,
  );
}

class DeleteSubscriptionUseCase {
  final MoneyRepository _repository;

  const DeleteSubscriptionUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteSubscription(id);
}

class DeleteIouUseCase {
  final MoneyRepository _repository;

  const DeleteIouUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteIou(id);
}
