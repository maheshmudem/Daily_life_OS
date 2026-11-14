import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/planner_item_entity.dart';

/// Structured / Sunsama-inspired chronological Day-Flow Timeline view.
///
/// Plots scheduled tasks along a vertical time rail with category-tinted nodes,
/// day-part distribution pills (`AppColors.routineMorning/Afternoon/Evening`),
/// content-adaptive block heights, and a live `NOW` horizontal indicator needle.
class PlannerTimelineView extends StatelessWidget {
  final List<PlannerItemEntity> items;
  final bool isDark;
  final ValueChanged<PlannerItemEntity> onToggle;
  final ValueChanged<PlannerItemEntity> onEdit;
  final ValueChanged<PlannerItemEntity> onStartFocus;
  final ValueChanged<PlannerItemEntity> onSnooze;

  const PlannerTimelineView({
    super.key,
    required this.items,
    required this.isDark,
    required this.onToggle,
    required this.onEdit,
    required this.onStartFocus,
    required this.onSnooze,
  });

  /// Parses `'9:30 AM'`, `'09:30'`, or `'14:15'` into minutes from midnight.
  static int? parseMinutesSinceMidnight(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final clean = raw.trim().toUpperCase();
    final regex = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$');
    final match = regex.firstMatch(clean);
    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!) ?? 0;
    final minute = int.tryParse(match.group(2)!) ?? 0;
    final period = match.group(3);

    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return (hour.clamp(0, 23) * 60) + minute.clamp(0, 59);
  }

  static String dayPartForMinutes(int? minutes) {
    if (minutes == null) return 'Anytime';
    if (minutes < 12 * 60) return 'Morning';
    if (minutes < 17 * 60) return 'Afternoon';
    return 'Evening';
  }

  static Color dayPartColor(String dayPart) {
    switch (dayPart) {
      case 'Morning':
        return AppColors.routineMorning;
      case 'Afternoon':
        return AppColors.routineAfternoon;
      case 'Evening':
        return AppColors.routineEvening;
      default:
        return AppColors.success;
    }
  }

  static String compactTimeLabel(String? raw, int? minutes) {
    if (minutes == null) return 'Flex';
    final h24 = minutes ~/ 60;
    final m = minutes % 60;
    final period = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    return '$h12:${m.toString().padLeft(2, '0')}\n$period';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheduled = <({PlannerItemEntity item, int minutes})>[];
    final unscheduled = <PlannerItemEntity>[];

    var morningCount = 0;
    var afternoonCount = 0;
    var eveningCount = 0;

    for (final item in items) {
      final mins = parseMinutesSinceMidnight(item.startTime);
      if (mins == null) {
        unscheduled.add(item);
      } else {
        scheduled.add((item: item, minutes: mins));
        if (mins < 12 * 60) {
          morningCount++;
        } else if (mins < 17 * 60) {
          afternoonCount++;
        } else {
          eveningCount++;
        }
      }
    }

    scheduled.sort((a, b) => a.minutes.compareTo(b.minutes));

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final nowFormatted = DateFormat('h:mm a').format(now);

    // Determine where to inject the live NOW needle
    var nowInsertIndex = scheduled.length;
    for (var i = 0; i < scheduled.length; i++) {
      if (scheduled[i].minutes >= nowMinutes) {
        nowInsertIndex = i;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── 1. Day-Part Rhythm Overview Strip ──────────────────────────────
        Container(
          margin: const EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: AppRadius.radiusMd,
            border: Border.all(color: palette.divider),
          ),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timeline_rounded,
                    size: 16,
                    color: AppColors.moduleTime,
                  ),
                  const SizedBox(width: 6),
                  AppText(
                    'Day-Flow Rhythm',
                    style: context.text.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.heading,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _DayPartChip(
                    icon: Icons.wb_twilight_rounded,
                    label: 'AM $morningCount',
                    color: AppColors.routineMorning,
                    isDark: palette.isDark,
                  ),
                  _DayPartChip(
                    icon: Icons.wb_sunny_rounded,
                    label: 'PM $afternoonCount',
                    color: AppColors.routineAfternoon,
                    isDark: palette.isDark,
                  ),
                  _DayPartChip(
                    icon: Icons.nights_stay_rounded,
                    label: 'Eve $eveningCount',
                    color: AppColors.routineEvening,
                    isDark: palette.isDark,
                  ),
                  if (unscheduled.isNotEmpty)
                    _DayPartChip(
                      icon: Icons.all_inclusive_rounded,
                      label: 'Flex ${unscheduled.length}',
                      color: AppColors.success,
                      isDark: palette.isDark,
                    ),
                ],
              ),
            ],
          ),
        ),

        // ── 2. Scheduled Chronological Axis + Live NOW Needle ──────────────
        for (var i = 0; i <= scheduled.length; i++) ...[
          if (i == nowInsertIndex) _NowNeedleRow(nowLabel: nowFormatted),
          if (i < scheduled.length)
            _TimelineAxisNode(
              item: scheduled[i].item,
              timeText: compactTimeLabel(
                scheduled[i].item.startTime,
                scheduled[i].minutes,
              ),
              dayPart: dayPartForMinutes(scheduled[i].minutes),
              isLast: i == scheduled.length - 1 && unscheduled.isEmpty,
              onToggle: () => onToggle(scheduled[i].item),
              onEdit: () => onEdit(scheduled[i].item),
              onStartFocus: () => onStartFocus(scheduled[i].item),
              onSnooze: () => onSnooze(scheduled[i].item),
            ),
        ],

        // ── 3. Unscheduled / Flexible Bucket ───────────────────────────────
        if (unscheduled.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: AppText.overline(
              'ANYTIME · FLEXIBLE SLOTS',
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: palette.caption,
            ),
          ),
          for (var i = 0; i < unscheduled.length; i++)
            _TimelineAxisNode(
              item: unscheduled[i],
              timeText: 'ANY\nTIME',
              dayPart: 'Anytime',
              isLast: i == unscheduled.length - 1,
              onToggle: () => onToggle(unscheduled[i]),
              onEdit: () => onEdit(unscheduled[i]),
              onStartFocus: () => onStartFocus(unscheduled[i]),
              onSnooze: () => onSnooze(unscheduled[i]),
            ),
        ],
      ],
    );
  }
}

