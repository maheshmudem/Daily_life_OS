import 'package:equatable/equatable.dart';
import '../../domain/entities/money_account_entity.dart';
import '../../domain/entities/money_insights.dart';
import '../../domain/entities/transaction_entity.dart';

abstract class MoneyEvent extends Equatable {
  const MoneyEvent();
  @override
  List<Object?> get props => [];
}

class LoadMoney extends MoneyEvent {
  const LoadMoney();
}

class AddTransaction extends MoneyEvent {
  final String title;
  final String category;
  final double amount;
  final String mode;
  final int iconCodePoint;
  final String type; // 'expense' / 'income'
  final DateTime? date;
  final String? note;

  const AddTransaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.mode,
    required this.iconCodePoint,
    this.type = 'expense',
    this.date,
    this.note,
  });

  @override
  List<Object?> get props => [
    title,
    category,
    amount,
    mode,
    iconCodePoint,
    type,
    date,
    note,
  ];
}

class ToggleAutoKill extends MoneyEvent {
  final int subscriptionId;
  const ToggleAutoKill(this.subscriptionId);
  @override
  List<Object?> get props => [subscriptionId];
}

class SettleIou extends MoneyEvent {
  final int iouId;
  const SettleIou(this.iouId);
  @override
  List<Object?> get props => [iouId];
}

class AddIou extends MoneyEvent {
  final String person;
  final double amount;
  final String type;
  final String note;
  const AddIou({
    required this.person,
    required this.amount,
    required this.type,
    required this.note,
  });
  @override
  List<Object?> get props => [person, amount, type, note];
}

class UpdateBudget extends MoneyEvent {
  final double monthlyBudget;
  final double fixedBills;
  const UpdateBudget(this.monthlyBudget, this.fixedBills);
  @override
  List<Object?> get props => [monthlyBudget, fixedBills];
}

// ── v3: full expense-tracker events ─────────────────────────────────────────

/// Switches the month used by Activity / Budgets / Insights.
class ChangeMonth extends MoneyEvent {
  final DateTime month;
  const ChangeMonth(this.month);
  @override
  List<Object?> get props => [month];
}

/// Switches the active time horizon (`Weekly` / `Monthly` / `6 Months` / `Yearly`).
class ChangeMoneyPeriod extends MoneyEvent {
  final MoneyPeriod period;
  const ChangeMoneyPeriod(this.period);
  @override
  List<Object?> get props => [period];
}

/// Applies a smart budget allocation preset (e.g. 50/30/20 rule) across all
/// expense categories based on [monthlyBudget].
class ApplyBudgetPlan extends MoneyEvent {
  final BudgetPlanPreset preset;
  final double monthlyBudget;
  final double? fixedBills;

  const ApplyBudgetPlan({
    required this.preset,
    required this.monthlyBudget,
    this.fixedBills,
  });

  @override
  List<Object?> get props => [preset, monthlyBudget, fixedBills];
}

class UpdateTransaction extends MoneyEvent {
  final TransactionEntity transaction;
  const UpdateTransaction(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

class DeleteTransaction extends MoneyEvent {
  final int transactionId;
  const DeleteTransaction(this.transactionId);
  @override
  List<Object?> get props => [transactionId];
}

class SetCategoryLimit extends MoneyEvent {
  final String category; // MoneyCategory key
  final double limit;
  const SetCategoryLimit(this.category, this.limit);
  @override
  List<Object?> get props => [category, limit];
}

class AddAccount extends MoneyEvent {
  final String name;
  final String type; // MoneyAccountType value
  final double balance;
  const AddAccount({
    required this.name,
    required this.type,
    required this.balance,
  });
  @override
  List<Object?> get props => [name, type, balance];
}

class UpdateAccount extends MoneyEvent {
  final MoneyAccountEntity account;
  const UpdateAccount(this.account);
  @override
  List<Object?> get props => [account];
}

class DeleteAccount extends MoneyEvent {
  final int accountId;
  const DeleteAccount(this.accountId);
  @override
  List<Object?> get props => [accountId];
}

class AddSubscription extends MoneyEvent {
  final String name;
  final double amount;
  final DateTime renewalDate;
  final int iconCodePoint;
  final bool autoKillEnabled;
  const AddSubscription({
    required this.name,
    required this.amount,
    required this.renewalDate,
    required this.iconCodePoint,
    this.autoKillEnabled = false,
  });
  @override
  List<Object?> get props => [
    name,
    amount,
    renewalDate,
    iconCodePoint,
    autoKillEnabled,
  ];
}

class DeleteSubscription extends MoneyEvent {
  final int subscriptionId;
  const DeleteSubscription(this.subscriptionId);
  @override
  List<Object?> get props => [subscriptionId];
}

class DeleteIou extends MoneyEvent {
  final int iouId;
  const DeleteIou(this.iouId);
  @override
  List<Object?> get props => [iouId];
}

class UpdateMoneySettings extends MoneyEvent {
  final String? currencyCode;
  final bool? budgetAlertsEnabled;
  final bool? moneyLockEnabled;
  const UpdateMoneySettings({
    this.currencyCode,
    this.budgetAlertsEnabled,
    this.moneyLockEnabled,
  });
  @override
  List<Object?> get props => [
    currencyCode,
    budgetAlertsEnabled,
    moneyLockEnabled,
  ];
}
