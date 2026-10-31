import 'package:equatable/equatable.dart';
import 'money_category.dart';

/// Time horizon for Budget Manager and Analytics / Insights.
enum MoneyPeriod {
  weekly,
  monthly,
  sixMonths,
  yearly;

  String get shortLabel {
    switch (this) {
      case MoneyPeriod.weekly:
        return '1W';
      case MoneyPeriod.monthly:
        return '1M';
      case MoneyPeriod.sixMonths:
        return '6M';
      case MoneyPeriod.yearly:
        return '1Y';
    }
  }

  String get shortTag => shortLabel;

  String get label {
    switch (this) {
      case MoneyPeriod.weekly:
        return 'Weekly';
      case MoneyPeriod.monthly:
        return 'Monthly';
      case MoneyPeriod.sixMonths:
        return '6 Months';
      case MoneyPeriod.yearly:
        return 'Yearly';
    }
  }

  String get budgetTitle {
    switch (this) {
      case MoneyPeriod.weekly:
        return 'Weekly Budget';
      case MoneyPeriod.monthly:
        return 'Monthly Budget';
      case MoneyPeriod.sixMonths:
        return '6-Month Budget';
      case MoneyPeriod.yearly:
        return 'Yearly Budget';
    }
  }

  /// Multiplier applied to a monthly budget limit to scale it to this period.
  double get monthMultiplier {
    switch (this) {
      case MoneyPeriod.weekly:
        return 0.25; // 1 week ≈ 1/4 month
      case MoneyPeriod.monthly:
        return 1.0;
      case MoneyPeriod.sixMonths:
        return 6.0;
      case MoneyPeriod.yearly:
        return 12.0;
    }
  }
}

/// Smart budget allocation preset (e.g. 50/30/20 rule).
enum BudgetPlanPreset {
  standard503020,
  essentials602020,
  saver452035;

  String get title {
    switch (this) {
      case BudgetPlanPreset.standard503020:
        return '50 / 30 / 20 Balanced';
      case BudgetPlanPreset.essentials602020:
        return '60 / 20 / 20 Essentials';
      case BudgetPlanPreset.saver452035:
        return '45 / 20 / 35 Super Saver';
    }
  }

  String get subtitle {
    switch (this) {
      case BudgetPlanPreset.standard503020:
        return '50% Needs · 30% Wants · 20% Savings';
      case BudgetPlanPreset.essentials602020:
        return '60% Needs · 20% Wants · 20% Savings';
      case BudgetPlanPreset.saver452035:
        return '45% Needs · 20% Wants · 35% Savings';
    }
  }

  double get needsRatio {
    switch (this) {
      case BudgetPlanPreset.standard503020:
        return 0.50;
      case BudgetPlanPreset.essentials602020:
        return 0.60;
      case BudgetPlanPreset.saver452035:
        return 0.45;
    }
  }

  double get wantsRatio {
    switch (this) {
      case BudgetPlanPreset.standard503020:
        return 0.30;
      case BudgetPlanPreset.essentials602020:
        return 0.20;
      case BudgetPlanPreset.saver452035:
        return 0.20;
    }
  }

  double get savingsRatio => 1.0 - needsRatio - wantsRatio;

  double get needsShare => needsRatio;
  double get wantsShare => wantsRatio;
  double get savingsShare => savingsRatio;

  /// Computes per-category monthly limits from [monthlyBudget].
  Map<String, double> allocateMonthlyLimits(double monthlyBudget) {
    final needsPool = monthlyBudget * needsRatio;
    final wantsPool = monthlyBudget * wantsRatio;
    return {
      // Needs (100% of needsPool): Bills 45%, Food 30%, Transport 14%, Health 11%
      MoneyCategory.bills.key: (needsPool * 0.45).roundToDouble(),
      MoneyCategory.food.key: (needsPool * 0.30).roundToDouble(),
      MoneyCategory.transport.key: (needsPool * 0.14).roundToDouble(),
      MoneyCategory.health.key: (needsPool * 0.11).roundToDouble(),
      // Wants (100% of wantsPool): Shopping 40%, Travel 27%, Entertainment 20%, Other 13%
      MoneyCategory.shopping.key: (wantsPool * 0.40).roundToDouble(),
      MoneyCategory.travel.key: (wantsPool * 0.27).roundToDouble(),
      MoneyCategory.entertainment.key: (wantsPool * 0.20).roundToDouble(),
      MoneyCategory.other.key: (wantsPool * 0.13).roundToDouble(),
    };
  }
}

/// A single value bucketed by month (charts: income / net cashflow series).
class MonthlyValue extends Equatable {
  final DateTime month;
  final double value;

  const MonthlyValue({required this.month, required this.value});

  @override
  List<Object?> get props => [month, value];
}

/// Spend aggregated for one category in the selected period.
class CategorySpend extends Equatable {
  final MoneyCategory category;
  final double amount;

