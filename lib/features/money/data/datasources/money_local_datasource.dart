import 'package:drift/drift.dart' hide Column;
import '../../../../core/database/app_database.dart';
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
}

class MoneyLocalDataSourceImpl implements MoneyLocalDataSource {
  final AppDatabase _db;

  MoneyLocalDataSourceImpl(this._db);

  @override
  Future<List<TransactionModel>> getRecentTransactions({int limit = 30}) async {
    final rows = await (_db.select(_db.transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
    return rows.map(TransactionModel.fromDrift).toList();
  }

  @override
  Future<BudgetModel> getBudget() async {
    BudgetSetting settings;
    try {
      settings = await (_db.select(_db.budgetSettings)..where((t) => t.id.equals(1))).getSingle();
    } catch (_) {
      await _db.into(_db.budgetSettings).insertOnConflictUpdate(
            const BudgetSettingsCompanion(
              id: Value(1),
              monthlyBudget: Value(40000),
              fixedBills: Value(8000),
            ),
          );
      settings = await (_db.select(_db.budgetSettings)..where((t) => t.id.equals(1))).getSingle();
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final allTx = await (_db.select(_db.transactions)
          ..where((t) => t.type.equals('expense') & t.date.isBiggerOrEqualValue(monthStart)))
        .get();
    final totalSpent = allTx.fold<double>(0, (sum, t) => sum + t.amount);

    return BudgetModel.fromValues(
      monthlyBudget: settings.monthlyBudget,
      fixedBills: settings.fixedBills,
      totalSpent: totalSpent,
    );
  }

  @override
  Future<void> addTransaction({
    required String title,
    required String category,
    required double amount,
    required String mode,
    required int iconCodePoint,
    String type = 'expense',
  }) async {
    await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            title: title,
            category: category,
            amount: amount,
            mode: mode,
            iconCodePoint: iconCodePoint,
            date: DateTime.now().toIso8601String(),
            type: Value(type),
          ),
        );
  }

  @override
  Future<void> updateBudget(double monthlyBudget, double fixedBills) async {
    await _db.into(_db.budgetSettings).insertOnConflictUpdate(
          BudgetSettingsCompanion(
            id: const Value(1),
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
    final sub = await (_db.select(_db.subscriptions)..where((t) => t.id.equals(id))).getSingle();
    await (_db.update(_db.subscriptions)..where((t) => t.id.equals(id))).write(
      SubscriptionsCompanion(autoKillEnabled: Value(!sub.autoKillEnabled)),
    );
  }

  @override
  Future<List<IouModel>> getIous() async {
    final rows = await (_db.select(_db.iouEntries)
          ..where((t) => t.isSettled.equals(false)))
        .get();
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
    await _db.into(_db.iouEntries).insert(
          IouEntriesCompanion.insert(
            person: person,
            amount: amount,
            type: type,
            note: note,
            date: DateTime.now().toIso8601String(),
          ),
        );
  }
}
