import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/features/money/data/datasources/money_local_datasource.dart';

void main() {
  late AppDatabase db;
  late MoneyLocalDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = MoneyLocalDataSourceImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('MoneyLocalDataSource manages transactions, budget, subscriptions, and IOUs',
      () async {
    // 1. Initial budget should return default or compute spent = 0
    final budget = await dataSource.getBudget();
    expect(budget.monthlyBudget, 40000.0);
    expect(budget.totalSpent, 0.0);

    // 2. Add an expense transaction
    await dataSource.addTransaction(
      title: 'Groceries at Supermarket',
      category: 'Food',
      amount: 1500.0,
      mode: 'UPI',
      iconCodePoint: 1234,
      type: 'expense',
    );

    final transactions = await dataSource.getRecentTransactions();
    expect(transactions.length, 1);
    expect(transactions.first.title, 'Groceries at Supermarket');
    expect(transactions.first.amount, 1500.0);

    // 3. Re-check budget -> totalSpent should be 1500
    final updatedBudget = await dataSource.getBudget();
    expect(updatedBudget.totalSpent, 1500.0);

    // 4. Update budget settings
    await dataSource.updateBudget(50000.0, 10000.0);
    final customizedBudget = await dataSource.getBudget();
    expect(customizedBudget.monthlyBudget, 50000.0);
    expect(customizedBudget.fixedBills, 10000.0);

    // 5. Add IOU
    await dataSource.addIou(
      person: 'David',
      amount: 500.0,
      type: 'lent',
      note: 'Lunch split',
    );
    final ious = await dataSource.getIous();
    expect(ious.length, 1);
    expect(ious.first.person, 'David');
    expect(ious.first.isSettled, false);

    // 6. Settle IOU -> Should no longer appear in unsettled list
    await dataSource.settleIou(ious.first.id);
    final activeIous = await dataSource.getIous();
    expect(activeIous, isEmpty);
  });
}
