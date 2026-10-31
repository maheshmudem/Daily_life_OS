import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/app_database.dart';
import '../models/money_account_model.dart';
import '../models/subscription_model.dart';
import '../models/transaction_model.dart';

abstract class MoneyLocalDataSource {
  Future<List<TransactionModel>> getRecentTransactions({int limit = 30});
  Future<BudgetModel> getBudget();
  Future<void> addTransaction({
    required String title,
    required String category,
    required double amount,
    required String mode,
    required int iconCodePoint,
    String type = 'expense',
    DateTime? date,
    String? note,
  });
  Future<void> updateBudget(double monthlyBudget, double fixedBills);
  Future<List<SubscriptionModel>> getSubscriptions();
  Future<void> toggleAutoKill(int id);
  Future<List<IouModel>> getIous();
  Future<void> settleIou(int id);
  Future<void> addIou({
    required String person,
    required double amount,
    required String type,
    required String note,
  });

  // ── v3: full expense-tracker support ──────────────────────────────────────
  Future<List<TransactionModel>> getAllTransactions();
  Future<List<TransactionModel>> getTransactionsInRange(
    DateTime start,
    DateTime end,
  );
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(int id);
  Future<Map<String, double>> getCategoryLimits();
  Future<void> setCategoryLimit(String category, double limit);
  Future<List<MoneyAccountModel>> getAccounts();
  Future<void> addAccount({
    required String name,
    required String type,
    required double balance,
    required int colorValue,
    required int iconCodePoint,
  });
  Future<void> updateAccount(MoneyAccountModel account);
  Future<void> deleteAccount(int id);
  Future<void> addSubscription({
    required String name,
    required double amount,
    required DateTime renewalDate,
    required int iconCodePoint,
    bool autoKillEnabled = false,
  });
  Future<void> deleteSubscription(int id);
  Future<void> deleteIou(int id);
  Future<MoneySettingsModel> getMoneySettings();
  Future<void> updateMoneySettings({
    String? currencyCode,
    bool? budgetAlertsEnabled,
    bool? moneyLockEnabled,
  });
}

class MoneyLocalDataSourceImpl implements MoneyLocalDataSource {
  final AppDatabase _db;

  MoneyLocalDataSourceImpl(this._db);

  @override
  Future<List<TransactionModel>> getRecentTransactions({int limit = 30}) async {
    final rows =
        await (_db.select(_db.transactions)
              ..orderBy([(t) => OrderingTerm.desc(t.date)])
              ..limit(limit))
            .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  @override
  Future<BudgetModel> getBudget() async {
    final settings = await _ensureSettings();

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final allTx =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.type.equals('expense') &
                  t.date.isBiggerOrEqualValue(monthStart),
            ))
            .get();
    final totalSpent = allTx.fold<double>(0, (sum, t) => sum + t.amount);

