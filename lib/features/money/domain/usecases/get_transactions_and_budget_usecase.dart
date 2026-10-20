import '../entities/transaction_entity.dart';
import '../repositories/money_repository.dart';

class GetRecentTransactionsUseCase {
  final MoneyRepository _repository;

  const GetRecentTransactionsUseCase(this._repository);

  Future<List<TransactionEntity>> call({int limit = 30}) =>
      _repository.getRecentTransactions(limit: limit);
}

class GetBudgetUseCase {
  final MoneyRepository _repository;

  const GetBudgetUseCase(this._repository);

  Future<BudgetEntity> call() => _repository.getBudget();
}
