import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../domain/entities/category_budget_entity.dart';
import '../../domain/entities/money_category.dart';
import '../../domain/entities/money_insights.dart';
import '../bloc/money_bloc.dart';
import '../widgets/edit_limit_sheet.dart';
import '../widgets/money_section_header.dart';
import '../widgets/money_shell_scope.dart';
import '../widgets/month_picker_sheet.dart';
import '../widgets/period_selector_bar.dart';
import '../widgets/salary_plan_coach_card.dart';

/// Money Tab 2 — Budget Manager:
/// Multi-period selector (`Weekly · Monthly · 6 Months · Yearly`), Overview
/// gradient card, Smart Budget Plan allocator (`50/30/20 Rule`, `60/20/20`,
/// `45/20/35`), over/near-limit alert banner, Safe-to-Spend settings,
/// per-category limit cards with edit sheet, and Budget Tips dialog.
class MoneyBudgetsPage extends StatefulWidget {
  const MoneyBudgetsPage({super.key});

  @override
  State<MoneyBudgetsPage> createState() => _MoneyBudgetsPageState();
}

class _MoneyBudgetsPageState extends State<MoneyBudgetsPage> {
  BudgetPlanPreset _selectedPreset = BudgetPlanPreset.standard503020;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => MoneyShellScope.handleBack(context),
        ),
        titleSpacing: 0,
        title: const Text(
          StringConstants.budgetManager,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          BlocBuilder<MoneyBloc, MoneyState>(
            builder: (context, state) {
              if (state is! MoneyLoaded) return const SizedBox.shrink();
              return MonthSelectorChip(
                selectedMonth: state.selectedMonth,
                onChanged: (m) => context.read<MoneyBloc>().add(ChangeMonth(m)),
              );
            },
          ),
          IconButton(
            tooltip: StringConstants.budgetTips,
            icon: const Icon(Icons.lightbulb_outline_rounded, size: 20),
            onPressed: () => _showBudgetTipsDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<MoneyBloc, MoneyState>(
        builder: (context, state) {
          if (state is! MoneyLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final period = state.selectedPeriod;
          final budgets = state.categoryBudgets;
          final totalLimit = budgets.fold<double>(
            0,
            (s, b) => s + b.monthlyLimit,
          );
          final totalSpent = budgets.fold<double>(0, (s, b) => s + b.spent);
          final totalRemaining = (totalLimit - totalSpent).clamp(
            0.0,
            double.infinity,
          );
          final overallProgress = totalLimit > 0
              ? (totalSpent / totalLimit).clamp(0.0, 1.0)
              : 0.0;
          final overCount = budgets.where((b) => b.isOverBudget).length;
          final nearCount = budgets.where((b) => b.isNearLimit).length;
          final okCount = budgets.length - overCount;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // 1. Multi-period switcher (Weekly · Monthly · 6 Months · Yearly)
              PeriodSelectorBar(
                selected: period,
                onChanged: (p) =>
                    context.read<MoneyBloc>().add(ChangeMoneyPeriod(p)),
              ),
              const SizedBox(height: 12),

              // 2. Overview gradient card (scaled to active period)
              _BudgetOverviewCard(
                title: period.budgetTitle,
                totalBudget: totalLimit,
                totalSpent: totalSpent,
                totalRemaining: totalRemaining,
                overallProgress: overallProgress,
                okCategoriesCount: okCount,
                totalCategoriesCount: budgets.length,
                onEditBudget: () =>
                    SalaryPlanSetupSheet.show(context, state: state),
              ),
              const SizedBox(height: 12),

              // 3. Alert banner (over-budget red takes priority over near-limit orange)
              if (overCount > 0)
                _AlertBanner(
                  color: AppColors.error,
                  icon: Icons.warning_amber_rounded,
                  message: overCount == 1
                      ? '1 category has exceeded the ${period.label.toLowerCase()} limit.'
                      : '$overCount categories have exceeded the ${period.label.toLowerCase()} limit.',
                )
              else if (nearCount > 0)
                _AlertBanner(
                  color: AppColors.warning,
                  icon: Icons.notifications_active_rounded,
                  message: nearCount == 1
                      ? '1 category is approaching the ${period.label.toLowerCase()} limit.'
                      : '$nearCount categories are approaching the ${period.label.toLowerCase()} limit.',
                ),
              if (overCount > 0 || nearCount > 0) const SizedBox(height: 12),

              // 4. Salary & Smart Budget Plan Allocator (50/30/20 · 60/20/20 · 45/20/35)
              SalaryPlanAllocatorCard(
                preset: _selectedPreset,
                period: period,
                initialSalary: state.insights.monthIncome > 0
                    ? state.insights.monthIncome
                    : (state.budget.monthlyBudget > 0
                          ? state.budget.monthlyBudget
                          : 50000.0),
                initialFixedBills: state.budget.fixedBills,
                isDark: isDark,
                onSelectPreset: (p) => setState(() => _selectedPreset = p),
                onApplyPlan: (salary, fixedBills, logSalaryIncome) {
                  final bloc = context.read<MoneyBloc>();
                  bloc.add(
                    ApplyBudgetPlan(
                      preset: _selectedPreset,
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
                  SnackbarUtils.showSuccess(
                    context,
                    'Applied ${_selectedPreset.title} across all categories',
                  );
                },
              ),
              const SizedBox(height: 12),

              // 5. Budget & Savings Report (Where you spend most, Savings, How to improve)
              BudgetExpenseReportCard(
                state: state,
                spentToday: state.allTransactions
                    .where(
                      (t) =>
                          t.isExpense &&
                          AppDateUtils.isSameDay(t.dateTime, DateTime.now()),
                    )
                    .fold<double>(0, (s, t) => s + t.amount),
              ),
              const SizedBox(height: 12),

              // 5. Safe-to-Spend Settings row (existing Monthly Budget & Fixed Bills)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
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
                            StringConstants.safeSpendSettings,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${StringConstants.monthlyBudget}: ${CurrencyUtils.format(state.budget.monthlyBudget)} • '
                            '${StringConstants.fixedBills}: ${CurrencyUtils.format(state.budget.fixedBills)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => EditSafeSpendSheet.show(
                        context,
                        budget: state.budget,
                      ),
                      child: const Text(StringConstants.edit),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 6. Category Limits header + cards
              MoneySectionHeader(
                title: StringConstants.categoryLimits,
                trailing: Text(
                  '${period.shortTag} · ${StringConstants.tapToEdit}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted,
                  ),
                ),
              ),
              ...budgets.map(
                (b) => _CategoryBudgetCard(
                  budget: b,
                  isDark: isDark,
                  onTap: () {
                    final rawMonthly =
                        state.categoryLimits[b.category] ??
                        (b.monthlyLimit / period.monthMultiplier);
                    EditCategoryLimitSheet.show(
                      context,
                      budget: CategoryBudgetEntity(
                        category: b.category,
                        monthlyLimit: rawMonthly,
                        spent: b.spent,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _showBudgetTipsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_rounded, color: AppColors.moduleTime),
            SizedBox(width: 10),
            Text(StringConstants.budgetTips),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TipRow(
              title: StringConstants.budgetTipRuleTitle,
              body: StringConstants.budgetTipRuleBody,
            ),
            SizedBox(height: 12),
            _TipRow(
              title: StringConstants.budgetTipWeeklyTitle,
              body: StringConstants.budgetTipWeeklyBody,
            ),
            SizedBox(height: 12),
            _TipRow(
              title: StringConstants.budgetTipBufferTitle,
              body: StringConstants.budgetTipBufferBody,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(StringConstants.gotIt),
          ),
        ],
      ),
    );
  }
}

class _BudgetOverviewCard extends StatelessWidget {
  final String title;
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final double overallProgress;
  final int okCategoriesCount;
  final int totalCategoriesCount;
  final VoidCallback? onEditBudget;

  const _BudgetOverviewCard({
    required this.title,
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.overallProgress,
    required this.okCategoriesCount,
    required this.totalCategoriesCount,
    this.onEditBudget,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (overallProgress * 100).round();
    final barColor = overallProgress >= 1.0
        ? Colors.redAccent
        : overallProgress >= 0.85
        ? Colors.orangeAccent
        : Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AppDecorations.heroMoneyGradient.copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onEditBudget != null) ...[
                InkWell(
                  onTap: onEditBudget,
                  borderRadius: AppRadius.radiusFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Set Budget',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  '$pct% used',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.format(totalBudget),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: AppRadius.radiusFull,
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: StringConstants.spent,
                  value: CurrencyUtils.format(totalSpent),
                ),
              ),
              Container(width: 1, height: 26, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _OverviewStat(
                    label: StringConstants.remaining,
                    value: CurrencyUtils.format(totalRemaining),
                  ),
                ),
              ),
              Container(width: 1, height: 26, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _OverviewStat(
                    label: StringConstants.categoriesOk,
                    value: '$okCategoriesCount / $totalCategoriesCount OK',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;

  const _AlertBanner({
    required this.color,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBudgetCard extends StatelessWidget {
  final CategoryBudgetEntity budget;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryBudgetCard({
    required this.budget,
    required this.isDark,
    required this.onTap,
  });

  Color _statusColor() {
    switch (budget.status) {
      case BudgetStatus.overBudget:
        return AppColors.error;
      case BudgetStatus.nearLimit:
        return AppColors.warning;
      case BudgetStatus.onTrack:
      case BudgetStatus.noLimit:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = budget.categoryInfo;
    final statusColor = _statusColor();
    final barColor = budget.isOverBudget
        ? AppColors.error
        : budget.isNearLimit
        ? AppColors.warning
        : cat.color;
    final captionColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: budget.isOverBudget
              ? AppColors.error.withValues(alpha: 0.4)
              : (isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.borderLg,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(cat.icon, size: 19, color: cat.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  budget.statusLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: CurrencyUtils.format(budget.spent),
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: budget.isOverBudget
                                      ? AppColors.error
                                      : (isDark
                                            ? AppColors.darkTextPrimary
                                            : AppColors.textPrimary),
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              if (budget.hasLimit)
                                TextSpan(
                                  text:
                                      ' / ${CurrencyUtils.format(budget.monthlyLimit)}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: captionColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !budget.hasLimit
                              ? StringConstants.tapToEdit
                              : budget.isOverBudget
                              ? '-${CurrencyUtils.format(budget.overBy)} over'
                              : '${CurrencyUtils.format(budget.remaining)} left',
                          style: TextStyle(
                            fontSize: 11,
                            color: budget.isOverBudget
                                ? AppColors.error
                                : captionColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_outlined, size: 15, color: captionColor),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: budget.progress,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceMuted
                        : AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String title;
  final String body;

  const _TipRow({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                body,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
