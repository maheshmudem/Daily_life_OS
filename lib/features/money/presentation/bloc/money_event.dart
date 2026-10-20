import 'package:equatable/equatable.dart';

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

  const AddTransaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.mode,
    required this.iconCodePoint,
  });

  @override
  List<Object?> get props => [title, amount];
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
  const AddIou({required this.person, required this.amount, required this.type, required this.note});
  @override
  List<Object?> get props => [person, amount];
}

class UpdateBudget extends MoneyEvent {
  final double monthlyBudget;
  final double fixedBills;
  const UpdateBudget(this.monthlyBudget, this.fixedBills);
  @override
  List<Object?> get props => [monthlyBudget, fixedBills];
}
