import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';
import '../utils/currency_utils.dart';
import 'feature_scaffold.dart';

/// Dynamic Safe-to-Spend meter widget implementing the formula from PRD:
/// Daily Safe Spend = (Monthly Budget - (Fixed Bills + Spent So Far)) / Days Remaining
class SafeSpendMeterWidget extends StatefulWidget {
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
  State<SafeSpendMeterWidget> createState() => _SafeSpendMeterWidgetState();
}

class _SafeSpendMeterWidgetState extends State<SafeSpendMeterWidget> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final palette = context.palette;

    final ratio = widget.dailySafeLimit > 0
        ? (widget.spentToday / widget.dailySafeLimit).clamp(0.0, 1.0)
        : 1.0;
    final isOver = widget.spentToday > widget.dailySafeLimit;
    final isNear = ratio >= 0.8 && !isOver;
    final tone = isOver
        ? AppColors.moneyLimit100
        : isNear
        ? AppColors.moneyWarning80
        : AppColors.moduleMoney;

    final statusLabel = isOver
        ? 'Over Limit'
        : isNear
        ? 'Near Limit'
        : 'On Track';

    final remaining = (widget.dailySafeLimit - widget.spentToday).abs();

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
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Safe-to-Spend Today',
                          style: text.titleMedium?.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: palette.heading,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: tone.withValues(alpha: 0.14),
                            borderRadius: AppRadius.radiusFull,
                          ),
                          child: Text(
                            statusLabel,
                            style: text.labelSmall?.copyWith(
                              color: tone,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
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
              if (widget.onLogExpense != null)
                FeatureIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Log expense',
                  color: AppColors.moduleMoney,
                  onPressed: widget.onLogExpense!,
                ),
            ],
          ),
          AppSpacing.gapH12,
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: ratio),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutCubic,
            builder: (context, animatedRatio, _) {
              return ClipRRect(
                borderRadius: AppRadius.radiusFull,
                child: LinearProgressIndicator(
                  value: animatedRatio,
                  minHeight: 7,
                  backgroundColor: palette.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(tone),
                ),
              );
            },
          ),
          AppSpacing.gapH8,
          Wrap(
            spacing: 12,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Spent ${CurrencyUtils.format(widget.spentToday)} of '
                '${CurrencyUtils.format(widget.dailySafeLimit)}',
                style: text.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${widget.daysRemaining} days left in month',
                style: text.labelMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              InkWell(
                onTap: () => setState(() => _showDetails = !_showDetails),
                borderRadius: AppRadius.radiusXs,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showDetails ? 'Show less' : 'Show more',
                        style: text.labelSmall?.copyWith(
                          color: AppColors.moduleMoney,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _showDetails
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: AppColors.moduleMoney,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _showDetails
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(color: palette.border, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _BudgetDetailColumn(
                              label: 'Monthly Budget',
                              value: CurrencyUtils.format(widget.monthlyBudget),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: palette.border,
                          ),
                          Expanded(
                            child: _BudgetDetailColumn(
                              label: 'Daily Safe Limit',
                              value: CurrencyUtils.format(
                                widget.dailySafeLimit,
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 26,
                            color: palette.border,
                          ),
                          Expanded(
                            child: _BudgetDetailColumn(
                              label: 'Used Today',
                              value: '${(ratio * 100).round()}%',
                              valueColor: tone,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _BudgetDetailColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BudgetDetailColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: palette.caption,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: text.labelLarge?.copyWith(
              color: valueColor ?? palette.heading,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
