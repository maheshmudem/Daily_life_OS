import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';
import '../utils/currency_utils.dart';
import 'feature_scaffold.dart';

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
    final text = context.text;
    final palette = context.palette;

    final ratio = dailySafeLimit > 0
        ? (spentToday / dailySafeLimit).clamp(0.0, 1.0)
        : 1.0;
    final isOver = spentToday > dailySafeLimit;
    final isNear = ratio >= 0.8 && !isOver;
    final tone = isOver
        ? AppColors.moneyLimit100
        : isNear
        ? AppColors.moneyWarning80
        : AppColors.moduleMoney;

    final remaining = (dailySafeLimit - spentToday).abs();

    return FeatureCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Safe-to-Spend Today', style: text.labelMedium),
                    AppSpacing.gapH4,
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: CurrencyUtils.format(remaining),
                            style: text.headlineLarge?.copyWith(
                              color: isOver ? tone : palette.heading,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: isOver ? '  over limit' : '  left today',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (onLogExpense != null)
                FeatureIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Log expense',
                  color: AppColors.moduleMoney,
                  onPressed: onLogExpense!,
                ),
            ],
          ),
          AppSpacing.gapH16,
          ClipRRect(
            borderRadius: AppRadius.radiusFull,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: palette.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(tone),
            ),
          ),
          AppSpacing.gapH8,
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent ${CurrencyUtils.format(spentToday)} of '
                  '${CurrencyUtils.format(dailySafeLimit)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                '$daysRemaining days left in month',
                style: text.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
