import '../../domain/entities/money_account_entity.dart';
import '../../domain/entities/money_settings_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/subscription_entity.dart';
import '../../domain/repositories/money_repository.dart';
import '../datasources/money_local_datasource.dart';
import '../models/money_account_model.dart';
import '../models/transaction_model.dart';

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
    DateTime? date,
    String? note,
  }) => _localDataSource.addTransaction(
    title: title,
    category: category,
    amount: amount,
    mode: mode,
    iconCodePoint: iconCodePoint,
    type: type,
    date: date,
    note: note,
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
  }) => _localDataSource.addIou(
    person: person,
    amount: amount,
    type: type,
    note: note,
  );

  // ── v3: full expense-tracker support ──────────────────────────────────────

  @override
  Future<List<TransactionEntity>> getAllTransactions() =>
      _localDataSource.getAllTransactions();

  @override
  Future<List<TransactionEntity>> getTransactionsInRange(
    DateTime start,
    DateTime end,
  ) => _localDataSource.getTransactionsInRange(start, end);

  @override
  Future<void> updateTransaction(TransactionEntity transaction) =>
      _localDataSource.updateTransaction(
        TransactionModel.fromEntity(transaction),
      );

  @override
  Future<void> deleteTransaction(int id) =>
      _localDataSource.deleteTransaction(id);

  @override
  Future<Map<String, double>> getCategoryLimits() =>
      _localDataSource.getCategoryLimits();

  @override
  Future<void> setCategoryLimit(String category, double limit) =>
      _localDataSource.setCategoryLimit(category, limit);

  @override
  Future<List<MoneyAccountEntity>> getAccounts() =>
      _localDataSource.getAccounts();

  @override
  Future<void> addAccount({
    required String name,
    required String type,
    required double balance,
    required int colorValue,
    required int iconCodePoint,
  }) => _localDataSource.addAccount(
    name: name,
    type: type,
    balance: balance,
    colorValue: colorValue,
    iconCodePoint: iconCodePoint,
  );

  @override
  Future<void> updateAccount(MoneyAccountEntity account) =>
      _localDataSource.updateAccount(MoneyAccountModel.fromEntity(account));

  @override
  Future<void> deleteAccount(int id) => _localDataSource.deleteAccount(id);

  @override
  Future<void> addSubscription({
    required String name,
    required double amount,
    required DateTime renewalDate,
    required int iconCodePoint,
    bool autoKillEnabled = false,
  }) => _localDataSource.addSubscription(
    name: name,
    amount: amount,
    renewalDate: renewalDate,
    iconCodePoint: iconCodePoint,
    autoKillEnabled: autoKillEnabled,
  );

  @override
  Future<void> deleteSubscription(int id) =>
      _localDataSource.deleteSubscription(id);

  @override
  Future<void> deleteIou(int id) => _localDataSource.deleteIou(id);

  @override
  Future<MoneySettingsEntity> getMoneySettings() =>
      _localDataSource.getMoneySettings();

  @override
  Future<void> updateMoneySettings({
    String? currencyCode,
    bool? budgetAlertsEnabled,
    bool? moneyLockEnabled,
  }) => _localDataSource.updateMoneySettings(
    currencyCode: currencyCode,
    budgetAlertsEnabled: budgetAlertsEnabled,
    moneyLockEnabled: moneyLockEnabled,
  );
}
