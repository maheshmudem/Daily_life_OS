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
    );
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
