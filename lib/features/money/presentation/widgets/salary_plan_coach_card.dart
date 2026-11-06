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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
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

/// Comprehensive AI-Powered Budget, Forecast & Savings Coach card showing:
/// 1. AI Financial Health Score & End-of-Month Spend Forecast.
/// 2. Where money is spent most (top category leaks + % of budget).
/// 3. How much savings the user is achieving (actual vs target savings + rate).
/// 4. Concrete, personalized AI recommendations + 1-tap Auto-Rebalance & Affordability Simulator.
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
    final dailyAllowance = state.budget.dailyAllowanceForToday(spentToday);
    final suggestions = _buildActionableSuggestions(
      state: state,
      spentToday: spentToday,
      dailyAllowance: dailyAllowance,
      effectiveIncome: effectiveIncome,
      actualSaved: actualSaved,
      targetSavings: targetSavings,
    );

    final score = insights.aiHealthScore;
    final scoreColor = score >= 75
        ? AppColors.success
        : score >= 50
        ? AppColors.warning
        : AppColors.error;

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
          // Header: AI Financial Coach + Score Pill (Spacious, Zero Crowding)
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
                  Icons.auto_awesome_rounded,
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
                      'AI Coach & Savings Report (${period.label})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Spend forecast · Savings rate · Smart optimizations',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  'AI $score/100',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick AI Action Bar: Can I Afford a Purchase? | Set Salary & Plan
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => AiAffordabilitySheet.show(context, state: state),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Can I Afford This? (AI Check)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (onOpenSalaryPlan != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onOpenSalaryPlan,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          size: 14,
                          color: AppColors.success,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Salary Plan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // AI End-of-Month Forecast Strip
          if (insights.aiForecastSummary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(
                  alpha: isDark ? 0.14 : 0.06,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.psychology_alt_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'AI Month-End Forecast',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Est. ${CurrencyUtils.format(insights.projectedMonthSpend)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color:
                                    insights.projectedMonthSpend >
                                        state.budget.monthlyBudget
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          insights.aiForecastSummary,
                          style: TextStyle(
                            fontSize: 10.5,
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
            const SizedBox(height: 10),
          ],

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
                          'Safe: ${CurrencyUtils.format(dailyAllowance)}/d',
                      color: insights.avgPerDay > dailyAllowance
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
                'AI RECOMMENDATIONS & ACTIONS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                ),
              ),
              if (overCategories.isNotEmpty)
                InkWell(
                  onTap: () => _rebalanceOverCategories(context, state),
                  borderRadius: AppRadius.radiusFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Text(
                      'Auto-Fix ${overCategories.length} Over Limit',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
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

  static void _rebalanceOverCategories(
    BuildContext context,
    MoneyLoaded state,
  ) {
    final bloc = context.read<MoneyBloc>();
    final multiplier = state.selectedPeriod.monthMultiplier;
    for (final catBudget in state.categoryBudgets.where(
      (b) => b.isOverBudget,
    )) {
      // Round up to nearest 500 with a 10% buffer so the category is back on track
      final neededPeriodLimit = (catBudget.spent * 1.10 / 500).ceil() * 500.0;
      final monthlyLimit = (neededPeriodLimit / multiplier).roundToDouble();
      bloc.add(SetCategoryLimit(catBudget.category, monthlyLimit));
    }
    SnackbarUtils.showSuccess(
      context,
      'AI rebalanced over-limit categories with a 10% safety buffer!',
    );
  }

  static List<_CoachSuggestion> _buildActionableSuggestions({
    required MoneyLoaded state,
    required double spentToday,
    required double dailyAllowance,
    required double effectiveIncome,
    required double actualSaved,
    required double targetSavings,
  }) {
    final tips = <_CoachSuggestion>[];
    final dailyLimit = dailyAllowance > 0
        ? dailyAllowance
        : state.budget.dailySafeSpend;

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
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            subtitle,
            maxLines: 1,
            style: TextStyle(
              fontSize: 9.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
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

/// Interactive AI Purchase Affordability & What-If Simulator Sheet.
///
/// Evaluates any planned purchase against:
/// 1. Today's Safe-to-Spend allowance
/// 2. Selected Category Budget limit
/// 3. Remaining Monthly Budget & Savings Goal
/// And provides a clear verdict (`Safe to Buy`, `Stretch`, or `Delay Purchase`)
/// with a 1-tap option to log the expense.
class AiAffordabilitySheet extends StatefulWidget {
  final MoneyLoaded state;

  const AiAffordabilitySheet({super.key, required this.state});

  static Future<void> show(BuildContext context, {required MoneyLoaded state}) {
    final bloc = context.read<MoneyBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: AiAffordabilitySheet(state: state),
      ),
    );
  }

  @override
  State<AiAffordabilitySheet> createState() => _AiAffordabilitySheetState();
}

class _AiAffordabilitySheetState extends State<AiAffordabilitySheet> {
  static const List<double> _quickAmounts = [500, 1500, 3000, 5000, 10000];
  late final TextEditingController _amountCtrl;
  late final TextEditingController _itemCtrl;
  String _categoryKey = MoneyCategory.shopping.key;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: '1500');
    _itemCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _itemCtrl.dispose();
    super.dispose();
  }

  double get _purchaseAmount {
    final v = double.tryParse(_amountCtrl.text.replaceAll(',', '').trim());
    return (v != null && v > 0) ? v : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = widget.state;
    final insights = state.insights;
    final amount = _purchaseAmount;
    final cat = MoneyCategory.resolve(_categoryKey);
    final catBudget = state.categoryBudgets
        .where((b) => b.category == _categoryKey)
        .firstOrNull;

    final dailyCap = state.budget.dailyAllowanceForToday(insights.spentToday);
    final leftTodayBefore = (dailyCap - insights.spentToday).clamp(
      0.0,
      double.infinity,
    );
    final leftTodayAfter = leftTodayBefore - amount;

    final catLimit = catBudget?.monthlyLimit ?? 0.0;
    final catSpentBefore = catBudget?.spent ?? 0.0;
    final catSpentAfter = catSpentBefore + amount;
    final catOverAfter = catLimit > 0 && catSpentAfter > catLimit;

    final monthRemainingBefore = state.budget.remainingSpendable;
    final monthRemainingAfter = monthRemainingBefore - amount;
    final daysLeft = state.budget.daysRemaining;
    final newDailyAllowance = daysLeft > 1
        ? ((monthRemainingBefore - amount).clamp(0.0, double.infinity) /
              (daysLeft - 1))
        : 0.0;

    // Determine AI Verdict
    final bool fitsToday = amount <= leftTodayBefore && !catOverAfter;
    final bool fitsMonth = amount <= monthRemainingBefore && !catOverAfter;

    final Color verdictColor = fitsToday
        ? AppColors.success
        : fitsMonth
        ? AppColors.warning
        : AppColors.error;
    final IconData verdictIcon = fitsToday
        ? Icons.verified_rounded
        : fitsMonth
        ? Icons.info_outline_rounded
        : Icons.gpp_bad_outlined;
    final String verdictTitle = fitsToday
        ? 'Safe to Buy Today'
        : fitsMonth
        ? 'Moderate Stretch — Fits Monthly Budget'
        : 'High Impact — Consider Delaying';

    final String verdictBody;
    if (fitsToday) {
      verdictBody =
          'This purchase fits comfortably inside today\'s safe allowance (${CurrencyUtils.format(leftTodayBefore)}) and leaves ${CurrencyUtils.format(leftTodayAfter.clamp(0, double.infinity))} for today.';
    } else if (fitsMonth) {
      final waitDays = dailyCap > 0 ? (amount / dailyCap).ceil() : 2;
      verdictBody =
          'Exceeds today\'s safe cap by ${CurrencyUtils.format((amount - leftTodayBefore).clamp(0, double.infinity))}, but fits your monthly budget. Your daily safe spend for the next ${daysLeft - 1} days will adjust to ${CurrencyUtils.format(newDailyAllowance)}/day (or wait $waitDays low-spend days).';
    } else {
      final overAmt = catOverAfter
          ? (catSpentAfter - catLimit)
          : (amount - monthRemainingBefore).clamp(0.0, double.infinity);
      verdictBody =
          'Pushes your ${catOverAfter ? '${cat.label} budget' : 'monthly spendable pool'} over limit by ${CurrencyUtils.format(overAmt)}. AI recommends waiting or rebalancing your budget first.';
    }

    return Container(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  borderRadius: AppRadius.radiusFull,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Purchase Affordability Check',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Simulate impact on today\'s safe spend, category & savings',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount + Item Name Inputs
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _CompactAmountField(
                    controller: _amountCtrl,
                    label: 'Planned Purchase Amount',
                    isDark: isDark,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item / Merchant (Optional)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SizedBox(
                        height: 34,
                        child: TextField(
                          controller: _itemCtrl,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'e.g. Headphones, Dinner',
                            hintStyle: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: isDark
                                ? AppColors.darkSurface
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Amount Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickAmounts.map((presetAmt) {
                  final selected = (amount - presetAmt).abs() < 1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _amountCtrl.text = presetAmt.toStringAsFixed(0),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : (isDark
                                    ? AppColors.darkSurfaceMuted
                                    : AppColors.surfaceElevated),
                          borderRadius: AppRadius.radiusFull,
                        ),
                        child: Text(
                          CurrencyUtils.format(presetAmt),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected
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
            const SizedBox(height: 10),

            // Category Selector Strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MoneyCategory.expenseCategories.map((c) {
                  final selected = c.key == _categoryKey;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _categoryKey = c.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? c.color.withValues(alpha: 0.16)
                              : (isDark
                                    ? AppColors.darkSurfaceMuted
                                    : AppColors.surfaceElevated),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected ? c.color : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(c.icon, size: 13, color: c.color),
                            const SizedBox(width: 4),
                            Text(
                              c.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? c.color
                                    : (isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // AI Verdict Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: verdictColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: verdictColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(verdictIcon, color: verdictColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          verdictTitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: verdictColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          verdictBody,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Before vs After Impact Strip
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
                      label: 'Today Left After',
                      value: CurrencyUtils.format(
                        leftTodayAfter.clamp(0, double.infinity),
                      ),
                      subtitle: 'Was ${CurrencyUtils.format(leftTodayBefore)}',
                      color: leftTodayAfter >= 0
                          ? AppColors.success
                          : AppColors.error,
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
                      padding: const EdgeInsets.only(left: 8),
                      child: _ReportMetricTile(
                        label: '${cat.label} After',
                        value: CurrencyUtils.format(catSpentAfter),
                        subtitle: catLimit > 0
                            ? 'of ${CurrencyUtils.format(catLimit)}'
                            : 'No limit set',
                        color: catOverAfter
                            ? AppColors.error
                            : AppColors.primary,
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
                      padding: const EdgeInsets.only(left: 8),
                      child: _ReportMetricTile(
                        label: 'Month Left After',
                        value: CurrencyUtils.format(
                          monthRemainingAfter.clamp(0, double.infinity),
                        ),
                        subtitle:
                            '${CurrencyUtils.format(newDailyAllowance)}/d next',
                        color: monthRemainingAfter >= 0
                            ? AppColors.moduleTime
                            : AppColors.error,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons: Close or Log Expense Now
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: amount <= 0
                        ? null
                        : () {
                            final title = _itemCtrl.text.trim().isNotEmpty
                                ? _itemCtrl.text.trim()
                                : cat.label;
                            context.read<MoneyBloc>().add(
                              AddTransaction(
                                title: title,
                                category: cat.key,
                                amount: amount,
                                mode: 'UPI',
                                iconCodePoint: cat.icon.codePoint,
                                type: 'expense',
                              ),
                            );
                            Navigator.of(context).pop();
                            SnackbarUtils.showSuccess(
                              context,
                              'Logged ${CurrencyUtils.format(amount)} in ${cat.label}',
                            );
                          },
                    icon: const Icon(Icons.check_circle_outline, size: 17),
                    label: Text('Log ${CurrencyUtils.format(amount)} Expense'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
