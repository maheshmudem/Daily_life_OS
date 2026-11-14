import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/planner_item_entity.dart';
import 'planner_week_strip.dart';

/// Theme-adaptive Planner Overview & 7-Day Horizon Card.
///
/// Built strictly on Daily Life OS design tokens (`context.palette`,
/// [AppColors.moduleTime] Sunrise Amber, [AppSpacing], [AppRadius], and
/// [AppTextStyles]) with content-proportional sizing:
/// - Left completion ring + concise status summary + optional 1-tap `Up Next`
///   focus pill (collapsed when no pending item exists)
/// - Surface-muted 4-metric interactive filter strip (`Active`, `Today`,
///   `Overdue`, `Done`)
/// - Seamless hairline-divided [PlannerWeekStrip]
class PlannerHeroCard extends StatelessWidget {
  final int totalCount;
  final int todayCount;
  final int overdueCount;
  final int completedCount;
  final String todayIso;
  final String? selectedDateIso;
  final String targetDateLabel;
  final int weekOffset;
  final List<PlannerItemEntity> allItems;
  final PlannerItemEntity? nextPendingItem;
  final bool isActiveMetricSelected;
  final bool isTodayMetricSelected;
  final bool isOverdueMetricSelected;
  final bool isDoneMetricSelected;
  final VoidCallback onTapActiveMetric;
  final VoidCallback onTapTodayMetric;
  final VoidCallback onTapOverdueMetric;
  final VoidCallback onTapDoneMetric;
  final ValueChanged<String?> onSelectDate;
  final ValueChanged<int> onChangeWeekOffset;
  final ValueChanged<PlannerItemEntity>? onFocusNext;