class _DayPartChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;

  const _DayPartChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: AppRadius.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3.5),
          AppText(
            label,
            style: context.text.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _NowNeedleRow extends StatelessWidget {
  final String nowLabel;

  const _NowNeedleRow({required this.nowLabel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.moduleTime,
              borderRadius: AppRadius.radiusFull,
              boxShadow: [
                BoxShadow(
                  color: AppColors.moduleTime.withValues(alpha: 0.28),
                  blurRadius: 6,
                ),
              ],
            ),
            child: const AppText.overline(
              'NOW',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.moduleTime,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.moduleTime,
                    AppColors.moduleTime.withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AppText.captionBold(
            nowLabel,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.moduleTimeDark,
            tabularFigures: true,
          ),
        ],
      ),
    );
  }
}

/// Content-proportional time-block card along the axis rail.
///
/// Uses `Stack` + `Positioned` instead of `IntrinsicHeight` so narrow viewports
/// and nested `FittedBox` children never trigger layout assertions.
class _TimelineAxisNode extends StatelessWidget {
  final PlannerItemEntity item;
  final String timeText;
  final String dayPart;
  final bool isLast;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onStartFocus;
  final VoidCallback onSnooze;

  const _TimelineAxisNode({
    required this.item,
    required this.timeText,
    required this.dayPart,
    required this.isLast,
    required this.onToggle,
    required this.onEdit,
    required this.onStartFocus,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;
    final accent = item.isOverdue
        ? AppColors.error
        : (item.isDone ? AppColors.success : item.color);
    final dayPartTone = PlannerTimelineView.dayPartColor(dayPart);
    final hasEndTime = (item.endTime ?? '').trim().isNotEmpty;
    final hasNotes = item.notes.trim().isNotEmpty;
    final hasChecklist = item.checklist.isNotEmpty;
    final checklistProgress = hasChecklist
        ? (item.checklistDoneCount / item.checklist.length).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      children: [
        // Vertical Spine Rail
        if (!isLast)
          Positioned(
            left: 50,
            top: 21,
            bottom: 0,
            width: 2,
            child: ColoredBox(
              color: accent.withValues(alpha: palette.isDark ? 0.28 : 0.22),
            ),
          ),

        // Left Time Label
        Positioned(
          left: 0,
          top: 9,
          width: 40,
          child: AppText(
            timeText,
            textAlign: TextAlign.right,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: item.isDone ? palette.caption : palette.heading,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),

        // Category Dot on Axis
        Positioned(
          left: 45,
          top: 12,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: item.isDone ? accent : palette.card,
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 2.4),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: 0.22), blurRadius: 5),
              ],
            ),
          ),
        ),

        // Right Time-Block Card (height sizes strictly to item's content)
        Padding(
          padding: const EdgeInsets.only(left: 64, bottom: AppSpacing.xs),
          child: Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                color: item.isOverdue
                    ? AppColors.error.withValues(alpha: 0.45)
                    : palette.divider,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3.5,
                  child: ColoredBox(
                    color: item.isDone
                        ? accent.withValues(alpha: 0.55)
                        : accent,
                  ),
                ),
                InkWell(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkResponse(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onToggle();
                          },
                          radius: 18,
                          child: Container(
                            width: 19,
                            height: 19,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.isDone
                                  ? accent
                                  : AppColors.transparent,
                              border: Border.all(
                                color: item.isDone ? accent : palette.border,
                                width: 1.8,
                              ),
                            ),
                            child: item.isDone
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 12.5,
                                    color: AppColors.textWhite,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                  color: item.isDone
                                      ? palette.caption
                                      : palette.heading,
                                  decoration: item.isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (hasNotes && !item.isDone) ...[
                                const SizedBox(height: 3),
                                AppText(
                                  item.notes.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    height: 1.3,
                                    color: palette.body,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (hasEndTime)
                                    _MiniBadge(
                                      label: item.timeRange,
                                      color: palette.caption,
                                    ),
                                  _MiniBadge(
                                    label: item.category,
                                    color: item.color,
                                  ),
                                  _MiniBadge(
                                    label: dayPart,
                                    color: dayPartTone,
                                  ),
                                  if (item.priority == 'urgent' ||
                                      item.priority == 'high')
                                    _MiniBadge(
                                      label: item.priority.toUpperCase(),
                                      color: item.priorityColor,
                                    ),
                                  if (hasChecklist)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 28,
                                          child: ClipRRect(
                                            borderRadius: AppRadius.radiusFull,
                                            child: LinearProgressIndicator(
                                              minHeight: 3,
                                              value: checklistProgress,
                                              backgroundColor: palette.divider,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(AppColors.moduleTime),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        AppText.captionBold(
                                          '✓ ${item.checklistDoneCount}/${item.checklist.length}',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.moduleTimeDark,
                                          tabularFigures: true,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!item.isDone) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Snooze Reminder',
                            child: InkWell(
                              borderRadius: AppRadius.radiusXs,
                              onTap: onSnooze,
                              child: Padding(
                                padding: const EdgeInsets.all(3),
                                child: Icon(
                                  Icons.snooze_rounded,
                                  size: 15,
                                  color: palette.caption,
                                ),
                              ),
                            ),
                          ),
                          Tooltip(
                            message: 'Start Focus Sprint',
                            child: InkWell(
                              borderRadius: AppRadius.radiusXs,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                onStartFocus();
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(
                                  Icons.bolt_rounded,
                                  size: 16,
                                  color: AppColors.moduleTime,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: AppText(
        label,
        style: context.text.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
