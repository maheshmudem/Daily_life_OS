import 'package:equatable/equatable.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/subscription_entity.dart';

abstract class MoneyState extends Equatable {
  const MoneyState();
  @override
  List<Object?> get props => [];
}

class MoneyInitial extends MoneyState {}

class MoneyLoading extends MoneyState {}

class MoneyLoaded extends MoneyState {
  final List<TransactionEntity> transactions;
  final BudgetEntity budget;
  final List<SubscriptionEntity> subscriptions;
  final List<IouEntity> ious;

  const MoneyLoaded({
    required this.transactions,
    required this.budget,
    required this.subscriptions,
    required this.ious,
  });

  @override
  List<Object?> get props => [transactions, budget, subscriptions, ious];
}

class MoneyError extends MoneyState {
  final String message;
  const MoneyError(this.message);
  @override
  List<Object?> get props => [message];
}
