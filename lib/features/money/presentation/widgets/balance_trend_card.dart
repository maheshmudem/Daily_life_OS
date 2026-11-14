import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../domain/entities/money_insights.dart';

/// Executive Fintech Wealth & Balance Hero Card inspired by Copilot Money,
/// Monarch Money, and Revolut:
/// 1. Ambient header glow + "Main Account" status pill + Net Worth pill +
///    1-tap Balance Privacy Mask toggle (`••••••`)
/// 2. Tabular integer/decimal split balance with interactive chart-scrubbing readout
/// 3. Full-width 14-day curved LineChart with emerald/indigo gradient fill
/// 4. Unified 2x2 Bento Cashflow Grid (`Salary / Income`, `Total Spent`,
///    `Net Saved`, `Can Spend (Month)`)
/// 5. Sleek Fintech Quick-Action Dock (`Add`, `Salary / Income`, `Lend / Borrow`,
///    `AI Check`, `Reports`)
class BalanceTrendCard extends StatefulWidget {
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
  State<BalanceTrendCard> createState() => _BalanceTrendCardState();
}

class _BalanceTrendCardState extends State<BalanceTrendCard> {
  bool _hideBalance = false;
  int? _touchedDayIndex;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final isDark = palette.isDark;
    final insights = widget.insights;
    final isPositive = insights.balanceChange >= 0;
    final changeColor = isPositive ? AppColors.moduleMoney : AppColors.error;

    final points = insights.balanceTrend;
    final activeBalance =
        (_touchedDayIndex != null &&
            _touchedDayIndex! >= 0 &&
            _touchedDayIndex! < points.length)
        ? points[_touchedDayIndex!]
        : insights.balance;

