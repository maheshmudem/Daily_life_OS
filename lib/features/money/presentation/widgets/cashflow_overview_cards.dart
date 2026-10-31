import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/money_insights.dart';

/// Two side-by-side mini-chart cards matching `CashflowSection` in
/// `docs/expensetracker-main/lib/widgets/reports_widgets.dart`:
/// Income (6-month BarChart) and Net Cashflow (6-month LineChart).
class CashflowOverviewCards extends StatelessWidget {
  final MoneyInsights insights;

  const CashflowOverviewCards({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _IncomeMiniCard(insights: insights)),
        const SizedBox(width: 12),
        Expanded(child: _NetCashflowMiniCard(insights: insights)),
      ],
    );
  }
}

class _IncomeMiniCard extends StatelessWidget {
  final MoneyInsights insights;

  const _IncomeMiniCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final values = insights.incomeSeries.map((e) => e.value).toList();
    final maxVal = [...values, 100.0].reduce(math.max) * 1.2;

    return Container(
      padding: const EdgeInsets.all(14),
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
          Text(
            StringConstants.income,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.format(insights.periodIncome, decimals: 2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: BarChart(
              BarChartData(
                maxY: maxVal,
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: const BarTouchData(enabled: false),
                barGroups: List.generate(values.length, (i) {
                  final isLatest = i == values.length - 1;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        width: 11,
                        color: isLatest
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.35),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NetCashflowMiniCard extends StatelessWidget {
  final MoneyInsights insights;

  const _NetCashflowMiniCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final net = insights.periodNet;
    final isPositive = net >= 0;
    final values = insights.netSeries.map((e) => e.value).toList();
    final minVal = [...values, -100.0].reduce(math.min) * 1.2;
    final maxVal = [...values, 100.0].reduce(math.max) * 1.2;

    final mainSpots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final negativeSpots = <FlSpot>[
      for (var i = 0; i < values.length; i++)
        FlSpot(i.toDouble(), math.min(values[i], 0)),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
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
          Text(
            StringConstants.netCashflow,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyUtils.signed(net, isCredit: isPositive, decimals: 2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isPositive ? AppColors.success : AppColors.error,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 70,
            child: LineChart(
              LineChartData(
                minY: minVal,
                maxY: maxVal,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: mainSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.primary,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.14),
                    ),
                  ),
                  LineChartBarData(
                    spots: negativeSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.error,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
