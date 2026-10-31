import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/money_category.dart';
import '../../domain/entities/money_insights.dart';
import '../bloc/money_bloc.dart';

/// Interactive Salary & Smart Budget Planner card used in [MoneyBudgetsPage]
/// and [SalaryPlanSetupSheet].
///
/// Lets the user enter their Salary / Income and Fixed Bills, pick a preset
/// (`50/30/20 Balanced`, `60/20/20 Essentials`, `45/20/35 Super Saver`),
/// inspect the calculated Daily, 7-Day, Monthly, 6-Month, and Yearly plan, and
/// apply it across all category limits in one tap.
class SalaryPlanAllocatorCard extends StatefulWidget {
  final BudgetPlanPreset preset;
  final MoneyPeriod period;
  final double initialSalary;
  final double initialFixedBills;
  final bool isDark;
  final ValueChanged<BudgetPlanPreset> onSelectPreset;
  final void Function(double salary, double fixedBills, bool logSalaryIncome)
  onApplyPlan;

  const SalaryPlanAllocatorCard({
    super.key,
    required this.preset,
    required this.period,
    required this.initialSalary,
    required this.initialFixedBills,
    required this.isDark,
    required this.onSelectPreset,
    required this.onApplyPlan,
  });

  @override
  State<SalaryPlanAllocatorCard> createState() =>
      _SalaryPlanAllocatorCardState();
}

class _SalaryPlanAllocatorCardState extends State<SalaryPlanAllocatorCard> {
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _billsCtrl;
  bool _showSalaryInputs = true;
  bool _logAsIncome = false;

  static const List<double> _quickSalaries = [
    25000,
    40000,
    60000,
    80000,
    100000,
  ];

