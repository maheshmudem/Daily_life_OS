import '../../../../core/utils/date_utils.dart';
import '../entities/category_budget_entity.dart';
import '../entities/money_account_entity.dart';
import '../entities/money_category.dart';
import '../entities/money_insights.dart';
import '../entities/transaction_entity.dart';

/// Filters transactions that fall inside the calendar month of [month].
class FilterMonthTransactionsUseCase {
  const FilterMonthTransactionsUseCase();

  List<TransactionEntity> call(
    List<TransactionEntity> transactions,
    DateTime month,
  ) {
    final result =
        transactions
            .where((t) => AppDateUtils.isSameMonth(t.dateTime, month))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return result;
  }
}

/// Filters transactions for any [MoneyPeriod] anchored at [anchorMonth].
class FilterPeriodTransactionsUseCase {
  const FilterPeriodTransactionsUseCase();

  List<TransactionEntity> call(
    List<TransactionEntity> transactions, {
    required DateTime anchorMonth,
    required MoneyPeriod period,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final range = periodRange(
      anchorMonth: anchorMonth,
      period: period,
      now: clock,
    );
    final result =
        transactions
            .where(
              (t) =>
                  !t.dateTime.isBefore(range.$1) &&
                  t.dateTime.isBefore(range.$2),
            )
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return result;
  }

  /// Returns `(startInclusive, endExclusive)` for [period].
  static (DateTime, DateTime) periodRange({
    required DateTime anchorMonth,
    required MoneyPeriod period,
    required DateTime now,
  }) {
    switch (period) {
      case MoneyPeriod.weekly:
        final today = DateTime(now.year, now.month, now.day);
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return (startOfWeek, startOfWeek.add(const Duration(days: 7)));
      case MoneyPeriod.monthly:
        final start = AppDateUtils.startOfMonth(anchorMonth);
        return (start, AppDateUtils.startOfNextMonth(anchorMonth));
      case MoneyPeriod.sixMonths:
        final end = AppDateUtils.startOfNextMonth(anchorMonth);
        final start = DateTime(anchorMonth.year, anchorMonth.month - 5, 1);
        return (start, end);
      case MoneyPeriod.yearly:
        final end = AppDateUtils.startOfNextMonth(anchorMonth);
        final start = DateTime(anchorMonth.year, anchorMonth.month - 11, 1);
        return (start, end);
    }
  }
}

/// Builds a [CategoryBudgetEntity] for every expense category, combining the
/// stored monthly limits (scaled by [period]) with the period's spend.
class BuildCategoryBudgetsUseCase {
  const BuildCategoryBudgetsUseCase();

  List<CategoryBudgetEntity> call({
    required Map<String, double> limits,
    required List<TransactionEntity> monthTransactions,
    MoneyPeriod period = MoneyPeriod.monthly,
  }) {
    final multiplier = period.monthMultiplier;
    final spentByCategory = <String, double>{};
    for (final tx in monthTransactions.where((t) => t.isExpense)) {
      final key = tx.categoryInfo.key;
      spentByCategory[key] = (spentByCategory[key] ?? 0) + tx.amount;
    }
    return MoneyCategory.expenseCategories.map((c) {
      final baseLimit = limits[c.key] ?? 0;
      final scaledLimit = baseLimit > 0
          ? (baseLimit * multiplier).roundToDouble()
          : 0.0;
      return CategoryBudgetEntity(
        category: c.key,
        monthlyLimit: scaledLimit,
        spent: spentByCategory[c.key] ?? 0,
      );
    }).toList();
  }
}

/// Pure analytics engine for the Money module (balance trend, weekly/period
/// buckets, cashflow series, category breakdown, budget score, assets).
class ComputeMoneyInsightsUseCase {
  const ComputeMoneyInsightsUseCase();

  static const int trendDays = 14;
  static const int seriesMonths = 6;
  static const int weekBuckets = 4;

