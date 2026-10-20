import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/money_repository.dart';
import '../datasources/money_local_datasource.dart';

class MoneyRepositoryImpl implements MoneyRepository {
  final MoneyLocalDataSource _localDataSource;

  MoneyRepositoryImpl(this._localDataSource);

  @override
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 30}) =>
      _localDataSource.getRecentTransactions(limit: limit);

  @override
  Future<BudgetEntity> getBudget() => _localDataSource.getBudget();

  @override
  Future<void> addTransaction({
    required String title,
    required String category,
    required double amount,
    required String mode,
    required int iconCodePoint,
    String type = 'expense',
  }) =>
      _localDataSource.addTransaction(
        title: title,
        category: category,
        amount: amount,
        mode: mode,
        iconCodePoint: iconCodePoint,
        type: type,
      );

  @override
  Future<void> updateBudget(double monthlyBudget, double fixedBills) =>
      _localDataSource.updateBudget(monthlyBudget, fixedBills);

  @override
  Future<List<SubscriptionEntity>> getSubscriptions() =>
      _localDataSource.getSubscriptions();

  @override
  Future<void> toggleAutoKill(int id) => _localDataSource.toggleAutoKill(id);

  @override
  Future<List<IouEntity>> getIous() => _localDataSource.getIous();

  @override
  Future<void> settleIou(int id) => _localDataSource.settleIou(id);

  @override
  Future<void> addIou({
    required String person,
    required double amount,
    required String type,
    required String note,
  }) =>
      _localDataSource.addIou(
        person: person,
        amount: amount,
        type: type,
        note: note,
      );
}
