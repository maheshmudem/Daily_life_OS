import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = budget.categoryInfo;
    final barColor = _statusColor();
    final captionColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    borderRadius: BorderRadius.circular(10),
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
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
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
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              !budget.hasLimit
                                  ? StringConstants.noLimitSet
                                  : budget.isOverBudget
                                  ? '${StringConstants.overBudget} (${CurrencyUtils.format(budget.overBy)})'
                                  : budget.isNearLimit
                                  ? StringConstants.nearLimit
                                  : '${CurrencyUtils.format(budget.remaining)} left',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    budget.isOverBudget || budget.isNearLimit
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: budget.isOverBudget || budget.isNearLimit
                                    ? barColor
                                    : captionColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: CurrencyUtils.format(budget.spent),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: budget.isOverBudget
                                  ? AppColors.error
                                  : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.textPrimary),
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
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: budget.progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 5.5,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceMuted
                      : AppColors.surfaceElevated,
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
