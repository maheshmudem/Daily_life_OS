import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/money_insights.dart';

/// Matches the clean reference layout (`HomeChartWidget` + `BalanceDisplayWidget`
/// + `ActionButtonsWidget` from `docs/expensetracker-main`):
/// 1. Full-width 14-day curved LineChart with gradient fill & end-dot
/// 2. Centered "Main Account" pill + status dot + change row
/// 3. Centered integer/decimal split balance (`RichText`)
/// 4. Compact 3-button action bar (`Add`, `Reports`, and `Income` icon button)
class BalanceTrendCard extends StatelessWidget {
  final MoneyInsights insights;
  final VoidCallback onAddExpense;
  final VoidCallback onAddIncome;
  final VoidCallback onOpenInsights;

  const BalanceTrendCard({
    super.key,
    required this.insights,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onOpenInsights,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPositive = insights.balanceChange >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;

    final formatted = CurrencyUtils.format(insights.balance, decimals: 2);
    final dotIndex = formatted.lastIndexOf('.');
    final wholePart = dotIndex != -1
        ? formatted.substring(0, dotIndex)
        : formatted;
    final decimalPart = dotIndex != -1 ? formatted.substring(dotIndex) : '.00';

    return Column(
      children: [
        // 1. 14-day running balance LineChart (open, full-width)
        SizedBox(
          height: 145,
          child: _BalanceLineChart(points: insights.balanceTrend),
        ),
        const SizedBox(height: 6),

        // 2. Centered Main Account pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surfaceElevated,
            borderRadius: AppRadius.radiusFull,
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: changeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                StringConstants.mainAccount,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 3. Centered change row (↑ +₹1,412.14   ▲ 12.1%)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPositive
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: changeColor,
              size: 14,
            ),
            const SizedBox(width: 2),
            Text(
              CurrencyUtils.signed(
                insights.balanceChange,
                isCredit: isPositive,
                decimals: 2,
              ),
              style: AppTextStyles.captionBold.copyWith(
                color: changeColor,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${isPositive ? '▲' : '▼'} ${insights.balanceChangePercent.abs().toStringAsFixed(1)}%',
              style: AppTextStyles.captionBold.copyWith(
                color: changeColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          StringConstants.totalBalance,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),

        // 4. Centered Balance with integer / decimal split
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: wholePart,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  letterSpacing: -1.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              TextSpan(
                text: decimalPart,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Compact 3-button action bar (matches reference ActionButtonsWidget)
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.add_rounded,
                label: StringConstants.moneyNavAdd,
                isPrimary: true,
                onTap: onAddExpense,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(
                icon: Icons.bar_chart_rounded,
                label: StringConstants.reports,
                isPrimary: false,
                onTap: onOpenInsights,
              ),
            ),
            const SizedBox(width: 10),
            _SquareIconButton(
              icon: Icons.south_west_rounded,
              tooltip: StringConstants.addIncome,
              onTap: onAddIncome,
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceLineChart extends StatelessWidget {
  final List<double> points;

  const _BalanceLineChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final values = points.isEmpty ? const [0.0, 0.0] : points;
    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final span = (maxVal - minVal).abs();
    final pad = span == 0 ? (maxVal.abs() * 0.1 + 100) : span * 0.2;

    final spots = <FlSpot>[
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return LineChart(
      LineChartData(
        minY: minVal - pad,
        maxY: maxVal + pad,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots
                .map(
                  (s) => LineTooltipItem(
                    CurrencyUtils.format(s.y),
                    AppTextStyles.captionBold.copyWith(color: Colors.white),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) => spot.x == spots.last.x,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.primary.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? AppColors.primary
                : (isDark ? AppColors.darkSurface : AppColors.surface),
            borderRadius: BorderRadius.circular(13),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
            boxShadow: [
              BoxShadow(
                color: widget.isPrimary
                    ? AppColors.primary.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.isPrimary
                    ? Colors.white
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isPrimary
                      ? Colors.white
                      : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
          child: Icon(icon, color: AppColors.success, size: 19),
        ),
      ),
    );
  }
}
