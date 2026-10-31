import '../../../../core/database/app_database.dart';
import '../../domain/entities/money_account_entity.dart';
import '../../domain/entities/money_settings_entity.dart';

class MoneyAccountModel extends MoneyAccountEntity {
  const MoneyAccountModel({
    required super.id,
    required super.name,
    required super.type,
    required super.balance,
    required super.colorValue,
    required super.iconCodePoint,
  });

  factory MoneyAccountModel.fromDrift(MoneyAccount row) {
    return MoneyAccountModel(
      id: row.id,
      name: row.name,
      type: row.type,
      balance: row.balance,
      colorValue: row.colorValue,
      iconCodePoint: row.iconCodePoint,
    );
  }

  factory MoneyAccountModel.fromEntity(MoneyAccountEntity entity) {
    return MoneyAccountModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      balance: entity.balance,
      colorValue: entity.colorValue,
      iconCodePoint: entity.iconCodePoint,
    );
  }
}

class MoneySettingsModel extends MoneySettingsEntity {
  const MoneySettingsModel({
    super.currencyCode,
    super.budgetAlertsEnabled,
    super.moneyLockEnabled,
  });

  factory MoneySettingsModel.fromDrift(BudgetSetting row) {
    return MoneySettingsModel(
      currencyCode: row.currencyCode,
      budgetAlertsEnabled: row.budgetAlertsEnabled,
      moneyLockEnabled: row.moneyLockEnabled,
    );
  }
}
