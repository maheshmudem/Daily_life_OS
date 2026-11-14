import 'package:flutter/material.dart';
import 'package:daily_life_os/config/theme/app_colors.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/expandable_text_widget.dart';
import '../../domain/entities/transaction_entity.dart';

/// Compact Safe-to-Spend Today & Daily/Weekly Budget card formatted via
/// [CurrencyUtils] with live animated today-spend progress, daily budget alerts,
/// 7-day budget cap, and quick edit / salary-plan triggers.
class SafeToSpendHeroCard extends StatelessWidget {
  final BudgetEntity budget;
  final double spentToday;
  final double weeklySpend;
  final VoidCallback? onEditBudget;
  final VoidCallback? onOpenSalaryPlan;

  const SafeToSpendHeroCard({
    super.key,
    required this.budget,
    this.spentToday = 0,
    this.weeklySpend = 0,
    this.onEditBudget,
    this.onOpenSalaryPlan,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    // Use dailyAllowanceForToday so today's expenses are NOT subtracted twice!
    final dailyLimit = budget.dailyAllowanceForToday(spentToday);
    final leftToday = dailyLimit - spentToday;
    final isOverDaily = dailyLimit > 0 && spentToday > dailyLimit;
    final isNearDaily =
        dailyLimit > 0 && !isOverDaily && (spentToday / dailyLimit) >= 0.8;
    final dailyProgress = dailyLimit > 0
        ? (spentToday / dailyLimit).clamp(0.0, 1.0)
        : 0.0;
    final weeklyCap = dailyLimit * 7;
    final leftThisWeek = (weeklyCap - weeklySpend).clamp(0.0, double.infinity);
    final leftThisMonth = budget.remainingSpendable;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecorations.heroMoneyGradient.copyWith(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Zero Overflow)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.textWhite.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppColors.textWhite,
                  size: 14,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AppText(
                    'SAFE-TO-SPEND TODAY',
                    style: text.labelSmall?.copyWith(
                      color: AppColors.textWhite,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onOpenSalaryPlan != null) ...[
                        InkWell(
                          onTap: onOpenSalaryPlan,
                          borderRadius: AppRadius.radiusFull,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textWhite.withValues(
                                alpha: 0.22,
                              ),
                              borderRadius: AppRadius.radiusFull,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_graph_rounded,
                                  size: 11,
                                  color: AppColors.textWhite,
                                ),
                                const SizedBox(width: 4),
                                AppText(
                                  'Set Plan',
                                  style: text.labelSmall?.copyWith(
                                    color: AppColors.textWhite,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textWhite.withValues(alpha: 0.18),
                          borderRadius: AppRadius.radiusFull,
                        ),
                        child: AppText(
                          '${budget.daysRemaining}d left',
                          style: text.labelSmall?.copyWith(
                            color: AppColors.textWhite,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (onEditBudget != null) ...[
                        const SizedBox(width: 5),
                        InkWell(
                          onTap: onEditBudget,
                          borderRadius: AppRadius.radiusFull,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.textWhite.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              size: 13,
                              color: AppColors.textWhite,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),

          // Main Can-Spend-Today Headline + Daily Allowance Cap
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        CurrencyUtils.format(
                          leftToday.clamp(0, double.infinity),
                        ),
                        maxLines: 1,
                        style: text.headlineMedium?.copyWith(
                          color: AppColors.textWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      budget.monthlyBudget <= 0
                          ? 'Tap "Set Plan" to set monthly salary/budget'
                          : 'Available out of ${CurrencyUtils.format(dailyLimit)}/day cap',
                      softWrap: true,
                      style: text.labelSmall?.copyWith(
                        color: AppColors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: isOverDaily
                      ? AppColors.error.withValues(alpha: 0.34)
                      : isNearDaily
                      ? AppColors.moduleTime.withValues(alpha: 0.30)
                      : AppColors.black.withValues(alpha: 0.18),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: AppText(
                  isOverDaily
                      ? 'Over by ${CurrencyUtils.format(spentToday - dailyLimit)}'
                      : '${((1.0 - dailyProgress) * 100).round()}% safe',
                  style: text.labelSmall?.copyWith(
                    color: AppColors.textWhite,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          // Animated Daily Spend Progress Bar
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: dailyProgress),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, animVal, _) => ClipRRect(
              borderRadius: AppRadius.radiusFull,
              child: LinearProgressIndicator(
                value: animVal,
                minHeight: 5.5,
                backgroundColor: AppColors.textWhite.withValues(alpha: 0.22),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverDaily
                      ? AppColors.errorLight
                      : isNearDaily
                      ? AppColors.moduleTimeLight
                      : AppColors.textWhite,
                ),
              ),
            ),
          ),

          // Inline Daily Budget Alert when near or over limit (Expandable)
          if (isOverDaily || isNearDaily) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    isOverDaily
                        ? Icons.warning_amber_rounded
                        : Icons.notifications_active_outlined,
                    size: 13,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: ExpandableTextWidget(
                    text: isOverDaily
                        ? 'Daily budget exceeded (${CurrencyUtils.format(spentToday)} spent today). Pause non-essential spend tomorrow to rebalance.'
                        : 'Approaching daily limit (${(dailyProgress * 100).round()}% used today). Keep remaining spend light.',
                    collapsedMaxLines: 1,
                    toggleColor: AppColors.textWhite,
                    style: text.labelSmall?.copyWith(
                      color: AppColors.textWhite,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 11),

          // Spacious 2x2 Spendable Runway Grid (Today Spent · Week Left / Month Left · Fixed Bills)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textWhite.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricStat(
                        context,
                        'Spent Today',
                        CurrencyUtils.format(spentToday),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricStat(
                        context,
                        'Can Spend This Week',
                        CurrencyUtils.format(leftThisWeek),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: AppColors.textWhite.withValues(alpha: 0.14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricStat(
                        context,
                        'Can Spend This Month',
                        CurrencyUtils.format(leftThisMonth),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricStat(
                        context,
                        'Fixed Monthly Bills',
                        CurrencyUtils.format(budget.fixedBills),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStat(BuildContext context, String label, String value) {
    final text = context.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AppText(
            label,
            style: text.labelSmall?.copyWith(
              color: AppColors.white70,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AppText(
            value,
            style: text.labelLarge?.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
