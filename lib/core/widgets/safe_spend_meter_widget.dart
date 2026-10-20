import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_text_styles.dart';

/// Dynamic Safe-to-Spend meter widget implementing the formula from PRD:
/// Daily Safe Spend = (Monthly Budget - (Fixed Bills + Spent So Far)) / Days Remaining
class SafeSpendMeterWidget extends StatelessWidget {
  final double spentToday;
  final double dailySafeLimit;
  final int daysRemaining;
  final double monthlyBudget;
  final VoidCallback? onLogExpense;

  const SafeSpendMeterWidget({
    super.key,
    required this.spentToday,
    required this.dailySafeLimit,
    required this.daysRemaining,
    required this.monthlyBudget,
    this.onLogExpense,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = dailySafeLimit > 0 ? (spentToday / dailySafeLimit).clamp(0.0, 1.0) : 1.0;
    final isOverLimit = spentToday > dailySafeLimit;
    final isNearLimit = ratio >= 0.8 && !isOverLimit;

    final progressColor = isOverLimit
        ? AppColors.moneyLimit100
        : isNearLimit
            ? AppColors.moneyWarning80
            : AppColors.moduleMoney;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusXl,
        border: Border.all(
          color: isOverLimit
              ? AppColors.moneyLimit100.withValues(alpha: 0.35)
              : (isDark ? AppColors.darkDivider : AppColors.divider),
        ),
        boxShadow: [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.14),
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 18,
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Safe-to-Spend Today',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                        ),
                      ),
                      Text(
                        '₹${(dailySafeLimit - spentToday).toStringAsFixed(0)} left today',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (onLogExpense != null)
                IconButton.filledTonal(
                  onPressed: onLogExpense,
                  style: IconButton.styleFrom(
                    backgroundColor: progressColor.withValues(alpha: 0.12),
                    foregroundColor: progressColor,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: AppRadius.radiusFull,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: isDark
                  ? AppColors.darkSurfaceSecondary
                  : AppColors.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 10),

          // Details Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ₹${spentToday.toStringAsFixed(0)} / ₹${dailySafeLimit.toStringAsFixed(0)}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Text(
                  '$daysRemaining days remaining in month',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
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
