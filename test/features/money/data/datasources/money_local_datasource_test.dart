import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/features/money/data/datasources/money_local_datasource.dart';
import 'package:daily_life_os/features/money/data/models/transaction_model.dart';

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

  test(
    'MoneyLocalDataSource manages transactions, budget, subscriptions, and IOUs',
    () async {
      // 1. Initial budget should return default or compute spent = 0
      final budget = await dataSource.getBudget();
      expect(budget.monthlyBudget, 40000.0);
      expect(budget.totalSpent, 0.0);

      // 2. Add an expense transaction with custom note
      await dataSource.addTransaction(
        title: 'Groceries at Supermarket',
        category: 'food',
        amount: 1500.0,
        mode: 'UPI',
        iconCodePoint: 1234,
        type: 'expense',
        note: 'Weekly organic basket',
      );

      final transactions = await dataSource.getRecentTransactions();
      expect(transactions.length, 1);
      expect(transactions.first.title, 'Groceries at Supermarket');
      expect(transactions.first.amount, 1500.0);
      expect(transactions.first.note, 'Weekly organic basket');

      // 3. Re-check budget -> totalSpent should be 1500
      final updatedBudget = await dataSource.getBudget();
      expect(updatedBudget.totalSpent, 1500.0);

      // 4. Update & delete transaction
      final edited = transactions.first.copyWith(
        title: 'Updated Groceries',
        amount: 1800.0,
      );
      await dataSource.updateTransaction(TransactionModel.fromEntity(edited));
      final afterEdit = await dataSource.getAllTransactions();
      expect(afterEdit.first.title, 'Updated Groceries');
      expect(afterEdit.first.amount, 1800.0);

      await dataSource.deleteTransaction(afterEdit.first.id);
      expect(await dataSource.getAllTransactions(), isEmpty);

      // 5. Update budget settings
      await dataSource.updateBudget(50000.0, 10000.0);
      final customizedBudget = await dataSource.getBudget();
      expect(customizedBudget.monthlyBudget, 50000.0);
      expect(customizedBudget.fixedBills, 10000.0);

      // 6. Category limits CRUD
      await dataSource.setCategoryLimit('food', 6000.0);
      await dataSource.setCategoryLimit('transport', 2500.0);
      await dataSource.setCategoryLimit('food', 7500.0); // upsert
      final limits = await dataSource.getCategoryLimits();
      expect(limits['food'], 7500.0);
      expect(limits['transport'], 2500.0);

      // 7. Money accounts CRUD
      await dataSource.addAccount(
        name: 'Savings Bank',
        type: 'savings',
        balance: 85000.0,
        colorValue: 0xFF10B981,
        iconCodePoint: 5678,
      );
      final accounts = await dataSource.getAccounts();
      expect(accounts.length, 1);
      expect(accounts.first.balance, 85000.0);
      await dataSource.deleteAccount(accounts.first.id);
      expect(await dataSource.getAccounts(), isEmpty);

      // 8. Money settings persistence
      await dataSource.updateMoneySettings(
        currencyCode: 'USD',
        budgetAlertsEnabled: false,
        moneyLockEnabled: true,
      );
      final settings = await dataSource.getMoneySettings();
      expect(settings.currencyCode, 'USD');
      expect(settings.budgetAlertsEnabled, isFalse);
      expect(settings.moneyLockEnabled, isTrue);

      // 9. Add & settle IOU
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

      await dataSource.settleIou(ious.first.id);
      final activeIous = await dataSource.getIous();
      expect(activeIous, isEmpty);
    },
  );
}
