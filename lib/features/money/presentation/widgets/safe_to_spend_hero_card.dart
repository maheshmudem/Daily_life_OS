import 'package:flutter/material.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/transaction_entity.dart';

/// Compact Safe-to-Spend Today & Daily/Weekly Budget card formatted via
/// [CurrencyUtils] with live today-spend progress, daily budget alerts,
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
    final dailyLimit = budget.dailySafeSpend;
    final leftToday = dailyLimit - spentToday;
    final isOverDaily = dailyLimit > 0 && spentToday > dailyLimit;
    final isNearDaily =
        dailyLimit > 0 && !isOverDaily && (spentToday / dailyLimit) >= 0.8;
    final dailyProgress = dailyLimit > 0
        ? (spentToday / dailyLimit).clamp(0.0, 1.0)
        : 0.0;
    final weeklyLimit = dailyLimit * 7;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: AppDecorations.heroMoneyGradient.copyWith(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              const Expanded(
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
              if (onOpenSalaryPlan != null) ...[
                InkWell(
                  onTap: onOpenSalaryPlan,
                  borderRadius: AppRadius.radiusFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
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
                          'Set Budget / Salary',
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
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
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
                const SizedBox(width: 6),
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
          const SizedBox(height: 8),

          // Main Daily Limit + Today's Remaining Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyUtils.format(dailyLimit),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/ day budget',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOverDaily
                      ? Colors.redAccent.withValues(alpha: 0.32)
                      : isNearDaily
                      ? Colors.amber.withValues(alpha: 0.28)
                      : Colors.black.withValues(alpha: 0.16),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  isOverDaily
                      ? 'Over by ${CurrencyUtils.format(spentToday - dailyLimit)}'
                      : '${CurrencyUtils.format(leftToday.clamp(0, double.infinity))} left today',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Daily Spend Progress Bar
          ClipRRect(
            borderRadius: AppRadius.radiusFull,
            child: LinearProgressIndicator(
              value: dailyProgress,
              minHeight: 5,
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

          // Inline Daily Budget Alert when near or over limit
          if (isOverDaily || isNearDaily) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(
                  isOverDaily
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_active_outlined,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    isOverDaily
                        ? 'Daily budget exceeded (${CurrencyUtils.format(spentToday)} spent today). Pause non-essential spend.'
                        : 'Approaching daily limit (${(dailyProgress * 100).round()}% used today).',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

          const SizedBox(height: 10),

          // 4-Metric Summary Strip (Spent Today, 7-Day Budget, Bills, Monthly Budget)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetricStat(
                  'Today Spent',
                  CurrencyUtils.format(spentToday),
                ),
                _buildMetricStat(
                  '7-Day Cap',
                  CurrencyUtils.format(weeklyLimit),
                ),
                _buildMetricStat(
                  'Fixed Bills',
                  CurrencyUtils.format(budget.fixedBills),
                ),
                _buildMetricStat(
                  'Month Cap',
                  CurrencyUtils.format(budget.monthlyBudget),
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
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
