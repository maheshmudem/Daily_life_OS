import '../entities/money_account_entity.dart';
import '../entities/money_settings_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/subscription_entity.dart';

abstract class MoneyRepository {
  Future<List<TransactionEntity>> getRecentTransactions({int limit = 30});
  Future<BudgetEntity> getBudget();

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
  Future<List<SubscriptionEntity>> getSubscriptions();
  Future<void> toggleAutoKill(int id);
  Future<List<IouEntity>> getIous();
  Future<void> settleIou(int id);
  Future<void> addIou({
    required String person,
    required double amount,
    required String type,
    required String note,
  });

  // ── v3: full expense-tracker support ──────────────────────────────────────
  Future<List<TransactionEntity>> getAllTransactions();
  Future<List<TransactionEntity>> getTransactionsInRange(
    DateTime start,
    DateTime end,
  );
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(int id);
  Future<Map<String, double>> getCategoryLimits();
  Future<void> setCategoryLimit(String category, double limit);
  Future<List<MoneyAccountEntity>> getAccounts();
  Future<void> addAccount({
    required String name,
    required String type,
    required double balance,
    required int colorValue,
    required int iconCodePoint,
  });
  Future<void> updateAccount(MoneyAccountEntity account);
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
  Future<MoneySettingsEntity> getMoneySettings();
  Future<void> updateMoneySettings({
    String? currencyCode,
    bool? budgetAlertsEnabled,
    bool? moneyLockEnabled,
  });
}
