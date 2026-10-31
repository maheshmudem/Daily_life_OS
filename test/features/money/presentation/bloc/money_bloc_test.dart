import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_life_os/core/database/app_database.dart';
import 'package:daily_life_os/features/money/data/datasources/money_local_datasource.dart';
import 'package:daily_life_os/features/money/data/repositories/money_repository_impl.dart';
import 'package:daily_life_os/features/money/domain/entities/money_category.dart';
import 'package:daily_life_os/features/money/domain/entities/money_insights.dart';
import 'package:daily_life_os/features/money/domain/usecases/get_transactions_and_budget_usecase.dart';
import 'package:daily_life_os/features/money/domain/usecases/manage_budgets_and_accounts_usecase.dart';
import 'package:daily_life_os/features/money/domain/usecases/manage_subscriptions_and_ious_usecase.dart';
import 'package:daily_life_os/features/money/domain/usecases/manage_transactions_usecase.dart';
import 'package:daily_life_os/features/money/presentation/bloc/money_bloc.dart';
import '../../../../core/notifications/fake_notification_service.dart';

void main() {
  late AppDatabase db;
  late FakeNotificationService notifications;
  late MoneyBloc bloc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notifications = FakeNotificationService();
    final ds = MoneyLocalDataSourceImpl(db);
    final repo = MoneyRepositoryImpl(ds);

    bloc = MoneyBloc(
      getRecentTransactionsUseCase: GetRecentTransactionsUseCase(repo),
      getBudgetUseCase: GetBudgetUseCase(repo),
      getSubscriptionsUseCase: GetSubscriptionsUseCase(repo),
      getIousUseCase: GetIousUseCase(repo),
      addTransactionUseCase: AddTransactionUseCase(repo),
      toggleAutoKillUseCase: ToggleAutoKillUseCase(repo),
      settleIouUseCase: SettleIouUseCase(repo),
      addIouUseCase: AddIouUseCase(repo),
      updateBudgetUseCase: UpdateBudgetUseCase(repo),
      getAllTransactionsUseCase: GetAllTransactionsUseCase(repo),
      updateTransactionUseCase: UpdateTransactionUseCase(repo),
      deleteTransactionUseCase: DeleteTransactionUseCase(repo),
      getCategoryLimitsUseCase: GetCategoryLimitsUseCase(repo),
      setCategoryLimitUseCase: SetCategoryLimitUseCase(repo),
      getAccountsUseCase: GetAccountsUseCase(repo),
      addAccountUseCase: AddAccountUseCase(repo),
      updateAccountUseCase: UpdateAccountUseCase(repo),
      deleteAccountUseCase: DeleteAccountUseCase(repo),
      addSubscriptionUseCase: AddSubscriptionUseCase(repo),
      deleteSubscriptionUseCase: DeleteSubscriptionUseCase(repo),
      deleteIouUseCase: DeleteIouUseCase(repo),
      getMoneySettingsUseCase: GetMoneySettingsUseCase(repo),
      updateMoneySettingsUseCase: UpdateMoneySettingsUseCase(repo),
      notifyBudgetThresholdUseCase: NotifyBudgetThresholdUseCase(notifications),
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  test(
    'MoneyBloc computes insights, updates category budgets, and triggers budget alerts',
    () async {
      bloc.add(const LoadMoney());
      await pumpEventQueue();
      expect(bloc.state, isA<MoneyLoaded>());

      // Set a Food category budget limit of 1000
      bloc.add(const SetCategoryLimit('food', 1000));
      await pumpEventQueue();

      var loaded = bloc.state as MoneyLoaded;
      final foodBudget = loaded.categoryBudgets.firstWhere(
        (b) => b.category == MoneyCategory.food.key,
      );
      expect(foodBudget.monthlyLimit, 1000);
      expect(foodBudget.spent, 0);

      // Log a 850 expense in food -> crosses 80% threshold -> triggers notification
      bloc.add(
        AddTransaction(
          title: 'Dinner',
          category: 'food',
          amount: 850,
          mode: 'UPI',
          iconCodePoint: MoneyCategory.food.icon.codePoint,
          type: 'expense',
        ),
      );
      await pumpEventQueue();

      loaded = bloc.state as MoneyLoaded;
      final updatedFood = loaded.categoryBudgets.firstWhere(
        (b) => b.category == MoneyCategory.food.key,
      );
      expect(updatedFood.spent, 850);
      expect(updatedFood.isNearLimit, isTrue);
      expect(notifications.instantNotifications, isNotEmpty);

      // Log an income of 5000 -> balance becomes 5000 - 850 = 4150
      bloc.add(
        AddTransaction(
          title: 'Freelance',
          category: 'business',
          amount: 5000,
          mode: 'Bank',
          iconCodePoint: MoneyCategory.business.icon.codePoint,
          type: 'income',
        ),
      );
      await pumpEventQueue();

      loaded = bloc.state as MoneyLoaded;
      expect(loaded.insights.balance, 4150);
      expect(loaded.insights.monthIncome, 5000);
      expect(loaded.insights.monthExpense, 850);

      // Add an asset account and verify totalAssets
      bloc.add(
        const AddAccount(name: 'Cash Wallet', type: 'cash', balance: 2500),
      );
      await pumpEventQueue();

      loaded = bloc.state as MoneyLoaded;
      expect(loaded.insights.totalAssets, 2500);
    },
  );

  test(
    'MoneyBloc applies 50/30/20 Smart Budget Plan and scales limits across Weekly / 6-Month / Yearly periods',
    () async {
      bloc.add(const LoadMoney());
      await pumpEventQueue();

      bloc.add(
        const ApplyBudgetPlan(
          preset: BudgetPlanPreset.standard503020,
          monthlyBudget: 60000,
          fixedBills: 15000,
        ),
      );
      await pumpEventQueue();

      var loaded = bloc.state as MoneyLoaded;
      expect(loaded.budget.monthlyBudget, 60000);
      expect(loaded.budget.fixedBills, 15000);
      // 50% Needs + 30% Wants = 80% of 60,000 = 48,000 allocated across categories
      final monthlyTotalAllocated = loaded.categoryBudgets.fold<double>(
        0,
        (s, b) => s + b.monthlyLimit,
      );
      expect(monthlyTotalAllocated, closeTo(48000, 10));

      // Switch to 6 Months -> limits scale by 6x
      bloc.add(const ChangeMoneyPeriod(MoneyPeriod.sixMonths));
      await pumpEventQueue();

      loaded = bloc.state as MoneyLoaded;
      expect(loaded.selectedPeriod, MoneyPeriod.sixMonths);
      expect(loaded.insights.periodBarLabels.length, 6);
      final sixMonthTotal = loaded.categoryBudgets.fold<double>(
        0,
        (s, b) => s + b.monthlyLimit,
      );
      expect(sixMonthTotal, closeTo(monthlyTotalAllocated * 6, 1));

      // Switch to Weekly -> limits scale by 0.25x and chart shows 7 days (Mon..Sun)
      bloc.add(const ChangeMoneyPeriod(MoneyPeriod.weekly));
      await pumpEventQueue();

      loaded = bloc.state as MoneyLoaded;
      expect(loaded.selectedPeriod, MoneyPeriod.weekly);
      expect(loaded.insights.periodBarLabels.length, 7);
      final weeklyTotal = loaded.categoryBudgets.fold<double>(
        0,
        (s, b) => s + b.monthlyLimit,
      );
      expect(weeklyTotal, closeTo(monthlyTotalAllocated * 0.25, 1));
    },
  );
}
