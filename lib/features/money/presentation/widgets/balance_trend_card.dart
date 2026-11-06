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
  final VoidCallback? onOpenAiSimulator;
  final VoidCallback? onOpenIou;

  const BalanceTrendCard({
    super.key,
    required this.insights,
    required this.onAddExpense,
    required this.onAddIncome,
    required this.onOpenInsights,
    this.onOpenAiSimulator,
    this.onOpenIou,
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

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Top Row: Main Account Pill + Net Worth Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceMuted
                      : AppColors.surfaceElevated,
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
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (insights.totalAssets > 0)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Text(
                      'Net Worth ${CurrencyUtils.compact(insights.netWorth)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Total Balance label + Main Balance Display
          Text(
            StringConstants.totalBalance,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: wholePart,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.textPrimary,
                      letterSpacing: -1.1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(
                    text: decimalPart,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Centered 14-day change row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: changeColor,
                size: 13,
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
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${isPositive ? '▲' : '▼'} ${insights.balanceChangePercent.abs().toStringAsFixed(1)}% (14d)',
                  style: AppTextStyles.captionBold.copyWith(
                    color: changeColor,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 14-day running balance LineChart
          SizedBox(
            height: 105,
            child: _BalanceLineChart(points: insights.balanceTrend),
          ),
          const SizedBox(height: 12),

          // Classic 2x2 Monthly Executive Summary Grid (Zero Overflows, Tappable)
          Row(
            children: [
              Expanded(
                child: _SnapshotMetricTile(
                  label: 'Salary / Income',
                  value: CurrencyUtils.format(insights.monthIncome),
                  subtitle: insights.monthIncome > 0
                      ? 'Earned this month'
                      : 'Tap to add income',
                  color: AppColors.success,
                  icon: Icons.south_west_rounded,
                  isDark: isDark,
                  onTap: onAddIncome,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotMetricTile(
                  label: 'Total Spent',
                  value: CurrencyUtils.format(insights.monthExpense),
                  subtitle: insights.totalLimit > 0
                      ? '${insights.spendPercent.round()}% of budget used'
                      : 'Tap to add expense',
                  color: AppColors.error,
                  icon: Icons.north_east_rounded,
                  isDark: isDark,
                  onTap: onAddExpense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SnapshotMetricTile(
                  label: 'Net Saved',
                  value: CurrencyUtils.format(insights.actualSaved),
                  subtitle:
                      '${insights.savingsRatePercent.clamp(0, 100).round()}% savings rate',
                  color: AppColors.primary,
                  icon: Icons.savings_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SnapshotMetricTile(
                  label: 'Can Spend (Month)',
                  value: CurrencyUtils.format(insights.canSpendThisMonth),
                  subtitle: '${insights.daysRemainingInMonth} days remaining',
                  color: AppColors.moduleTime,
                  icon: Icons.account_balance_wallet_outlined,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Primary Action Row: + Add Expense  |  + Add Salary / Income
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_rounded,
                  label: StringConstants.moneyNavAdd,
                  isPrimary: true,
                  accentColor: AppColors.primary,
                  onTap: onAddExpense,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.south_west_rounded,
                  label: 'Salary / Income',
                  isPrimary: true,
                  accentColor: AppColors.success,
                  onTap: onAddIncome,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Secondary Quick Tools Strip: Lend / Borrow  |  AI Check  |  Reports
          Row(
            children: [
              if (onOpenIou != null) ...[
                Expanded(
                  child: _ActionButton(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Lend / Borrow',
                    isPrimary: false,
                    onTap: onOpenIou!,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (onOpenAiSimulator != null) ...[
                Expanded(
                  child: _ActionButton(
                    icon: Icons.auto_awesome_rounded,
                    label: 'AI Check',
                    isPrimary: false,
                    onTap: onOpenAiSimulator!,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: _ActionButton(
                  icon: Icons.bar_chart_rounded,
                  label: StringConstants.reports,
                  isPrimary: false,
                  onTap: onOpenInsights,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SnapshotMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _SnapshotMetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceMuted
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 13, color: color),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
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
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    this.accentColor = AppColors.primary,
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
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? widget.accentColor
                : (isDark ? AppColors.darkSurface : AppColors.surface),
            borderRadius: BorderRadius.circular(12),
            border: widget.isPrimary
                ? null
                : Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
            boxShadow: [
              BoxShadow(
                color: widget.isPrimary
                    ? widget.accentColor.withValues(alpha: 0.22)
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
                size: 16,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.isPrimary
                        ? Colors.white
                        : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
