import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../entities/category_budget_entity.dart';
import '../entities/money_account_entity.dart';
import '../entities/money_settings_entity.dart';
import '../repositories/money_repository.dart';

class GetCategoryLimitsUseCase {
  final MoneyRepository _repository;

  const GetCategoryLimitsUseCase(this._repository);

  Future<Map<String, double>> call() => _repository.getCategoryLimits();
}

class SetCategoryLimitUseCase {
  final MoneyRepository _repository;

  const SetCategoryLimitUseCase(this._repository);

  Future<void> call(String category, double limit) =>
      _repository.setCategoryLimit(category, limit);
}

class GetAccountsUseCase {
  final MoneyRepository _repository;

  const GetAccountsUseCase(this._repository);

  Future<List<MoneyAccountEntity>> call() => _repository.getAccounts();
}

class AddAccountUseCase {
  final MoneyRepository _repository;

  const AddAccountUseCase(this._repository);

  Future<void> call({
    required String name,
    required String type,
    required double balance,
    required int colorValue,
    required int iconCodePoint,
  }) => _repository.addAccount(
    name: name,
    type: type,
    balance: balance,
    colorValue: colorValue,
    iconCodePoint: iconCodePoint,
  );
}

class UpdateAccountUseCase {
  final MoneyRepository _repository;

  const UpdateAccountUseCase(this._repository);

  Future<void> call(MoneyAccountEntity account) =>
      _repository.updateAccount(account);
}

class DeleteAccountUseCase {
  final MoneyRepository _repository;

  const DeleteAccountUseCase(this._repository);

  Future<void> call(int id) => _repository.deleteAccount(id);
}

class GetMoneySettingsUseCase {
  final MoneyRepository _repository;

  const GetMoneySettingsUseCase(this._repository);

  Future<MoneySettingsEntity> call() => _repository.getMoneySettings();
}

class UpdateMoneySettingsUseCase {
  final MoneyRepository _repository;

  const UpdateMoneySettingsUseCase(this._repository);

  Future<void> call({
    String? currencyCode,
    bool? budgetAlertsEnabled,
    bool? moneyLockEnabled,
  }) => _repository.updateMoneySettings(
    currencyCode: currencyCode,
    budgetAlertsEnabled: budgetAlertsEnabled,
    moneyLockEnabled: moneyLockEnabled,
  );
}

/// Fires a local notification when a category crosses 80% or 100% of its
/// monthly limit (compares the budget before and after a change).
class NotifyBudgetThresholdUseCase {
  final NotificationService _notificationService;

  const NotifyBudgetThresholdUseCase(this._notificationService);

  /// Base id; category index is added so each category has its own slot.
  static const int _notificationBaseId = 7300;

  Future<void> call({
    required List<CategoryBudgetEntity> before,
    required List<CategoryBudgetEntity> after,
  }) async {
    for (var i = 0; i < after.length; i++) {
      final now = after[i];
      if (!now.hasLimit) continue;
      final previous = before.firstWhere(
        (b) => b.category == now.category,
        orElse: () => now.copyWith(spent: 0),
      );
      final label = now.categoryInfo.label;
      if (!previous.isOverBudget && now.isOverBudget) {
        await _notificationService.showInstantNotification(
          id: _notificationBaseId + i,
          title: '$label budget exceeded',
          body:
              'You have spent ${CurrencyUtils.format(now.spent)} of '
              '${CurrencyUtils.format(now.monthlyLimit)} this month.',
        );
      } else if (previous.progress < CategoryBudgetEntity.nearLimitThreshold &&
          now.progress >= CategoryBudgetEntity.nearLimitThreshold &&
          !now.isOverBudget) {
        await _notificationService.showInstantNotification(
          id: _notificationBaseId + i,
          title: '$label at ${now.percentUsed.round()}% of budget',
          body:
              'Only ${CurrencyUtils.format(now.remaining)} left for $label this month.',
        );
      }
    }
  }
}
