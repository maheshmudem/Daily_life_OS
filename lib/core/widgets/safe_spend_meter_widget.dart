import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: AppText(
                  'Safe-to-Spend Today',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: palette.heading,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.14),
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: AppText(
                      statusLabel,
                      style: text.labelSmall?.copyWith(
                        color: tone,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  if (widget.onLogExpense != null) ...[
                    const SizedBox(width: 6),
                    FeatureIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'Log expense',
                      color: AppColors.moduleMoney,
                      onPressed: widget.onLogExpense!,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: AppText.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: CurrencyUtils.format(remaining),
                        style: text.headlineLarge?.copyWith(
                          fontSize: 24,
                          height: 1.15,
                          letterSpacing: -0.6,
                          color: isOver ? tone : palette.heading,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      TextSpan(
                        text: isOver ? '  over limit' : '  left today',
                        style: text.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: palette.caption,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => setState(() => _showDetails = !_showDetails),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: palette.divider, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        _showDetails ? 'Show less' : 'Show more',
                        style: text.labelSmall?.copyWith(
                          color: palette.body,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _showDetails
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: palette.caption,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AppText(
                  'Spent ${CurrencyUtils.format(widget.spentToday)} of '
                  '${CurrencyUtils.format(widget.dailySafeLimit)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelMedium?.copyWith(
                    fontSize: 12,
                    color: palette.caption,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AppText(
                  '${widget.daysRemaining} days left in month',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: text.labelMedium?.copyWith(
                    fontSize: 12,
                    color: palette.caption,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
          AppText(
            label,
            style: text.labelSmall?.copyWith(
              color: palette.caption,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          AppText(
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
