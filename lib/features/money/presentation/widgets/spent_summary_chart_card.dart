import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/money_insights.dart';

/// Period-aware Spent summary card with grouped BarChart:
/// - `1W`: Mon..Sun (This week vs Last week)
/// - `1M`: W1..W4 (This month vs Previous month)
/// - `6M`: 6 months (Last 6 months vs Prior 6 months)
/// - `1Y`: Q1..Q4 (Last 4 quarters vs Prior 4 quarters)
class SpentSummaryChartCard extends StatelessWidget {
  final MoneyInsights insights;

  const SpentSummaryChartCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final captionColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;

    final labels = insights.periodBarLabels.isNotEmpty
        ? insights.periodBarLabels
        : const ['W1', 'W2', 'W3', 'W4'];
    final currentBars = insights.periodCurrentBars.isNotEmpty
        ? insights.periodCurrentBars
        : insights.weeklySpend;
    final previousBars = insights.periodPreviousBars.isNotEmpty
        ? insights.periodPreviousBars
        : insights.previousWeeklySpend;

    final maxBucket = [...currentBars, ...previousBars, 100.0].reduce(math.max);
    final maxY = (maxBucket * 1.25).ceilToDouble();
    final rodWidth = labels.length > 5 ? 8.5 : 13.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${StringConstants.spent} · ${insights.period.label}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: captionColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      CurrencyUtils.format(insights.periodExpense, decimals: 2),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _SpendDeltaChip(
                    percent: insights.percentVsAverage,
                    label: StringConstants.vsAverage,
                  ),
                  const SizedBox(height: 4),
                  _SpendDeltaChip(
                    percent: insights.percentVsLastWeek,
                    label: StringConstants.lastWeek.toLowerCase(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 4 : 100,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: (isDark ? AppColors.darkBorder : AppColors.border)
                        .withValues(alpha: 0.8),
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[idx],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: captionColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        CurrencyUtils.format(rod.toY),
                        AppTextStyles.captionBold.copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
                barGroups: List.generate(labels.length, (i) {
                  final curr = i < currentBars.length ? currentBars[i] : 0.0;
                  final prev = i < previousBars.length ? previousBars[i] : 0.0;
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: curr,
                        width: rodWidth,
                        color: AppColors.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                      BarChartRodData(
                        toY: prev,
                        width: rodWidth,
                        color: AppColors.moneyChartPrevious,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              _LegendDot(
                color: AppColors.primary,
                label: insights.periodCurrentLegend,
              ),
              const SizedBox(width: 14),
              _LegendDot(
                color: AppColors.moneyChartPrevious,
                label: insights.periodPreviousLegend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpendDeltaChip extends StatelessWidget {
  final double percent;
  final String label;

  const _SpendDeltaChip({required this.percent, required this.label});

  @override
  Widget build(BuildContext context) {
    final isUp = percent > 0;
    final color = isUp ? AppColors.warning : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${isUp ? '↑' : '↓'} ${percent.abs().toStringAsFixed(1)}% $label',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
