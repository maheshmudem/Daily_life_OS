import 'package:equatable/equatable.dart';
import '../../domain/entities/category_budget_entity.dart';
import '../../domain/entities/money_account_entity.dart';
import '../../domain/entities/money_insights.dart';
import '../../domain/entities/money_settings_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/subscription_entity.dart';

abstract class MoneyState extends Equatable {
  const MoneyState();
  @override
  List<Object?> get props => [];
}

class MoneyInitial extends MoneyState {}

class MoneyLoading extends MoneyState {}

class MoneyLoaded extends MoneyState {
  /// Most recent transactions (newest first, capped).
  final List<TransactionEntity> transactions;
  final BudgetEntity budget;
  final List<SubscriptionEntity> subscriptions;
  final List<IouEntity> ious;

  // ── v3 ──────────────────────────────────────────────────────────────────
  /// Every transaction (newest first).
  final List<TransactionEntity> allTransactions;

  /// Month used by Activity / Budgets / Insights (first day of month).
  final DateTime selectedMonth;

  /// Active budget & analytics horizon (Weekly / Monthly / 6 Months / Yearly).
  final MoneyPeriod selectedPeriod;

  /// Transactions inside [selectedMonth] (newest first).
  final List<TransactionEntity> monthTransactions;

  /// Transactions inside the active [selectedPeriod] window (newest first).
  final List<TransactionEntity> periodTransactions;

  /// One entry per expense category scaled to [selectedPeriod].
  final List<CategoryBudgetEntity> categoryBudgets;

  /// Raw stored monthly limits keyed by category key.
  final Map<String, double> categoryLimits;
  final List<MoneyAccountEntity> accounts;
  final MoneyInsights insights;
  final MoneySettingsEntity settings;

  /// One-shot error from a failed mutation (UI shows a SnackBar).
  final String? actionError;

  const MoneyLoaded({
    required this.transactions,
    required this.budget,
    required this.subscriptions,
    required this.ious,
    required this.allTransactions,
    required this.selectedMonth,
    required this.monthTransactions,
    required this.categoryBudgets,
    required this.categoryLimits,
    required this.accounts,
    required this.insights,
    required this.settings,
    this.selectedPeriod = MoneyPeriod.monthly,
    this.periodTransactions = const [],
    this.actionError,
  });

  /// Monthly subscription burn.
  double get subscriptionsTotal =>
      subscriptions.fold<double>(0, (sum, s) => sum + s.amount);

  double get totalLent =>
      ious.where((i) => i.isLent).fold<double>(0, (sum, i) => sum + i.amount);

  double get totalBorrowed =>
      ious.where((i) => !i.isLent).fold<double>(0, (sum, i) => sum + i.amount);

  MoneyLoaded copyWith({String? actionError}) {
    return MoneyLoaded(
      transactions: transactions,
      budget: budget,
      subscriptions: subscriptions,
      ious: ious,
      allTransactions: allTransactions,
      selectedMonth: selectedMonth,
      selectedPeriod: selectedPeriod,
      monthTransactions: monthTransactions,
      periodTransactions: periodTransactions,
      categoryBudgets: categoryBudgets,
      categoryLimits: categoryLimits,
      accounts: accounts,
      insights: insights,
      settings: settings,
      actionError: actionError,
    );
  }

  @override
  List<Object?> get props => [
    transactions,
    budget,
    subscriptions,
    ious,
    allTransactions,
    selectedMonth,
    selectedPeriod,
    monthTransactions,
    periodTransactions,
    categoryBudgets,
    categoryLimits,
    accounts,
    insights,
    settings,
    actionError,
  ];
}

class MoneyError extends MoneyState {
  final String message;
  const MoneyError(this.message);
  @override
  List<Object?> get props => [message];
}
