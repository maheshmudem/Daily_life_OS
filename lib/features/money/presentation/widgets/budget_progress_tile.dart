import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/category_budget_entity.dart';

/// Compact budget progress row matching `BudgetBarWidget` in
/// `docs/expensetracker-main/lib/widgets/budget_bar_widget.dart`.
class BudgetProgressTile extends StatelessWidget {
  final CategoryBudgetEntity budget;
  final VoidCallback? onTap;

  const BudgetProgressTile({super.key, required this.budget, this.onTap});

  Color _statusColor() {
    if (budget.isOverBudget) return AppColors.error;
    if (budget.isNearLimit) return AppColors.warning;
    return budget.categoryInfo.color;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = context.text;
    final cat = budget.categoryInfo;
    final barColor = _statusColor();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.label,
                        style: text.titleSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: p.heading,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Row(
                        children: [
                          if (budget.isOverBudget || budget.isNearLimit) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: barColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            AppSpacing.gapW4,
                          ],
                          Flexible(
                            child: Text(
                              !budget.hasLimit
                                  ? StringConstants.noLimitSet
                                  : budget.isOverBudget
                                  ? '${StringConstants.overBudget} (${CurrencyUtils.format(budget.overBy, decimals: 0)})'
                                  : budget.isNearLimit
                                  ? StringConstants.nearLimit
                                  : '${CurrencyUtils.format(budget.remaining, decimals: 0)} left',
                              softWrap: true,
                              style: text.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight:
                                    budget.isOverBudget || budget.isNearLimit
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: budget.isOverBudget || budget.isNearLimit
                                    ? barColor
                                    : p.caption,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapW8,
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: CurrencyUtils.format(budget.spent),
                              style: text.labelLarge?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: budget.isOverBudget
                                    ? AppColors.error
                                    : p.heading,
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
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapH8,
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: budget.progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: AppRadius.radiusXs,
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 5.5,
                  backgroundColor: p.isDark ? p.surfaceSubtle : p.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