    return BudgetModel.fromValues(
      monthlyBudget: settings.monthlyBudget,
      fixedBills: settings.fixedBills,
      totalSpent: totalSpent,
    );
  }

  /// Returns the single settings row, creating it with defaults if missing.
  Future<BudgetSetting> _ensureSettings() async {
    final existing = await (_db.select(
      _db.budgetSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (existing != null) return existing;
    await _db
        .into(_db.budgetSettings)
        .insertOnConflictUpdate(
          const BudgetSettingsCompanion(
            id: Value(1),
            monthlyBudget: Value(40000),
            fixedBills: Value(8000),
          ),
        );
    return (_db.select(
      _db.budgetSettings,
    )..where((t) => t.id.equals(1))).getSingle();
  }

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
  }) async {
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            title: title,
            category: category,
            amount: amount,
            mode: mode,
            iconCodePoint: iconCodePoint,
            date: (date ?? DateTime.now()).toIso8601String(),
            type: Value(type),
            note: Value(note),
          ),
        );
  }

  @override
  Future<void> updateBudget(double monthlyBudget, double fixedBills) async {
    await _ensureSettings();
    await (_db.update(_db.budgetSettings)..where((t) => t.id.equals(1))).write(
      BudgetSettingsCompanion(
        monthlyBudget: Value(monthlyBudget),
        fixedBills: Value(fixedBills),
      ),
    );
  }

  @override
  Future<List<SubscriptionModel>> getSubscriptions() async {
    final rows = await _db.select(_db.subscriptions).get();
    return rows.map(SubscriptionModel.fromDrift).toList();
  }

  @override
  Future<void> toggleAutoKill(int id) async {
    final sub = await (_db.select(
      _db.subscriptions,
    )..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(_db.subscriptions)..where((t) => t.id.equals(id))).write(
      SubscriptionsCompanion(autoKillEnabled: Value(!sub.autoKillEnabled)),
    );
  }

  @override
  Future<List<IouModel>> getIous() async {
    final rows = await (_db.select(
      _db.iouEntries,
    )..where((t) => t.isSettled.equals(false))).get();
    return rows.map(IouModel.fromDrift).toList();
  }

  @override
  Future<void> settleIou(int id) async {
    await (_db.update(_db.iouEntries)..where((t) => t.id.equals(id))).write(
      const IouEntriesCompanion(isSettled: Value(true)),
    );
  }

  @override
  Future<void> addIou({
    required String person,
    required double amount,
    required String type,
    required String note,
  }) async {
    await _db
        .into(_db.iouEntries)
        .insert(
          IouEntriesCompanion.insert(
            person: person,
            amount: amount,
            type: type,
            note: note,
            date: DateTime.now().toIso8601String(),
          ),
        );
  }

  // ── v3: full expense-tracker support ──────────────────────────────────────

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final rows = await (_db.select(
      _db.transactions,
    )..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows =
        await (_db.select(_db.transactions)
              ..where(
                (t) =>
                    t.date.isBiggerOrEqualValue(start.toIso8601String()) &
                    t.date.isSmallerThanValue(end.toIso8601String()),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.date)]))
            .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await (_db.update(
      _db.transactions,
    )..where((t) => t.id.equals(transaction.id))).write(
      TransactionsCompanion(
        title: Value(transaction.title),
        category: Value(transaction.category),
        amount: Value(transaction.amount),
        mode: Value(transaction.mode),
        iconCodePoint: Value(transaction.iconCodePoint),
        date: Value(transaction.date),
        type: Value(transaction.type),
        note: Value(transaction.note),
      ),
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<Map<String, double>> getCategoryLimits() async {
    final rows = await _db.select(_db.categoryBudgets).get();
    return {for (final r in rows) r.category: r.monthlyLimit};
  }

  @override
  Future<void> setCategoryLimit(String category, double limit) async {
    await _db
        .into(_db.categoryBudgets)
        .insert(
          CategoryBudgetsCompanion.insert(
            category: category,
            monthlyLimit: Value(limit),
          ),
          onConflict: DoUpdate(
            (_) => CategoryBudgetsCompanion(monthlyLimit: Value(limit)),
            target: [_db.categoryBudgets.category],
          ),
        );
  }

  @override
  Future<List<MoneyAccountModel>> getAccounts() async {
    final rows = await _db.select(_db.moneyAccounts).get();
    return rows.map(MoneyAccountModel.fromDrift).toList();
  }

  @override
  Future<void> addAccount({
    required String name,
    required String type,
    required double balance,
    required int colorValue,
    required int iconCodePoint,
  }) async {
    await _db
        .into(_db.moneyAccounts)
        .insert(
          MoneyAccountsCompanion.insert(
            name: name,
            type: type,
            balance: Value(balance),
            colorValue: colorValue,
            iconCodePoint: iconCodePoint,
          ),
        );
  }

  @override
  Future<void> updateAccount(MoneyAccountModel account) async {
    await (_db.update(
      _db.moneyAccounts,
    )..where((t) => t.id.equals(account.id))).write(
      MoneyAccountsCompanion(
        name: Value(account.name),
        type: Value(account.type),
        balance: Value(account.balance),
        colorValue: Value(account.colorValue),
        iconCodePoint: Value(account.iconCodePoint),
      ),
    );
  }

  @override
  Future<void> deleteAccount(int id) async {
    await (_db.delete(_db.moneyAccounts)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> addSubscription({
    required String name,
    required double amount,
    required DateTime renewalDate,
    required int iconCodePoint,
    bool autoKillEnabled = false,
  }) async {
    await _db
        .into(_db.subscriptions)
        .insert(
          SubscriptionsCompanion.insert(
            name: name,
            amount: amount,
            renewalDate: renewalDate.toIso8601String(),
            iconCodePoint: iconCodePoint,
            autoKillEnabled: Value(autoKillEnabled),
          ),
        );
  }

  @override
  Future<void> deleteSubscription(int id) async {
    await (_db.delete(_db.subscriptions)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteIou(int id) async {
    await (_db.delete(_db.iouEntries)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<MoneySettingsModel> getMoneySettings() async {
    final row = await _ensureSettings();
    return MoneySettingsModel.fromDrift(row);
  }

  @override
  Future<void> updateMoneySettings({
    String? currencyCode,
    bool? budgetAlertsEnabled,
    bool? moneyLockEnabled,
  }) async {
    await _ensureSettings();
    await (_db.update(_db.budgetSettings)..where((t) => t.id.equals(1))).write(
      BudgetSettingsCompanion(
        currencyCode: currencyCode == null
            ? const Value.absent()
            : Value(currencyCode),
        budgetAlertsEnabled: budgetAlertsEnabled == null
            ? const Value.absent()
            : Value(budgetAlertsEnabled),
        moneyLockEnabled: moneyLockEnabled == null
            ? const Value.absent()
            : Value(moneyLockEnabled),
      ),
    );
  }
}
