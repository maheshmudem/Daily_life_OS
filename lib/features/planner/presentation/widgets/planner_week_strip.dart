import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/planner_item_entity.dart';

/// Interactive 7-day week horizon strip for [PlannerPage].
///
/// Respects `context.palette` in both Light and Dark themes using
/// [AppColors.moduleTime] (Sunrise Amber) as the active Planner accent.
/// When [embeddedInHero] is `true`, omits the outer card border/padding so it
/// nests seamlessly inside `PlannerHeroCard`.
class PlannerWeekStrip extends StatelessWidget {
  final String? selectedDateIso;
  final int weekOffset;
  final List<PlannerItemEntity> allItems;
  final ValueChanged<String?> onSelectDate;
  final ValueChanged<int> onChangeWeekOffset;
  final bool embeddedInHero;

  const PlannerWeekStrip({
    super.key,
    required this.selectedDateIso,
    required this.weekOffset,
    required this.allItems,
    required this.onSelectDate,
    required this.onChangeWeekOffset,
    this.embeddedInHero = false,
  });

  static String toIsoDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Checks whether [item] occurs on [day] (either direct date match or active
  /// recurrence rule).
  static bool itemOccursOnDay(PlannerItemEntity item, DateTime day) {
    final dayIso = toIsoDate(day);
    if (item.date == dayIso) return true;
    if (!item.isRecurring) return false;

    final start = DateTime.tryParse(item.date);
    if (start != null) {
      final startDay = DateTime(start.year, start.month, start.day);
      if (day.isBefore(startDay)) return false;
    }
    if (item.endDate != null && item.endDate!.isNotEmpty) {
      final end = DateTime.tryParse(item.endDate!);
      if (end != null) {
        final endDay = DateTime(end.year, end.month, end.day);
        if (day.isAfter(endDay)) return false;
      }
    }

    switch (item.repeatType) {
      case 'daily':
        return true;
      case 'weekdays':
        return day.weekday >= DateTime.monday && day.weekday <= DateTime.friday;
      case 'weekly':
        final days = item.parsedRepeatDays;
        if (days.isEmpty) {
          return start != null && day.weekday == start.weekday;
        }
        return days.contains(day.weekday);
      case 'monthly':
        return start != null && day.day == start.day;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIso = toIsoDate(today);

    // Monday-anchored 7-day week shifted by [weekOffset]
    final currentWeekMonday = today.subtract(Duration(days: today.weekday - 1));
    final startMonday = currentWeekMonday.add(Duration(days: weekOffset * 7));
    final weekDays = List<DateTime>.generate(
      7,
      (i) => startMonday.add(Duration(days: i)),
    );

    final anchorForLabel = selectedDateIso != null
        ? (DateTime.tryParse(selectedDateIso!) ?? weekDays[3])
        : weekDays[3];
    final monthHeader = DateFormat('MMMM yyyy').format(anchorForLabel);
    final isAllDates = selectedDateIso == null;
    final activeAmber = palette.isDark
        ? AppColors.moduleTimeLight
        : AppColors.moduleTimeDark;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Top Row: Month Label + All Dates Pill + Week Chevrons ──────────
        Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 15,
              color: AppColors.moduleTime,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppText(
                  monthHeader,
                  maxLines: 1,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: palette.heading,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              key: const ValueKey('planner_all_dates_chip'),
              borderRadius: AppRadius.radiusFull,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelectDate(null);
                if (weekOffset != 0) onChangeWeekOffset(0);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: isAllDates
                      ? AppColors.moduleTime.withValues(
                          alpha: palette.isDark ? 0.20 : 0.12,
                        )
                      : palette.surfaceMuted,
                  borderRadius: AppRadius.radiusFull,
                  border: Border.all(
                    color: isAllDates
                        ? AppColors.moduleTime.withValues(alpha: 0.45)
                        : palette.divider,
                  ),
                ),
                child: AppText(
                  'All Dates',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isAllDates ? activeAmber : palette.secondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            _WeekNavIcon(
              tooltip: 'Previous week',
              icon: Icons.chevron_left_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                onChangeWeekOffset(weekOffset - 1);
              },
            ),
            _WeekNavIcon(
              tooltip: 'Next week',
              icon: Icons.chevron_right_rounded,
              onTap: () {
                HapticFeedback.selectionClick();
                onChangeWeekOffset(weekOffset + 1);
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // ── 7-Day Cells ────────────────────────────────────────────────────
        Row(
          children: [
            for (var i = 0; i < weekDays.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: _DayCell(
                  day: weekDays[i],
                  dayIso: toIsoDate(weekDays[i]),
                  isToday: toIsoDate(weekDays[i]) == todayIso,
                  isSelected: toIsoDate(weekDays[i]) == selectedDateIso,
                  itemsOnDay: allItems
                      .where((it) => itemOccursOnDay(it, weekDays[i]))
                      .toList(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final iso = toIsoDate(weekDays[i]);
                    onSelectDate(selectedDateIso == iso ? null : iso);
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    );

    if (embeddedInHero) {
      return content;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: palette.divider),
      ),
      child: content,
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final String dayIso;
  final bool isToday;
  final bool isSelected;
  final List<PlannerItemEntity> itemsOnDay;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.dayIso,
    required this.isToday,
    required this.isSelected,
    required this.itemsOnDay,
    required this.onTap,
  });

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final todayTextColor = palette.isDark
        ? AppColors.moduleTimeLight
        : AppColors.moduleTimeDark;

    final hasOverdue = itemsOnDay.any((i) => i.isOverdue);
    final hasPending = itemsOnDay.any((i) => !i.isDone);
    final hasAny = itemsOnDay.isNotEmpty;

    final Color? dotColor;
    if (!hasAny) {
      dotColor = null;
    } else if (isSelected) {
      dotColor = AppColors.textWhite;
    } else if (hasOverdue) {
      dotColor = AppColors.error;
    } else if (hasPending) {
      dotColor = AppColors.moduleTime;
    } else {
      dotColor = AppColors.success;
    }

    return InkWell(
      key: ValueKey('planner_day_$dayIso'),
      borderRadius: AppRadius.radiusSm,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 5.5, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.moduleTime
              : (isToday
                    ? AppColors.moduleTime.withValues(
                        alpha: palette.isDark ? 0.16 : 0.10,
                      )
                    : AppColors.transparent),
          borderRadius: AppRadius.radiusSm,
          border: Border.all(
            color: isSelected
                ? AppColors.moduleTime
                : (isToday
                      ? AppColors.moduleTime.withValues(alpha: 0.38)
                      : AppColors.transparent),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AppText(
                _weekdayLabels[day.weekday - 1],
                maxLines: 1,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.textWhite.withValues(alpha: 0.92)
                      : (isToday ? todayTextColor : palette.caption),
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: AppText(
                '${day.day}',
                maxLines: 1,
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isSelected
                      ? AppColors.textWhite
                      : (isToday ? todayTextColor : palette.heading),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4.5,
              height: 4.5,
              decoration: BoxDecoration(
                color: dotColor ?? AppColors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekNavIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  const _WeekNavIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(icon, size: 18, color: palette.icon),
        ),
      ),
    );
  }
}