  /// Share of the period's total spend (0..1).
  final double share;

  const CategorySpend({
    required this.category,
    required this.amount,
    required this.share,
  });

  @override
  List<Object?> get props => [category, amount, share];
}

/// All derived analytics for the Money module (computed, never stored).
class MoneyInsights extends Equatable {
  final DateTime month;
  final MoneyPeriod period;

  // ── Balance ──────────────────────────────────────────────────────────────
  /// All-time balance: Σ income − Σ expense.
  final double balance;

  /// End-of-day running balance for the last 14 days (oldest → today).
  final List<double> balanceTrend;

  /// Change vs the first point of [balanceTrend].
  final double balanceChange;
  final double balanceChangePercent;

  // ── Selected month totals ───────────────────────────────────────────────
  final double monthIncome;
  final double monthExpense;
  final int transactionCount;
  final int daysElapsed;
  final double avgPerDay;

  // ── Active period totals (1W / 1M / 6M / 1Y) ────────────────────────────
  final double periodIncome;
  final double periodExpense;
  final double periodLimit;
  final List<String> periodBarLabels;
  final List<double> periodCurrentBars;
  final List<double> periodPreviousBars;
  final String periodCurrentLegend;
  final String periodPreviousLegend;

  // ── Weekly spend (W1 = 1–7, W2 = 8–14, W3 = 15–21, W4 = 22–end) ─────────
  final List<double> weeklySpend;
  final List<double> previousWeeklySpend;
  final int currentWeekIndex;
  final double currentWeekSpend;
  final double previousWeekSpend;
  final double percentVsAverage;
  final double percentVsLastWeek;

  // ── 6-month series ending at [month] ────────────────────────────────────
  final List<MonthlyValue> incomeSeries;
  final List<MonthlyValue> netSeries;

  // ── Categories & budget ─────────────────────────────────────────────────
  final List<CategorySpend> categorySpend;
  final double totalLimit;
  final double saved;
  final int budgetScore;
  final int overBudgetCount;
  final int nearLimitCount;

  // ── Assets ──────────────────────────────────────────────────────────────
  final double totalAssets;
  final Map<String, double> assetsByType;

  const MoneyInsights({
    required this.month,
    this.period = MoneyPeriod.monthly,
    required this.balance,
    required this.balanceTrend,
    required this.balanceChange,
    required this.balanceChangePercent,
    required this.monthIncome,
    required this.monthExpense,
    required this.transactionCount,
    required this.daysElapsed,
    required this.avgPerDay,
    this.periodIncome = 0,
    this.periodExpense = 0,
    this.periodLimit = 0,
    this.periodBarLabels = const ['W1', 'W2', 'W3', 'W4'],
    this.periodCurrentBars = const [0, 0, 0, 0],
    this.periodPreviousBars = const [0, 0, 0, 0],
    this.periodCurrentLegend = 'This month',
    this.periodPreviousLegend = 'Last month',
    required this.weeklySpend,
    required this.previousWeeklySpend,
    required this.currentWeekIndex,
    required this.currentWeekSpend,
    required this.previousWeekSpend,
    required this.percentVsAverage,
    required this.percentVsLastWeek,
    required this.incomeSeries,
    required this.netSeries,
    required this.categorySpend,
    required this.totalLimit,
    required this.saved,
    required this.budgetScore,
    required this.overBudgetCount,
    required this.nearLimitCount,
    required this.totalAssets,
    required this.assetsByType,
  });

  double get monthNet => monthIncome - monthExpense;
  double get periodNet => periodIncome - periodExpense;

  /// Spend progress against [totalLimit] (0..1), 0 when no limits are set.
  double get spendProgress =>
      totalLimit > 0 ? (monthExpense / totalLimit).clamp(0.0, 1.0) : 0.0;

  double get spendPercent =>
      totalLimit > 0 ? monthExpense / totalLimit * 100 : 0;

  double get periodProgress =>
      periodLimit > 0 ? (periodExpense / periodLimit).clamp(0.0, 1.0) : 0.0;

  double get periodSpendProgress => periodProgress;

  double get periodSaved =>
      (periodLimit - periodExpense).clamp(0.0, double.infinity);

  int get periodTransactionCount => transactionCount;

  double get periodAvgPerDay => avgPerDay;

  @override
  List<Object?> get props => [
    month,
    period,
    balance,
    balanceTrend,
    balanceChange,
    monthIncome,
    monthExpense,
    periodIncome,
    periodExpense,
    periodLimit,
    periodBarLabels,
    periodCurrentBars,
    periodPreviousBars,
    transactionCount,
    weeklySpend,
    previousWeeklySpend,
    incomeSeries,
    netSeries,
    categorySpend,
    totalLimit,
    budgetScore,
    totalAssets,
    assetsByType,
  ];
}