  MoneyInsights call({
    required List<TransactionEntity> transactions,
    required DateTime month,
    required List<CategoryBudgetEntity> categoryBudgets,
    required List<MoneyAccountEntity> accounts,
    MoneyPeriod period = MoneyPeriod.monthly,
    double fallbackMonthlyBudget = 0,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final selected = AppDateUtils.startOfMonth(month);

    // ── Balance & 14-day trend ────────────────────────────────────────────
    final balance = transactions.fold<double>(
      0,
      (sum, t) => sum + t.signedAmount,
    );
    final today = DateTime(clock.year, clock.month, clock.day);
    final trend = <double>[];
    for (var i = trendDays - 1; i >= 0; i--) {
      final endOfDay = today.subtract(Duration(days: i - 1)); // exclusive bound
      final value = transactions
          .where((t) => t.dateTime.isBefore(endOfDay))
          .fold<double>(0, (sum, t) => sum + t.signedAmount);
      trend.add(value);
    }
    final trendStart = trend.first;
    final balanceChange = balance - trendStart;
    final balanceChangePercent = trendStart.abs() > 0
        ? balanceChange / trendStart.abs() * 100
        : 0.0;

    // ── Active Period transactions & totals ───────────────────────────────
    final range = FilterPeriodTransactionsUseCase.periodRange(
      anchorMonth: selected,
      period: period,
      now: clock,
    );
    final periodTx = transactions
        .where(
          (t) =>
              !t.dateTime.isBefore(range.$1) && t.dateTime.isBefore(range.$2),
        )
        .toList();
    final periodIncome = _sum(periodTx.where((t) => t.isIncome));
    final periodExpense = _sum(periodTx.where((t) => t.isExpense));

    // ── Month totals (kept for backwards compatibility + monthly KPIs) ────
    final monthTx = transactions
        .where((t) => AppDateUtils.isSameMonth(t.dateTime, selected))
        .toList();
    final monthIncome = _sum(monthTx.where((t) => t.isIncome));
    final monthExpense = _sum(monthTx.where((t) => t.isExpense));

    final isCurrentMonth = AppDateUtils.isSameMonth(selected, clock);
    final isFutureMonth = selected.isAfter(AppDateUtils.startOfMonth(clock));
    final daysElapsed = switch (period) {
      MoneyPeriod.weekly => clock.weekday,
      MoneyPeriod.monthly =>
        isCurrentMonth
            ? clock.day
            : isFutureMonth
            ? 0
            : AppDateUtils.daysInMonth(selected),
      MoneyPeriod.sixMonths => 180,
      MoneyPeriod.yearly => 365,
    };
    final activeExpense = period == MoneyPeriod.monthly
        ? monthExpense
        : periodExpense;
    final avgPerDay = activeExpense / (daysElapsed > 0 ? daysElapsed : 1);

    // ── Weekly buckets for selected month ─────────────────────────────────
    final weekly = _weeklyBuckets(monthTx);
    final previousMonth = DateTime(selected.year, selected.month - 1, 1);
    final previousMonthTx = transactions
        .where((t) => AppDateUtils.isSameMonth(t.dateTime, previousMonth))
        .toList();
    final previousWeekly = _weeklyBuckets(previousMonthTx);

    final currentWeekIndex = isCurrentMonth
        ? _bucketFor(clock.day)
        : weekBuckets - 1;
    final currentWeekSpend = weekly[currentWeekIndex];
    final previousWeekSpend = currentWeekIndex > 0
        ? weekly[currentWeekIndex - 1]
        : previousWeekly[weekBuckets - 1];
    final elapsedBuckets = weekly.sublist(0, currentWeekIndex + 1);
    final avgWeekly =
        elapsedBuckets.fold<double>(0, (a, b) => a + b) / elapsedBuckets.length;
    final percentVsAverage = avgWeekly > 0
        ? (currentWeekSpend - avgWeekly) / avgWeekly * 100
        : 0.0;
    final percentVsLastWeek = previousWeekSpend > 0
        ? (currentWeekSpend - previousWeekSpend) / previousWeekSpend * 100
        : 0.0;

    // ── Period-aware grouped bar chart series ─────────────────────────────
    final periodBars = _buildPeriodBars(
      transactions: transactions,
      selectedMonth: selected,
      period: period,
      clock: clock,
      weekly: weekly,
      previousWeekly: previousWeekly,
    );

    // ── 6-month income & net series ───────────────────────────────────────
    final incomeSeries = <MonthlyValue>[];
    final netSeries = <MonthlyValue>[];
    for (var i = seriesMonths - 1; i >= 0; i--) {
      final m = DateTime(selected.year, selected.month - i, 1);
      final mTx = transactions.where(
        (t) => AppDateUtils.isSameMonth(t.dateTime, m),
      );
      final inc = _sum(mTx.where((t) => t.isIncome));
      final exp = _sum(mTx.where((t) => t.isExpense));
      incomeSeries.add(MonthlyValue(month: m, value: inc));
      netSeries.add(MonthlyValue(month: m, value: inc - exp));
    }

    // ── Category breakdown (for active period) ────────────────────────────
    final byCategory = <String, double>{};
    for (final tx in periodTx.where((t) => t.isExpense)) {
      final key = tx.categoryInfo.key;
      byCategory[key] = (byCategory[key] ?? 0) + tx.amount;
    }
    final categorySpend =
        byCategory.entries
            .where((e) => e.value > 0)
            .map(
              (e) => CategorySpend(
                category: MoneyCategory.resolve(e.key),
                amount: e.value,
                share: periodExpense > 0 ? e.value / periodExpense : 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    // ── Budget aggregates (already scaled in categoryBudgets) ─────────────
    final limited = categoryBudgets.where((b) => b.hasLimit).toList();
    final categoryLimitTotal = limited.fold<double>(
      0,
      (sum, b) => sum + b.monthlyLimit,
    );
    final scaledFallback = (fallbackMonthlyBudget * period.monthMultiplier)
        .roundToDouble();
    final totalLimit = categoryLimitTotal > 0
        ? categoryLimitTotal
        : scaledFallback;
    final overBudgetCount = limited.where((b) => b.isOverBudget).length;
    final nearLimitCount = limited.where((b) => b.isNearLimit).length;
    final budgetScore = limited.isEmpty
        ? (totalLimit > 0 && activeExpense > totalLimit ? 0 : 100)
        : ((limited.length - overBudgetCount) / limited.length * 100).round();
    final saved = (totalLimit - activeExpense).clamp(0.0, double.infinity);

    // ── Assets ────────────────────────────────────────────────────────────
    final assetsByType = <String, double>{
      for (final t in MoneyAccountType.values) t: 0,
    };
    for (final a in accounts) {
      assetsByType[a.type] = (assetsByType[a.type] ?? 0) + a.balance;
    }
    final totalAssets = accounts.fold<double>(0, (sum, a) => sum + a.balance);

    // ── Smart Spendable, Savings & AI Forecast Metrics ────────────────────
    final spentToday = _sum(
      transactions.where(
        (t) => t.isExpense && AppDateUtils.isSameDay(t.dateTime, clock),
      ),
    );
    final totalDaysInMonth = AppDateUtils.daysInMonth(selected);
    final daysRemainingInMonth = isCurrentMonth
        ? (totalDaysInMonth - clock.day + 1).clamp(1, 31)
        : (isFutureMonth ? totalDaysInMonth : 1);

    final monthlyBaseBudget = fallbackMonthlyBudget > 0
        ? fallbackMonthlyBudget
        : (totalLimit > 0 ? totalLimit / period.monthMultiplier : 40000.0);
    final spentBeforeToday = (monthExpense - spentToday).clamp(
      0.0,
      double.infinity,
    );
    final poolAtStartOfToday = (monthlyBaseBudget - spentBeforeToday).clamp(
      0.0,
      double.infinity,
    );
    final dailySafeAllowance = daysRemainingInMonth > 0
        ? poolAtStartOfToday / daysRemainingInMonth
        : 0.0;
    final canSpendToday = (dailySafeAllowance - spentToday).clamp(
      0.0,
      double.infinity,
    );

    // Weekly spend in the current ISO week (Mon..Sun)
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final isoWeekSpend = _sum(
      transactions.where(
        (t) =>
            t.isExpense &&
            !t.dateTime.isBefore(startOfWeek) &&
            t.dateTime.isBefore(endOfWeek),
      ),
    );
    final weeklyBudgetCap = monthlyBaseBudget / 4.0;
    final canSpendThisWeek = (weeklyBudgetCap - isoWeekSpend).clamp(
      0.0,
      double.infinity,
    );
    final canSpendThisMonth = (monthlyBaseBudget - monthExpense).clamp(
      0.0,
      double.infinity,
    );

    // True Savings = Income − Expense (or vs Budget if no income logged yet)
    final effectiveMonthlyIncome = monthIncome > 0
        ? monthIncome
        : monthlyBaseBudget;
    final actualSaved = (effectiveMonthlyIncome - monthExpense).clamp(
      0.0,
      double.infinity,
    );
    final savingsRatePercent = effectiveMonthlyIncome > 0
        ? ((effectiveMonthlyIncome - monthExpense) /
                  effectiveMonthlyIncome *
                  100)
              .clamp(-100.0, 100.0)
        : 0.0;

    // Pace-adjusted End-of-Month Forecast
    final monthDaysElapsed = isCurrentMonth
        ? clock.day.clamp(1, totalDaysInMonth)
        : totalDaysInMonth;
    final dailyBurnRate = monthExpense / monthDaysElapsed;
    final projectedMonthSpend = isCurrentMonth
        ? (monthExpense + dailyBurnRate * (totalDaysInMonth - clock.day))
              .roundToDouble()
        : monthExpense;
    final projectedMonthSavings =
        (effectiveMonthlyIncome - projectedMonthSpend);

    // Composite AI Financial Health Score (0..100)
    final adherencePoints = (budgetScore * 0.40).round(); // max 40
    final savingsPoints = ((savingsRatePercent.clamp(0.0, 25.0) / 20.0) * 30.0)
        .round()
        .clamp(0, 30); // max 30
    final paceRatio = monthlyBaseBudget > 0
        ? projectedMonthSpend / monthlyBaseBudget
        : 0.5;
    final pacePoints = paceRatio <= 0.85
        ? 20
        : paceRatio <= 1.0
        ? 14
        : paceRatio <= 1.15
        ? 7
        : 0; // max 20
    final bufferPoints = overBudgetCount == 0
        ? 10
        : (10 - overBudgetCount * 3).clamp(0, 10);
    final aiHealthScore =
        (adherencePoints + savingsPoints + pacePoints + bufferPoints).clamp(
          0,
          100,
        );

    final aiForecastSummary = _buildAiForecastSummary(
      projectedMonthSpend: projectedMonthSpend,
      monthlyBaseBudget: monthlyBaseBudget,
      projectedMonthSavings: projectedMonthSavings,
      dailySafeAllowance: dailySafeAllowance,
      daysRemainingInMonth: daysRemainingInMonth,
    );

    final aiInsights = _buildAiInsights(
      categorySpend: categorySpend,
      categoryBudgets: categoryBudgets,
      previousMonthTx: previousMonthTx,
      spentToday: spentToday,
      dailySafeAllowance: dailySafeAllowance,
      projectedMonthSpend: projectedMonthSpend,
      monthlyBaseBudget: monthlyBaseBudget,
      savingsRatePercent: savingsRatePercent,
    );

    return MoneyInsights(
      month: selected,
      period: period,
      balance: balance,
      balanceTrend: trend,
      balanceChange: balanceChange,
      balanceChangePercent: balanceChangePercent,
      monthIncome: monthIncome,
      monthExpense: monthExpense,
      transactionCount: periodTx.length,
      daysElapsed: daysElapsed,
      avgPerDay: avgPerDay,
      periodIncome: periodIncome,
      periodExpense: periodExpense,
      periodLimit: totalLimit,
      periodBarLabels: periodBars.labels,
      periodCurrentBars: periodBars.current,
      periodPreviousBars: periodBars.previous,
      periodCurrentLegend: periodBars.currentLegend,
      periodPreviousLegend: periodBars.previousLegend,
      weeklySpend: weekly,
      previousWeeklySpend: previousWeekly,
      currentWeekIndex: currentWeekIndex,
      currentWeekSpend: currentWeekSpend,
      previousWeekSpend: previousWeekSpend,
      percentVsAverage: percentVsAverage,
      percentVsLastWeek: percentVsLastWeek,
      incomeSeries: incomeSeries,
      netSeries: netSeries,
      categorySpend: categorySpend,
      totalLimit: totalLimit,
      saved: saved,
      budgetScore: budgetScore,
      overBudgetCount: overBudgetCount,
      nearLimitCount: nearLimitCount,
      totalAssets: totalAssets,
      assetsByType: assetsByType,
      spentToday: spentToday,
      dailySafeAllowance: dailySafeAllowance,
      canSpendToday: canSpendToday,
      canSpendThisWeek: canSpendThisWeek,
      canSpendThisMonth: canSpendThisMonth,
      actualSaved: actualSaved,
      savingsRatePercent: savingsRatePercent,
      projectedMonthSpend: projectedMonthSpend,
      projectedMonthSavings: projectedMonthSavings,
      daysRemainingInMonth: daysRemainingInMonth,
      aiHealthScore: aiHealthScore,
      aiForecastSummary: aiForecastSummary,
      aiInsights: aiInsights,
    );
  }

  static String _buildAiForecastSummary({
    required double projectedMonthSpend,
    required double monthlyBaseBudget,
    required double projectedMonthSavings,
    required double dailySafeAllowance,
    required int daysRemainingInMonth,
  }) {
    if (monthlyBaseBudget <= 0) {
      return 'Set a monthly budget or salary plan to unlock AI spend forecasting.';
    }
    if (projectedMonthSpend > monthlyBaseBudget) {
      final overrun = (projectedMonthSpend - monthlyBaseBudget).round();
      return 'At your current pace, month-end spend is projected to exceed budget by $overrun. Keep daily spend under ${dailySafeAllowance.round()}/day for the next $daysRemainingInMonth days.';
    }
    final headroom = (monthlyBaseBudget - projectedMonthSpend).round();
    return 'On track to finish $headroom under budget with ${projectedMonthSavings > 0 ? projectedMonthSavings.round() : 0} in projected savings ($daysRemainingInMonth days left).';
  }

  static List<AiFinancialInsight> _buildAiInsights({
    required List<CategorySpend> categorySpend,
    required List<CategoryBudgetEntity> categoryBudgets,
    required List<TransactionEntity> previousMonthTx,
    required double spentToday,
    required double dailySafeAllowance,
    required double projectedMonthSpend,
    required double monthlyBaseBudget,
    required double savingsRatePercent,
  }) {
    final list = <AiFinancialInsight>[];

    // 1. Today's velocity insight
    if (dailySafeAllowance > 0 && spentToday > dailySafeAllowance) {
      final over = (spentToday - dailySafeAllowance).round();
      list.add(
        AiFinancialInsight(
          id: 'daily_over',
          title: 'Today\'s Safe Limit Exceeded',
          description:
              'You spent ${spentToday.round()} today vs your ${dailySafeAllowance.round()} daily allowance. Aim for a low-spend day tomorrow.',
          impactLabel: 'Over by $over',
          severity: 'warning',
        ),
      );
    } else if (dailySafeAllowance > 0) {
      final remainingToday = (dailySafeAllowance - spentToday)
          .clamp(0, double.infinity)
          .round();
      list.add(
        AiFinancialInsight(
          id: 'daily_safe',
          title: 'Daily Pace Is Healthy',
          description:
              'You still have $remainingToday safe to spend today without affecting your month-end savings goal.',
          impactLabel: '$remainingToday left today',
          severity: 'positive',
        ),
      );
    }

    // 2. Category anomaly vs previous month or budget limit
    final prevByCat = <String, double>{};
    for (final tx in previousMonthTx.where((t) => t.isExpense)) {
      final key = tx.categoryInfo.key;
      prevByCat[key] = (prevByCat[key] ?? 0) + tx.amount;
    }

    final overCat = categoryBudgets.where((b) => b.isOverBudget).firstOrNull;
    if (overCat != null) {
      final overAmt = (overCat.spent - overCat.monthlyLimit).round();
      list.add(
        AiFinancialInsight(
          id: 'cat_over_${overCat.category}',
          title: '${overCat.categoryInfo.label} Is Over Budget',
          description:
              'Rebalance $overAmt from under-utilized categories or pause ${overCat.categoryInfo.label} purchases this week.',
          impactLabel: '+$overAmt over',
          severity: 'critical',
          categoryKey: overCat.category,
        ),
      );
    } else if (categorySpend.isNotEmpty) {
      final topFlex = categorySpend
          .where((c) => c.category.key != MoneyCategory.bills.key)
          .firstOrNull;
      if (topFlex != null && topFlex.amount > 0) {
        final save15 = (topFlex.amount * 0.15).round();
        list.add(
          AiFinancialInsight(
            id: 'trim_${topFlex.category.key}',
            title: 'Smart Save in ${topFlex.category.label}',
            description:
                '${topFlex.category.label} is ${(topFlex.share * 100).round()}% of your spend. Trimming 15% unlocks $save15/month (${save15 * 12}/year).',
            impactLabel: 'Save +$save15/mo',
            severity: 'info',
            categoryKey: topFlex.category.key,
          ),
        );
      }
    }

    // 3. Savings rate coaching
    if (savingsRatePercent >= 20) {
      list.add(
        AiFinancialInsight(
          id: 'savings_goal_met',
          title: 'Strong ${savingsRatePercent.round()}% Savings Rate',
          description:
              'You are beating the 20% benchmark. Consider sweeping surplus cash into your Investment account.',
          impactLabel: '${savingsRatePercent.round()}% Saved',
          severity: 'positive',
        ),
      );
    } else {
      list.add(
        AiFinancialInsight(
          id: 'savings_boost',
          title: 'Boost Monthly Savings Toward 20%',
          description:
              'Current savings rate is ${savingsRatePercent.clamp(0, 100).round()}%. Apply the 50/30/20 Smart Plan to automate your 20% savings bucket.',
          impactLabel: 'Target 20%',
          severity: 'info',
        ),
      );
    }

    return list;
  }

  static ({
    List<String> labels,
    List<double> current,
    List<double> previous,
    String currentLegend,
    String previousLegend,
  })
  _buildPeriodBars({
    required List<TransactionEntity> transactions,
    required DateTime selectedMonth,
    required MoneyPeriod period,
    required DateTime clock,
    required List<double> weekly,
    required List<double> previousWeekly,
  }) {
    switch (period) {
      case MoneyPeriod.weekly:
        const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final today = DateTime(clock.year, clock.month, clock.day);
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final prevStart = startOfWeek.subtract(const Duration(days: 7));
        final curr = List<double>.filled(7, 0);
        final prev = List<double>.filled(7, 0);
        for (final tx in transactions.where((t) => t.isExpense)) {
          final d = DateTime(
            tx.dateTime.year,
            tx.dateTime.month,
            tx.dateTime.day,
          );
          final diffCurr = d.difference(startOfWeek).inDays;
          if (diffCurr >= 0 && diffCurr < 7) curr[diffCurr] += tx.amount;
          final diffPrev = d.difference(prevStart).inDays;
          if (diffPrev >= 0 && diffPrev < 7) prev[diffPrev] += tx.amount;
        }
        return (
          labels: labels,
          current: curr,
          previous: prev,
          currentLegend: 'This week',
          previousLegend: 'Last week',
        );

      case MoneyPeriod.monthly:
        return (
          labels: const ['W1', 'W2', 'W3', 'W4'],
          current: weekly,
          previous: previousWeekly,
          currentLegend: 'This month',
          previousLegend: 'Last month',
        );

      case MoneyPeriod.sixMonths:
        final labels = <String>[];
        final curr = <double>[];
        final prev = <double>[];
        for (var i = 5; i >= 0; i--) {
          final m = DateTime(selectedMonth.year, selectedMonth.month - i, 1);
          final pm = DateTime(
            selectedMonth.year,
            selectedMonth.month - i - 6,
            1,
          );
          labels.add(AppDateUtils.formatMonthShort(m));
          curr.add(
            _sum(
              transactions.where(
                (t) => t.isExpense && AppDateUtils.isSameMonth(t.dateTime, m),
              ),
            ),
          );
          prev.add(
            _sum(
              transactions.where(
                (t) => t.isExpense && AppDateUtils.isSameMonth(t.dateTime, pm),
              ),
            ),
          );
        }
        return (
          labels: labels,
          current: curr,
          previous: prev,
          currentLegend: 'Last 6 months',
          previousLegend: 'Prior 6 months',
        );

      case MoneyPeriod.yearly:
        const labels = ['Q1', 'Q2', 'Q3', 'Q4'];
        final curr = List<double>.filled(4, 0);
        final prev = List<double>.filled(4, 0);
        final year = selectedMonth.year;
        for (final tx in transactions.where((t) => t.isExpense)) {
          final q = (tx.dateTime.month - 1) ~/ 3;
          if (tx.dateTime.year == year) curr[q] += tx.amount;
          if (tx.dateTime.year == year - 1) prev[q] += tx.amount;
        }
        return (
          labels: labels,
          current: curr,
          previous: prev,
          currentLegend: '$year',
          previousLegend: '${year - 1}',
        );
    }
  }

  static int _bucketFor(int day) {
    final index = (day - 1) ~/ 7;
    return index >= weekBuckets ? weekBuckets - 1 : index;
  }

  static List<double> _weeklyBuckets(List<TransactionEntity> monthTx) {
    final buckets = List<double>.filled(weekBuckets, 0);
    for (final tx in monthTx.where((t) => t.isExpense)) {
      buckets[_bucketFor(tx.dateTime.day)] += tx.amount;
    }
    return buckets;
  }

  static double _sum(Iterable<TransactionEntity> items) =>
      items.fold<double>(0, (sum, t) => sum + t.amount);
}
