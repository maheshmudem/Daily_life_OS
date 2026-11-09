import 'package:flutter/material.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
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
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SAFE-TO-SPEND TODAY',
                    style: TextStyle(
                      color: Colors.white,
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
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: AppRadius.radiusFull,
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_graph_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Set Plan',
                                  style: TextStyle(
                                    color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: AppRadius.radiusFull,
                        ),
                        child: Text(
                          '${budget.daysRemaining}d left',
                          style: const TextStyle(
                            color: Colors.white,
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
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              size: 13,
                              color: Colors.white,
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
                      child: Text(
                        CurrencyUtils.format(
                          leftToday.clamp(0, double.infinity),
                        ),
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      budget.monthlyBudget <= 0
                          ? 'Tap "Set Plan" to set monthly salary/budget'
                          : 'Available out of ${CurrencyUtils.format(dailyLimit)}/day cap',
                      softWrap: true,
                      style: const TextStyle(
                        color: Colors.white70,
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
                      ? Colors.redAccent.withValues(alpha: 0.34)
                      : isNearDaily
                      ? Colors.amber.withValues(alpha: 0.30)
                      : Colors.black.withValues(alpha: 0.18),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  isOverDaily
                      ? 'Over by ${CurrencyUtils.format(spentToday - dailyLimit)}'
                      : '${((1.0 - dailyProgress) * 100).round()}% safe',
                  style: const TextStyle(
                    color: Colors.white,
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
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverDaily
                      ? Colors.redAccent.shade100
                      : isNearDaily
                      ? Colors.amberAccent
                      : Colors.white,
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: ExpandableTextWidget(
                    text: isOverDaily
                        ? 'Daily budget exceeded (${CurrencyUtils.format(spentToday)} spent today). Pause non-essential spend tomorrow to rebalance.'
                        : 'Approaching daily limit (${(dailyProgress * 100).round()}% used today). Keep remaining spend light.',
                    collapsedMaxLines: 1,
                    toggleColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.white,
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
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricStat(
                        'Spent Today',
                        CurrencyUtils.format(spentToday),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricStat(
                        'Can Spend This Week',
                        CurrencyUtils.format(leftThisWeek),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricStat(
                        'Can Spend This Month',
                        CurrencyUtils.format(leftThisMonth),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricStat(
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

  Widget _buildMetricStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
