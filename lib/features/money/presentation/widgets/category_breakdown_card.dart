import 'package:fl_chart/fl_chart.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/category_budget_entity.dart';
import '../../domain/entities/money_insights.dart';

/// "By Category" breakdown card with animated bars and over-budget warnings
/// matching `docs/expensetracker-main/lib/widgets/reports_widgets.dart`.
class CategoryBreakdownCard extends StatelessWidget {
  final List<CategoryBudgetEntity> categoryBudgets;

  const CategoryBreakdownCard({super.key, required this.categoryBudgets});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < categoryBudgets.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: palette.border,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _CategoryBreakdownRow(budget: categoryBudgets[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBreakdownRow extends StatelessWidget {
  final CategoryBudgetEntity budget;

  const _CategoryBreakdownRow({required this.budget});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final cat = budget.categoryInfo;
    final barColor = budget.isOverBudget
        ? AppColors.error
        : budget.isNearLimit
        ? AppColors.warning
        : cat.color;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: cat.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(cat.icon, size: 18, color: cat.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AppText(
                      cat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: palette.heading,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: AppText.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: CurrencyUtils.format(
                              budget.spent,
                              decimals: 2,
                            ),
                            style: text.labelLarge?.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: budget.isOverBudget
                                  ? AppColors.error
                                  : palette.heading,
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
                                color: palette.caption,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: budget.progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 5,
                    backgroundColor: palette.surfaceSubtle,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
              if (budget.isOverBudget) ...[
                const SizedBox(height: 3),
                AppText(
                  'Over by ${CurrencyUtils.format(budget.overBy, decimals: 2)}',
                  style: text.labelSmall?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Period spending vs budget summary + Top Spending Categories + 3 KPI cards
/// (Transactions, Avg/Day, Budget Score).
class MonthlySpendingSummaryCard extends StatelessWidget {
  final MoneyInsights insights;

  const MonthlySpendingSummaryCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final progress = insights.periodSpendProgress;
    final barColor = progress >= 0.85 ? AppColors.warning : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                '${insights.period.label} Spending',
                style: text.bodyMedium?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: palette.heading,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AppText(
                  AppDateUtils.formatMonthYear(insights.month),
                  style: text.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                CurrencyUtils.format(insights.periodExpense, decimals: 2),
                style: text.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: palette.heading,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: AppText(
                  'of ${CurrencyUtils.format(insights.periodLimit)}',
                  style: text.bodySmall?.copyWith(
                    fontSize: 12.5,
                    color: palette.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: palette.surfaceSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                '${(progress * 100).round()}% of ${insights.period.label.toLowerCase()} budget used',
                style: text.labelSmall?.copyWith(
                  fontSize: 11.5,
                  color: palette.secondary,
                ),
              ),
              AppText(
                '${CurrencyUtils.format(insights.periodSaved)} ${StringConstants.saved}',
                style: text.labelSmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TopSpendingCategoriesCard extends StatefulWidget {
  final List<CategorySpend> items;

  const TopSpendingCategoriesCard({super.key, required this.items});

  @override
  State<TopSpendingCategoriesCard> createState() =>
      _TopSpendingCategoriesCardState();
}

class _TopSpendingCategoriesCardState extends State<TopSpendingCategoriesCard> {
  int _touchedIndex = -1;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final totalSpent = items.fold<double>(0, (s, e) => s + e.amount);
    final displayed = _showAll ? items : items.take(4).toList();
    final touchedItem = (_touchedIndex >= 0 && _touchedIndex < items.length)
        ? items[_touchedIndex]
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText(
                  StringConstants.topCategories,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.heading,
                  ),
                ),
              ),
              if (items.length > 4) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showAll = !_showAll),
                  child: AppText(
                    _showAll ? 'Show top 4' : 'Show all (${items.length})',
                    style: text.labelSmall?.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Interactive Donut Ring + Active Category Callout
          if (totalSpent > 0) ...[
            Row(
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              if (!event.isInterestedForInteractions ||
                                  response == null ||
                                  response.touchedSection == null) {
                                if (_touchedIndex != -1) {
                                  setState(() => _touchedIndex = -1);
                                }
                                return;
                              }
                              final idx =
                                  response.touchedSection!.touchedSectionIndex;
                              if (_touchedIndex != idx) {
                                setState(() => _touchedIndex = idx);
                              }
                            },
                          ),
                          sectionsSpace: 2.5,
                          centerSpaceRadius: 34,
                          sections: List.generate(items.length, (i) {
                            final entry = items[i];
                            final isTouched = i == _touchedIndex;
                            return PieChartSectionData(
                              color: entry.category.color,
                              value: entry.amount > 0 ? entry.amount : 0.01,
                              title: '',
                              radius: isTouched ? 19 : 15,
                            );
                          }),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(
                              touchedItem != null
                                  ? touchedItem.category.shortLabel
                                  : 'Total',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall?.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: palette.caption,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AppText(
                                CurrencyUtils.compact(
                                  touchedItem != null
                                      ? touchedItem.amount
                                      : totalSpent,
                                ),
                                style: text.labelLarge?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: palette.heading,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items.take(3).map((entry) {
                      final cat = entry.category;
                      final pct = (entry.share * 100).round();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Icon(cat.icon, size: 13, color: cat.color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppText(
                                cat.shortLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.heading,
                                ),
                              ),
                            ),
                            AppText(
                              '$pct%',
                              style: text.labelSmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: cat.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: palette.border),
            const SizedBox(height: 10),
          ],

          // Detailed category rows with progress bars
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: Column(
              children: displayed.map((entry) {
                final cat = entry.category;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: cat.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppText(
                          cat.label,
                          style: text.bodySmall?.copyWith(
                            fontSize: 12.5,
                            color: palette.secondary,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: entry.share.clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: palette.surfaceSubtle,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              cat.color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 72,
                        child: AppText(
                          CurrencyUtils.format(entry.amount),
                          textAlign: TextAlign.right,
                          style: text.labelMedium?.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: palette.heading,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class MoneyKpiRow extends StatelessWidget {
  final MoneyInsights insights;

  const MoneyKpiRow({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiTile(
            icon: Icons.receipt_long_rounded,
            color: AppColors.moneyCatTransport,
            label: StringConstants.transactionsLabel,
            value: '${insights.periodTransactionCount}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiTile(
            icon: Icons.today_rounded,
            color: AppColors.primary,
            label: StringConstants.avgPerDay,
            value: CurrencyUtils.format(insights.periodAvgPerDay),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _KpiTile(
            icon: Icons.emoji_events_rounded,
            color: AppColors.moduleTime,
            label: StringConstants.budgetScore,
            value: '${insights.budgetScore}%',
          ),
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _KpiTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppText(
              value,
              maxLines: 1,
              style: text.titleSmall?.copyWith(
                fontSize: 15,
                color: palette.heading,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          AppText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall?.copyWith(
              fontSize: 11,
              color: palette.caption,
            ),
          ),
        ],
      ),
    );
  }
}