  @override
  void initState() {
    super.initState();
    final baseSalary = widget.initialSalary > 0
        ? widget.initialSalary
        : 50000.0;
    _salaryCtrl = TextEditingController(text: baseSalary.toStringAsFixed(0));
    _billsCtrl = TextEditingController(
      text: widget.initialFixedBills.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _salaryCtrl.dispose();
    _billsCtrl.dispose();
    super.dispose();
  }

  double get _enteredSalary {
    final parsed = double.tryParse(_salaryCtrl.text.replaceAll(',', '').trim());
    if (parsed != null && parsed > 0) return parsed;
    return widget.initialSalary > 0 ? widget.initialSalary : 50000.0;
  }

  double get _enteredBills {
    final parsed = double.tryParse(_billsCtrl.text.replaceAll(',', '').trim());
    if (parsed != null && parsed >= 0) return parsed;
    return widget.initialFixedBills;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final preset = widget.preset;
    final period = widget.period;
    final salary = _enteredSalary;
    final bills = _enteredBills;

    final periodPool = salary * period.monthMultiplier;
    final needsAmount = periodPool * preset.needsShare;
    final wantsAmount = periodPool * preset.wantsShare;
    final savingsAmount = periodPool * preset.savingsShare;

    // Spendable monthly budget (Needs + Wants) and daily / 7-day safe caps
    final monthlySpendable = salary * (preset.needsShare + preset.wantsShare);
    final discretionaryAfterBills = (monthlySpendable - bills).clamp(
      0.0,
      double.infinity,
    );
    final dailySafe = discretionaryAfterBills / 30.0;
    final weeklySafe = dailySafe * 7.0;
    final yearlySavings = salary * preset.savingsShare * 12.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title + Enter Salary Toggle + Apply Plan Button
          Row(
            children: [
              const Icon(
                Icons.auto_graph_rounded,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Salary & Smart Plan (${period.label})',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
              InkWell(
                onTap: () =>
                    setState(() => _showSalaryInputs = !_showSalaryInputs),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showSalaryInputs ? 'Hide Input' : 'Set Salary',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => widget.onApplyPlan(salary, bills, _logAsIncome),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Apply Plan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Collapsible Salary & Fixed Bills Input Panel
          if (_showSalaryInputs) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceMuted
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CompactAmountField(
                          controller: _salaryCtrl,
                          label: 'Monthly Salary / Income',
                          isDark: isDark,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CompactAmountField(
                          controller: _billsCtrl,
                          label: 'Fixed Bills (Rent/EMI)',
                          isDark: isDark,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickSalaries.map((amt) {
                        final isSelected = (salary - amt).abs() < 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _salaryCtrl.text = amt.toStringAsFixed(0);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.darkSurface
                                          : Colors.white),
                                borderRadius: AppRadius.radiusFull,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.darkBorder
                                            : AppColors.border),
                                ),
                              ),
                              child: Text(
                                CurrencyUtils.compact(amt),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => setState(() => _logAsIncome = !_logAsIncome),
                    child: Row(
                      children: [
                        Icon(
                          _logAsIncome
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 16,
                          color: _logAsIncome
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.textMuted),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Also record ${CurrencyUtils.format(salary)} as this month\'s Salary Income',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Preset selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BudgetPlanPreset.values.map((p) {
                final selected = p == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => widget.onSelectPreset(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : (isDark
                                  ? AppColors.darkSurfaceMuted
                                  : AppColors.surfaceElevated),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        p.title,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Needs / Wants / Savings breakdown strip for the selected period
          Row(
            children: [
              Expanded(
                child: _PlanBucketTile(
                  label: 'Needs (${(preset.needsShare * 100).round()}%)',
                  amount: CurrencyUtils.format(needsAmount),
                  color: AppColors.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PlanBucketTile(
                  label: 'Wants (${(preset.wantsShare * 100).round()}%)',
                  amount: CurrencyUtils.format(wantsAmount),
                  color: AppColors.moduleTime,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PlanBucketTile(
                  label: 'Savings (${(preset.savingsShare * 100).round()}%)',
                  amount: CurrencyUtils.format(savingsAmount),
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Daily / 7-Day / Yearly Savings Recommendation Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceMuted
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniPlanMetric(
                  label: 'Daily Safe Cap',
                  value: '${CurrencyUtils.format(dailySafe)}/d',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                _MiniPlanMetric(
                  label: '7-Day Budget',
                  value: '${CurrencyUtils.format(weeklySafe)}/wk',
                  color: AppColors.moduleTime,
                  isDark: isDark,
                ),
                _MiniPlanMetric(
                  label: '1-Yr Savings',
                  value: CurrencyUtils.compact(yearlySavings),
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _CompactAmountField({
    required this.controller,
    required this.label,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          height: 34,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              prefixText: '${CurrencyUtils.symbol} ',
              prefixStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanBucketTile extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final bool isDark;

  const _PlanBucketTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPlanMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniPlanMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Comprehensive Budget & Expense Report card showing:
/// 1. Where money is spent most (top category leaks + % of budget).
/// 2. How much savings the user is achieving (actual vs target savings + rate).
/// 3. Concrete, personalized suggestions on how to improve the budget & save more.
class BudgetExpenseReportCard extends StatelessWidget {
  final MoneyLoaded state;
  final double spentToday;
  final VoidCallback? onOpenSalaryPlan;

  const BudgetExpenseReportCard({
    super.key,
    required this.state,
    this.spentToday = 0,
    this.onOpenSalaryPlan,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final insights = state.insights;
    final period = state.selectedPeriod;
    final effectiveIncome = insights.periodIncome > 0
        ? insights.periodIncome
        : state.budget.monthlyBudget * period.monthMultiplier;
    final actualSaved = (effectiveIncome - insights.periodExpense).clamp(
      0.0,
      double.infinity,
    );
    final savingsRate = effectiveIncome > 0
        ? (actualSaved / effectiveIncome * 100).clamp(0.0, 100.0)
        : 0.0;
    final targetSavings = effectiveIncome * 0.20;
    final topCategories = insights.categorySpend.take(3).toList();
    final overCategories = state.categoryBudgets
        .where((b) => b.isOverBudget)
        .toList();
    final suggestions = _buildActionableSuggestions(
      state: state,
      spentToday: spentToday,
      effectiveIncome: effectiveIncome,
      actualSaved: actualSaved,
      targetSavings: targetSavings,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget & Savings Report (${period.label})',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Where you spend most · Savings · How to improve',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (insights.budgetScore >= 75
                              ? AppColors.success
                              : insights.budgetScore >= 50
                              ? AppColors.warning
                              : AppColors.error)
                          .withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  'Score ${insights.budgetScore}/100',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: insights.budgetScore >= 75
                        ? AppColors.success
                        : insights.budgetScore >= 50
                        ? AppColors.warning
                        : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. How Much Savings I Am Doing
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceMuted
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _ReportMetricTile(
                    label: 'Actual Saved',
                    value: CurrencyUtils.format(actualSaved),
                    subtitle: '${savingsRate.toStringAsFixed(0)}% of income',
                    color: AppColors.success,
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: _ReportMetricTile(
                      label: 'Target (20%)',
                      value: CurrencyUtils.format(targetSavings),
                      subtitle: actualSaved >= targetSavings
                          ? 'Goal achieved'
                          : 'Gap: ${CurrencyUtils.format(targetSavings - actualSaved)}',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: _ReportMetricTile(
                      label: 'Daily Avg Spend',
                      value: CurrencyUtils.format(insights.avgPerDay),
                      subtitle:
                          'Safe: ${CurrencyUtils.format(state.budget.dailySafeSpend)}/d',
                      color: insights.avgPerDay > state.budget.dailySafeSpend
                          ? AppColors.warning
                          : AppColors.moduleTime,
                      isDark: isDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Where You Are Spending Money Most
          if (topCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'WHERE YOU SPEND THE MOST',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            ...topCategories.map((cs) {
              final catBudget = state.categoryBudgets
                  .where((b) => b.category == cs.category.key)
                  .firstOrNull;
              final pctOfTotal = (cs.share * 100).round();
              final isOver = catBudget?.isOverBudget ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(cs.category.icon, size: 15, color: cs.category.color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cs.category.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isOver && catBudget != null)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: AppRadius.radiusXs,
                        ),
                        child: Text(
                          'Over by ${CurrencyUtils.format(catBudget.spent - catBudget.monthlyLimit)}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    Text(
                      '${CurrencyUtils.format(cs.amount)} ($pctOfTotal%)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // 3. How to Improve Budget & Save Money
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HOW TO IMPROVE & SAVE MORE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              if (overCategories.isNotEmpty)
                Text(
                  '${overCategories.length} over limit',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ...suggestions.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: tip.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tip.color.withValues(alpha: 0.22)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(tip.icon, size: 15, color: tip.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            tip.body,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.3,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<_CoachSuggestion> _buildActionableSuggestions({
    required MoneyLoaded state,
    required double spentToday,
    required double effectiveIncome,
    required double actualSaved,
    required double targetSavings,
  }) {
    final tips = <_CoachSuggestion>[];
    final dailyLimit = state.budget.dailySafeSpend;

    // 1. Daily budget alert or daily buffer suggestion
    if (dailyLimit > 0 && spentToday > dailyLimit) {
      tips.add(
        _CoachSuggestion(
          icon: Icons.warning_amber_rounded,
          color: AppColors.error,
          title:
              'Daily Alert: Over today\'s limit by ${CurrencyUtils.format(spentToday - dailyLimit)}',
          body:
              'Try a zero-spend day tomorrow to bring your 7-day average back under ${CurrencyUtils.format(dailyLimit)}/day.',
        ),
      );
    } else if (dailyLimit > 0) {
      final dailyBuffer = (dailyLimit * 0.15).roundToDouble();
      tips.add(
        _CoachSuggestion(
          icon: Icons.shield_outlined,
          color: AppColors.success,
          title:
              'Daily Rule: Save ${CurrencyUtils.format(dailyBuffer)}/day from your daily cap',
          body:
              'Spending ${CurrencyUtils.format(dailyLimit - dailyBuffer)} instead of ${CurrencyUtils.format(dailyLimit)}/day adds ${CurrencyUtils.format(dailyBuffer * 30)}/mo (${CurrencyUtils.compact(dailyBuffer * 365)}/yr) to savings.',
        ),
      );
    }

    // 2. Top non-bill spending category optimization
    final nonBillTop = state.insights.categorySpend
        .where((c) => c.category.key != MoneyCategory.bills.key)
        .firstOrNull;
    if (nonBillTop != null && nonBillTop.amount > 0) {
      final trim15 = (nonBillTop.amount * 0.15).roundToDouble();
      tips.add(
        _CoachSuggestion(
          icon: Icons.trending_down_rounded,
          color: AppColors.moduleTime,
          title:
              'Trim ${nonBillTop.category.label} by 15% (+${CurrencyUtils.format(trim15)} saved)',
          body:
              '${nonBillTop.category.label} is your biggest flexible expense (${CurrencyUtils.format(nonBillTop.amount)}). Cutting 15% saves ${CurrencyUtils.compact(trim15 * 12)}/year.',
        ),
      );
    }

    // 3. Subscriptions / Auto-Kill suggestion or Savings gap suggestion
    final unkilledSubs = state.subscriptions
        .where((s) => !s.autoKillEnabled)
        .toList();
    if (unkilledSubs.isNotEmpty) {
      final subTotal = unkilledSubs.fold<double>(0, (s, e) => s + e.amount);
      tips.add(
        _CoachSuggestion(
          icon: Icons.autorenew_rounded,
          color: AppColors.primary,
          title:
              'Audit ${unkilledSubs.length} subscription(s) (${CurrencyUtils.format(subTotal)}/mo)',
          body:
              'Enable Auto-Kill on unused renewals to save up to ${CurrencyUtils.format(subTotal * 12)}/year automatically.',
        ),
      );
    } else if (actualSaved < targetSavings) {
      final gap = targetSavings - actualSaved;
      tips.add(
        _CoachSuggestion(
          icon: Icons.savings_outlined,
          color: AppColors.primary,
          title:
              'Pay Yourself First: Auto-transfer ${CurrencyUtils.format(targetSavings)}',
          body:
              'Move 20% of your salary to Savings on payday to close the ${CurrencyUtils.format(gap)} savings gap.',
        ),
      );
    }

    return tips;
  }
}

class _ReportMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final bool isDark;

  const _ReportMetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 1),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9.5,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CoachSuggestion {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _CoachSuggestion({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

/// Modal sheet that lets the user enter their Salary & Fixed Bills from
/// anywhere in the Money module (e.g. Overview Dashboard) and apply a smart plan.
class SalaryPlanSetupSheet extends StatefulWidget {
  final MoneyLoaded state;

  const SalaryPlanSetupSheet({super.key, required this.state});

  static Future<void> show(BuildContext context, {required MoneyLoaded state}) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: SalaryPlanSetupSheet(state: state),
      ),
    );
  }

  @override
  State<SalaryPlanSetupSheet> createState() => _SalaryPlanSetupSheetState();
}

class _SalaryPlanSetupSheetState extends State<SalaryPlanSetupSheet> {
  BudgetPlanPreset _preset = BudgetPlanPreset.standard503020;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = widget.state;
    final baseSalary = state.insights.monthIncome > 0
        ? state.insights.monthIncome
        : state.budget.monthlyBudget;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.topXl,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: AppRadius.radiusFull,
              ),
            ),
            const SizedBox(height: 12),
            SalaryPlanAllocatorCard(
              preset: _preset,
              period: state.selectedPeriod,
              initialSalary: baseSalary,
              initialFixedBills: state.budget.fixedBills,
              isDark: isDark,
              onSelectPreset: (p) => setState(() => _preset = p),
              onApplyPlan: (salary, fixedBills, logSalaryIncome) {
                final bloc = context.read<MoneyBloc>();
                bloc.add(
                  ApplyBudgetPlan(
                    preset: _preset,
                    monthlyBudget: salary,
                    fixedBills: fixedBills,
                  ),
                );
                if (logSalaryIncome) {
                  bloc.add(
                    AddTransaction(
                      title: 'Monthly Salary',
                      category: MoneyCategory.salary.key,
                      amount: salary,
                      mode: 'Bank',
                      iconCodePoint: MoneyCategory.salary.icon.codePoint,
                      type: 'income',
                    ),
                  );
                }
                Navigator.of(context).pop();
                SnackbarUtils.showSuccess(
                  context,
                  'Salary plan (${_preset.title}) applied!',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
