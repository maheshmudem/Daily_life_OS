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
}
