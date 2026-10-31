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

class GetAllTransactionsUseCase {
  final MoneyRepository _repository;

  const GetAllTransactionsUseCase(this._repository);

  Future<List<TransactionEntity>> call() => _repository.getAllTransactions();
}

class GetTransactionsInRangeUseCase {
  final MoneyRepository _repository;

  const GetTransactionsInRangeUseCase(this._repository);

  /// [end] is exclusive.
  Future<List<TransactionEntity>> call(DateTime start, DateTime end) =>
      _repository.getTransactionsInRange(start, end);
}

/// Snapshot used by Today Hub's Safe-to-Spend meter.
class DailySpendSnapshot {
  final double spentToday;
  final double dailySafeLimit;
  final int daysRemaining;
  final double monthlyBudget;

  const DailySpendSnapshot({
    required this.spentToday,
    required this.dailySafeLimit,
    required this.daysRemaining,
    required this.monthlyBudget,
  });
}

class GetDailySpendSnapshotUseCase {
  final MoneyRepository _repository;

  const GetDailySpendSnapshotUseCase(this._repository);

  Future<DailySpendSnapshot> call() async {
    final budget = await _repository.getBudget();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final today = await _repository.getTransactionsInRange(
      startOfDay,
      startOfDay.add(const Duration(days: 1)),
    );
    final spentToday = today
        .where((t) => t.isExpense)
        .fold<double>(0, (sum, t) => sum + t.amount);
    return DailySpendSnapshot(
      spentToday: spentToday,
      dailySafeLimit: budget.dailySafeSpend,
      daysRemaining: budget.daysRemaining,
      monthlyBudget: budget.monthlyBudget,
    );
  }
}
