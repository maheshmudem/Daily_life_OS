import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
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
    final p = context.palette;
    final text = context.text;

    return BlocBuilder<MoneyBloc, MoneyState>(
      builder: (context, moneyState) => FeatureScaffold(
        title: StringConstants.budgetManager,
        onBack: () => MoneyShellScope.handleBack(context),
        accentColor: AppColors.moduleMoney,
        actionsEndPadding: AppSpacing.pageGutter,
        actions: [
          FeatureIconButton(
            tooltip: StringConstants.budgetTips,
            icon: Icons.lightbulb_outline_rounded,
            onPressed: () => _showBudgetTipsDialog(context),
          ),
        ],
        status: moneyFeatureStatus(moneyState),
        errorMessage: moneyState is MoneyError ? moneyState.message : null,
        onRetry: () => context.read<MoneyBloc>().add(const LoadMoney()),
        loading: const FeatureLoadingView(blockHeights: [40, 160, 88, 220]),
        builder: (context) {
          final state = moneyState as MoneyLoaded;
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: [
              // 1. Period header with month selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    'Budget Period',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: p.heading,
                    ),
                  ),
                  MonthSelectorChip(
                    selectedMonth: state.selectedMonth,
                    onChanged: (m) =>
                        context.read<MoneyBloc>().add(ChangeMonth(m)),
                  ),
                ],
              ),
              AppSpacing.gapH8,

              // 2. Multi-period switcher (Weekly · Monthly · 6 Months · Yearly)
              PeriodSelectorBar(
                selected: period,
                onChanged: (periodVal) =>
                    context.read<MoneyBloc>().add(ChangeMoneyPeriod(periodVal)),
              ),
              AppSpacing.gapH12,

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
              AppSpacing.gapH12,

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
              if (overCount > 0 || nearCount > 0) AppSpacing.gapH12,

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
                isDark: p.isDark,
                onSelectPreset: (presetVal) =>
                    setState(() => _selectedPreset = presetVal),
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
              AppSpacing.gapH12,

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
              AppSpacing.gapH12,

              // 5. Safe-to-Spend Settings row (existing Monthly Budget & Fixed Bills)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: p.border),
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
                          AppText(
                            StringConstants.safeSpendSettings,
                            style: text.labelLarge?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: p.heading,
                            ),
                          ),
                          AppText(
                            '${StringConstants.monthlyBudget}: ${CurrencyUtils.format(state.budget.monthlyBudget)} • '
                            '${StringConstants.fixedBills}: ${CurrencyUtils.format(state.budget.fixedBills)}',
                            style: text.labelSmall?.copyWith(
                              fontSize: 11,
                              color: p.secondary,
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
                      child: const AppText(StringConstants.edit),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 6. Category Limits header + cards
              MoneySectionHeader(
                title: StringConstants.categoryLimits,
                trailing: AppText(
                  '${period.shortTag} · ${StringConstants.tapToEdit}',
                  style: text.labelSmall?.copyWith(
                    fontSize: 11.5,
                    color: p.caption,
                  ),
                ),
              ),
              ...budgets.map(
                (b) => _CategoryBudgetCard(
                  budget: b,
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
    final p = context.palette;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusXl),
        title: const Row(
          children: [
            Icon(Icons.lightbulb_rounded, color: AppColors.moduleTime),
            SizedBox(width: 10),
            AppText(StringConstants.budgetTips),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TipRow(
              title: StringConstants.budgetTipRuleTitle,
              body: StringConstants.budgetTipRuleBody,
            ),
            AppSpacing.gapH12,
            _TipRow(
              title: StringConstants.budgetTipWeeklyTitle,
              body: StringConstants.budgetTipWeeklyBody,
            ),
            AppSpacing.gapH12,
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
              foregroundColor: AppColors.textWhite,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const AppText(StringConstants.gotIt),
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
    final text = context.text;
    final pct = (overallProgress * 100).round();
    final barColor = overallProgress >= 1.0
        ? AppColors.error
        : overallProgress >= 0.85
        ? AppColors.warning
        : AppColors.textWhite;

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
                child: AppText(
                  title,
                  style: text.labelMedium?.copyWith(
                    color: AppColors.white70,
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
                      color: AppColors.textWhite.withValues(alpha: 0.22),
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          size: 11,
                          color: AppColors.textWhite,
                        ),
                        AppSpacing.gapW4,
                        AppText(
                          'Set Budget',
                          style: text.labelSmall?.copyWith(
                            color: AppColors.textWhite,
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
                  color: AppColors.textWhite.withValues(alpha: 0.22),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: AppText(
                  '$pct% used',
                  style: text.labelSmall?.copyWith(
                    color: AppColors.textWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapH4,
          AppText(
            CurrencyUtils.format(totalBudget),
            style: text.headlineMedium?.copyWith(
              color: AppColors.textWhite,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          AppSpacing.gapH12,
          ClipRRect(
            borderRadius: AppRadius.radiusFull,
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 7,
              backgroundColor: AppColors.textWhite.withValues(alpha: 0.22),
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
              Container(width: 1, height: 26, color: AppColors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: _OverviewStat(
                    label: StringConstants.remaining,
                    value: CurrencyUtils.format(totalRemaining),
                  ),
                ),
              ),
              Container(width: 1, height: 26, color: AppColors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
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
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          style: text.labelSmall?.copyWith(
            color: AppColors.white70,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 2),
        AppText(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.labelMedium?.copyWith(
            color: AppColors.textWhite,
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
            child: AppText(
              message,
              style: context.text.labelMedium?.copyWith(
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
  final VoidCallback onTap;

  const _CategoryBudgetCard({required this.budget, required this.onTap});

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
    final p = context.palette;
    final text = context.text;
    final cat = budget.categoryInfo;
    final statusColor = _statusColor();
    final barColor = budget.isOverBudget
        ? AppColors.error
        : budget.isNearLimit
        ? AppColors.warning
        : cat.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: budget.isOverBudget
              ? AppColors.error.withValues(alpha: 0.4)
              : p.border,
        ),
      ),
      child: Material(
        color: AppColors.transparent,
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.12),
                        borderRadius: AppRadius.radiusMd,
                      ),
                      child: Icon(cat.icon, size: 18, color: cat.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppText(
                        cat.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.heading,
                        ),
                      ),
                    ),
                    AppSpacing.gapW8,
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: AppText.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: CurrencyUtils.format(budget.spent),
                              style: text.labelLarge?.copyWith(
                                fontSize: 13.5,
                                color: budget.isOverBudget
                                    ? AppColors.error
                                    : p.heading,
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
                                style: text.labelSmall?.copyWith(
                                  fontSize: 11.5,
                                  color: p.caption,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_outlined, size: 15, color: p.caption),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: AppRadius.radiusXs,
                  child: LinearProgressIndicator(
                    value: budget.progress,
                    minHeight: 5,
                    backgroundColor: p.isDark
                        ? p.surfaceSubtle
                        : p.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
                const SizedBox(height: 7),
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
                    AppText(
                      budget.statusLabel,
                      style: text.labelSmall?.copyWith(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    AppText(
                      !budget.hasLimit
                          ? StringConstants.tapToEdit
                          : budget.isOverBudget
                          ? '-${CurrencyUtils.format(budget.overBy)} over'
                          : '${CurrencyUtils.format(budget.remaining)} left',
                      style: text.labelSmall?.copyWith(
                        fontSize: 11,
                        color: budget.isOverBudget
                            ? AppColors.error
                            : p.caption,
                      ),
                    ),
                  ],
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
    final p = context.palette;
    final text = context.text;
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
              AppText(
                title,
                style: text.titleSmall?.copyWith(color: p.heading),
              ),
              AppText(
                body,
                style: text.bodySmall?.copyWith(color: p.secondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