  const PlannerHeroCard({
    super.key,
    required this.totalCount,
    required this.todayCount,
    required this.overdueCount,
    required this.completedCount,
    required this.todayIso,
    required this.selectedDateIso,
    required this.targetDateLabel,
    required this.weekOffset,
    required this.allItems,
    this.nextPendingItem,
    required this.isActiveMetricSelected,
    required this.isTodayMetricSelected,
    required this.isOverdueMetricSelected,
    required this.isDoneMetricSelected,
    required this.onTapActiveMetric,
    required this.onTapTodayMetric,
    required this.onTapOverdueMetric,
    required this.onTapDoneMetric,
    required this.onSelectDate,
    required this.onChangeWeekOffset,
    this.onFocusNext,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final isDark = palette.isDark;

    final pendingCount = math.max(0, totalCount - completedCount);
    final progress = totalCount > 0
        ? (completedCount / totalCount).clamp(0.0, 1.0)
        : 0.0;
    final completionPct = (progress * 100).round();

    final amberAccent = isDark
        ? AppColors.moduleTimeLight
        : AppColors.moduleTimeDark;

    final String headline;
    final String subtitle;
    if (totalCount == 0) {
      headline = 'No reminders scheduled yet';
      subtitle = 'Add a reminder or pick a quick template below';
    } else if (pendingCount == 0) {
      headline = 'All $totalCount reminders completed';
      subtitle = 'Schedule clear — great consistency today';
    } else if (overdueCount > 0) {
      headline =
          '$pendingCount active · $overdueCount overdue ${overdueCount == 1 ? 'task' : 'tasks'}';
      subtitle = '$completedCount of $totalCount completed so far';
    } else {
      headline =
          '$pendingCount active ${pendingCount == 1 ? 'reminder' : 'reminders'}';
      subtitle = '$completedCount of $totalCount completed ($completionPct%)';
    }

    return Container(
      decoration: AppDecorations.card(context),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Subtle Sunrise Amber top wash matching Module 2 (Planner & Focus)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 84,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.moduleTime.withValues(
                        alpha: isDark ? 0.12 : 0.07,
                      ),
                      AppColors.focusPomodoro.withValues(
                        alpha: isDark ? 0.04 : 0.02,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              14,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── 1. Compact Ring + Data-Driven Summary + Next Focus ──────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PlannerCompletionRing(
                      progress: progress,
                      percentage: completionPct,
                      isDark: isDark,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  selectedDateIso == null
                                      ? 'PLANNER HORIZON'
                                      : 'HORIZON · ${targetDateLabel.toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.overline.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: amberAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.25,
                              color: palette.heading,
                            ),
                          ),
                          const SizedBox(height: 1.5),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: palette.caption,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Optional 1-Tap "Up Next" Focus Pill (only when data exists)
                if (nextPendingItem != null && onFocusNext != null) ...[
                  const SizedBox(height: 10),
                  Material(
                    color: AppColors.moduleTime.withValues(
                      alpha: isDark ? 0.14 : 0.08,
                    ),
                    borderRadius: AppRadius.radiusSm,
                    child: InkWell(
                      borderRadius: AppRadius.radiusSm,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onFocusNext!(nextPendingItem!);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6.5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.radiusSm,
                          border: Border.all(
                            color: AppColors.moduleTime.withValues(
                              alpha: isDark ? 0.30 : 0.22,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: AppColors.moduleTime,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Up Next · ${nextPendingItem!.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.heading,
                                ),
                              ),
                            ),
                            if ((nextPendingItem!.startTime ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Text(
                                nextPendingItem!.startTime!,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: amberAccent,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 15,
                              color: palette.caption,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.sm),

                // ── 2. Theme-Matched 4-Metric Interactive Filter Strip ──────
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: AppRadius.radiusMd,
                    border: Border.all(
                      color: palette.divider.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroMetricTile(
                          key: const ValueKey('planner_metric_active'),
                          icon: Icons.pending_actions_rounded,
                          accentColor: AppColors.primary,
                          label: 'Active',
                          value: '$pendingCount',
                          isActive: isActiveMetricSelected,
                          onTap: onTapActiveMetric,
                        ),
                      ),
                      _metricDivider(palette.divider),
                      Expanded(
                        child: _HeroMetricTile(
                          key: const ValueKey('planner_metric_today'),
                          icon: Icons.today_rounded,
                          accentColor: AppColors.moduleTime,
                          label: 'Today',
                          value: '$todayCount',
                          isActive: isTodayMetricSelected,
                          onTap: onTapTodayMetric,
                        ),
                      ),
                      _metricDivider(palette.divider),
                      Expanded(
                        child: _HeroMetricTile(
                          key: const ValueKey('planner_metric_overdue'),
                          icon: Icons.warning_amber_rounded,
                          accentColor: overdueCount > 0
                              ? AppColors.error
                              : palette.caption,
                          label: 'Overdue',
                          value: '$overdueCount',
                          highlightError: overdueCount > 0,
                          isActive: isOverdueMetricSelected,
                          onTap: onTapOverdueMetric,
                        ),
                      ),
                      _metricDivider(palette.divider),
                      Expanded(
                        child: _HeroMetricTile(
                          key: const ValueKey('planner_metric_done'),
                          icon: Icons.check_circle_outline_rounded,
                          accentColor: AppColors.success,
                          label: 'Done',
                          value: '$completionPct%',
                          isActive: isDoneMetricSelected,
                          onTap: onTapDoneMetric,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),
                Divider(height: 1, thickness: 1, color: palette.divider),
                const SizedBox(height: 10),

                // ── 3. Embedded 7-Day Week Horizon ──────────────────────────
                PlannerWeekStrip(
                  selectedDateIso: selectedDateIso,
                  weekOffset: weekOffset,
                  allItems: allItems,
                  embeddedInHero: true,
                  onSelectDate: onSelectDate,
                  onChangeWeekOffset: onChangeWeekOffset,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricDivider(Color color) =>
      Container(width: 1, height: 24, color: color);
}

class _PlannerCompletionRing extends StatelessWidget {
  final double progress;
  final int percentage;
  final bool isDark;

  const _PlannerCompletionRing({
    required this.progress,
    required this.percentage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final ringColor = percentage >= 100
        ? AppColors.success
        : AppColors.moduleTime;

    return SizedBox(
      width: 50,
      height: 50,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, child) {
          return CustomPaint(
            painter: _RingPainter(
              progress: animatedValue,
              color: ringColor,
              trackColor: palette.surfaceSubtle,
            ),
            child: child,
          );
        },
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                '$percentage%',
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: palette.heading,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 3.5;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.005) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

class _HeroMetricTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String label;
  final String value;
  final bool highlightError;
  final bool isActive;
  final VoidCallback onTap;

  const _HeroMetricTile({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.label,
    required this.value,
    this.highlightError = false,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4.5),
        decoration: BoxDecoration(
          color: isActive ? palette.card : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isActive
                ? accentColor.withValues(alpha: palette.isDark ? 0.45 : 0.35)
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 15.5,
                  height: 1.15,
                  letterSpacing: -0.3,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: highlightError
                      ? AppColors.error
                      : (isActive ? accentColor : palette.heading),
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 11.5, color: accentColor),
                  const SizedBox(width: 3.5),
                  Text(
                    label,
                    maxLines: 1,
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? accentColor : palette.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
