import 'package:equatable/equatable.dart';

/// Money module preferences (stored in the single-row BudgetSettings table).
class MoneySettingsEntity extends Equatable {
  final String currencyCode;
  final bool budgetAlertsEnabled;
  final bool moneyLockEnabled;

  const MoneySettingsEntity({
    this.currencyCode = 'INR',
    this.budgetAlertsEnabled = true,
    this.moneyLockEnabled = false,
  });

  MoneySettingsEntity copyWith({
    String? currencyCode,
    bool? budgetAlertsEnabled,
    bool? moneyLockEnabled,
  }) {
    return MoneySettingsEntity(
      currencyCode: currencyCode ?? this.currencyCode,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      moneyLockEnabled: moneyLockEnabled ?? this.moneyLockEnabled,
    );
  }

  @override
  List<Object?> get props => [
    currencyCode,
    budgetAlertsEnabled,
    moneyLockEnabled,
  ];
}