    final formatted = CurrencyUtils.format(activeBalance, decimals: 2);
    final dotIndex = formatted.lastIndexOf('.');
    final wholePart = dotIndex != -1
        ? formatted.substring(0, dotIndex)
        : formatted;
    final decimalPart = dotIndex != -1 ? formatted.substring(dotIndex) : '.00';

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppColors.moduleMoney.withValues(alpha: 0.24)
              : palette.border,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle ambient top-right radial glow for executive fintech depth
          Positioned(
            top: -45,
            right: -35,
            child: IgnorePointer(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.moduleMoney.withValues(
                        alpha: isDark ? 0.16 : 0.10,
                      ),
                      AppColors.moduleMoney.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Column(
              children: [
                // 1. Top Row: Main Account Pill + Net Worth Pill + Privacy Toggle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: palette.surfaceSubtle,
                        borderRadius: AppRadius.radiusFull,
                        border: Border.all(color: palette.border),
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
                              boxShadow: [
                                BoxShadow(
                                  color: changeColor.withValues(alpha: 0.45),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          AppText(
                            StringConstants.mainAccount,
                            style: text.labelSmall?.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: palette.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (insights.totalAssets > 0) ...[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.moduleMoney.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: AppRadius.radiusFull,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: AppText(
                              _hideBalance
                                  ? 'Net Worth ••••'
                                  : 'Net Worth ${CurrencyUtils.compact(insights.netWorth)}',
                              style: text.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.moduleMoney,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Tooltip(
                      message: _hideBalance ? 'Show balance' : 'Hide balance',
                      child: InkWell(
                        key: const ValueKey('toggle_balance_privacy'),
                        borderRadius: AppRadius.radiusFull,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _hideBalance = !_hideBalance);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: palette.surfaceSubtle,
                            shape: BoxShape.circle,
                            border: Border.all(color: palette.border),
                          ),
                          child: Icon(
                            _hideBalance
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 14,
                            color: palette.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Total Balance label + Main Balance Display
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      StringConstants.totalBalance,
                      style: text.labelSmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: palette.caption,
                      ),
                    ),
                    if (_touchedDayIndex != null && points.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AppText(
                          'Day ${_touchedDayIndex! + 1}/${points.length}',
                          style: text.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _hideBalance
                      ? AppText(
                          '${CurrencyUtils.symbol} ••••••',
                          key: const ValueKey('masked_balance'),
                          style: text.headlineLarge?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: palette.heading,
                          ),
                        )
                      : FittedBox(
                          key: ValueKey('visible_balance_$wholePart'),
                          fit: BoxFit.scaleDown,
                          child: AppText.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: wholePart,
                                  style: text.headlineLarge?.copyWith(
                                    fontSize: 35,
                                    fontWeight: FontWeight.w800,
                                    color: palette.heading,
                                    letterSpacing: -1.1,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                TextSpan(
                                  text: decimalPart,
                                  style: text.titleMedium?.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: palette.secondary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 5),

                // Centered 14-day change row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: changeColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    AppText.captionBold(
                      _hideBalance
                          ? '••••'
                          : CurrencyUtils.signed(
                              insights.balanceChange,
                              isCredit: isPositive,
                              decimals: 2,
                            ),
                      color: changeColor,
                      fontSize: 12,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: AppText.captionBold(
                        '${isPositive ? '▲' : '▼'} ${insights.balanceChangePercent.abs().toStringAsFixed(1)}% (14d)',
                        color: changeColor,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. 14-day running balance LineChart with touch scrubbing
                SizedBox(
                  height: 100,
                  child: _BalanceLineChart(
                    points: insights.balanceTrend,
                    onTouchIndexChanged: (idx) {
                      if (_touchedDayIndex != idx) {
                        setState(() => _touchedDayIndex = idx);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // 4. Unified 2x2 Bento Cashflow Grid
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? palette.surfaceSubtle.withValues(alpha: 0.65)
                        : palette.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SnapshotMetricTile(
                              label: 'Salary / Income',
                              value: _hideBalance
                                  ? '•••••'
                                  : CurrencyUtils.format(insights.monthIncome),
                              subtitle: insights.monthIncome > 0
                                  ? 'Earned this month'
                                  : 'Tap to add income',
                              color: AppColors.success,
                              icon: Icons.south_west_rounded,
                              onTap: widget.onAddIncome,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SnapshotMetricTile(
                              label: 'Total Spent',
                              value: _hideBalance
                                  ? '•••••'
                                  : CurrencyUtils.format(insights.monthExpense),
                              subtitle: insights.totalLimit > 0
                                  ? '${insights.spendPercent.round()}% of budget used'
                                  : 'Tap to add expense',
                              color: AppColors.error,
                              icon: Icons.north_east_rounded,
                              onTap: widget.onAddExpense,
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
                              value: _hideBalance
                                  ? '•••••'
                                  : CurrencyUtils.format(insights.actualSaved),
                              subtitle:
                                  '${insights.savingsRatePercent.clamp(0, 100).round()}% savings rate',
                              color: AppColors.primary,
                              icon: Icons.savings_outlined,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _SnapshotMetricTile(
                              label: 'Can Spend (Month)',
                              value: _hideBalance
                                  ? '•••••'
                                  : CurrencyUtils.format(
                                      insights.canSpendThisMonth,
                                    ),
                              subtitle:
                                  '${insights.daysRemainingInMonth} days remaining',
                              color: AppColors.moduleTime,
                              icon: Icons.account_balance_wallet_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Modern Fintech Quick-Action Dock
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DockActionTile(
                        icon: Icons.add_rounded,
                        label: StringConstants.moneyNavAdd,
                        accentColor: AppColors.moduleMoney,
                        isFilled: true,
                        onTap: widget.onAddExpense,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _DockActionTile(
                        icon: Icons.south_west_rounded,
                        label: 'Salary / Income',
                        accentColor: AppColors.success,
                        isFilled: true,
                        onTap: widget.onAddIncome,
                      ),
                    ),
                    if (widget.onOpenIou != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _DockActionTile(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Lend / Borrow',
                          accentColor: AppColors.moduleTime,
                          isFilled: false,
                          onTap: widget.onOpenIou!,
                        ),
                      ),
                    ],
                    if (widget.onOpenAiSimulator != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: _DockActionTile(
                          icon: Icons.auto_awesome_rounded,
                          label: 'AI Check',
                          accentColor: AppColors.primary,
                          isFilled: false,
                          onTap: widget.onOpenAiSimulator!,
                        ),
                      ),
                    ],
                    const SizedBox(width: 6),
                    Expanded(
                      child: _DockActionTile(
                        icon: Icons.bar_chart_rounded,
                        label: StringConstants.reports,
                        accentColor: AppColors.moduleNotes,
                        isFilled: false,
                        onTap: widget.onOpenInsights,
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
}

class _SnapshotMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _SnapshotMetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final isDark = palette.isDark;
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: palette.border.withValues(alpha: isDark ? 0.7 : 0.8),
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
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: AppText(
                        label,
                        style: text.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppText(
                  value,
                  maxLines: 1,
                  style: text.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.heading,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppText(
                  subtitle,
                  style: text.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color,
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

class _BalanceLineChart extends StatelessWidget {
  final List<double> points;
  final ValueChanged<int?>? onTouchIndexChanged;

  const _BalanceLineChart({required this.points, this.onTouchIndexChanged});

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
          touchCallback: (event, response) {
            if (onTouchIndexChanged == null) return;
            if (!event.isInterestedForInteractions ||
                response == null ||
                response.lineBarSpots == null ||
                response.lineBarSpots!.isEmpty) {
              onTouchIndexChanged!(null);
              return;
            }
            onTouchIndexChanged!(response.lineBarSpots!.first.spotIndex);
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots
                .map(
                  (s) => LineTooltipItem(
                    CurrencyUtils.format(s.y),
                    context.text.captionBold.copyWith(
                      color: AppColors.textWhite,
                    ),
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
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.moduleMoney],
            ),
            barWidth: 2.8,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) => spot.x == spots.last.x,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 5,
                    color: AppColors.moduleMoney,
                    strokeWidth: 2.5,
                    strokeColor: AppColors.textWhite,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.moduleMoney.withValues(alpha: 0.22),
                  AppColors.primary.withValues(alpha: 0.04),
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

class _DockActionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool isFilled;
  final VoidCallback onTap;

  const _DockActionTile({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.isFilled,
    required this.onTap,
  });

  @override
  State<_DockActionTile> createState() => _DockActionTileState();
}

class _DockActionTileState extends State<_DockActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final isDark = palette.isDark;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 40,
              decoration: BoxDecoration(
                color: widget.isFilled
                    ? widget.accentColor
                    : widget.accentColor.withValues(
                        alpha: isDark ? 0.16 : 0.10,
                      ),
                borderRadius: BorderRadius.circular(13),
                border: widget.isFilled
                    ? null
                    : Border.all(
                        color: widget.accentColor.withValues(alpha: 0.28),
                      ),
                boxShadow: widget.isFilled
                    ? [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                widget.icon,
                size: 19,
                color: widget.isFilled
                    ? AppColors.textWhite
                    : widget.accentColor,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AppText(
                widget.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: palette.heading,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
