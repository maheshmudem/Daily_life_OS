import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/app_dropdown_menu.dart';
import '../../../../core/widgets/expandable_text_widget.dart';
import '../../domain/entities/planner_item_entity.dart';

/// Editorial reminder & task card used in the Planner Agenda view.
///
/// Uses Daily Life OS design tokens (`AppRadius.radiusMd`, `AppSpacing`,
/// `AppColors.moduleTime` / `routineMorning` / `routineAfternoon` / `routineEvening`)
/// and sizes its vertical height strictly to actual item content (notes and
/// checklists collapse to zero height when empty).
class PlannerItemCard extends StatefulWidget {
  final PlannerItemEntity item;
  final bool isDark;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onSnooze;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onPushTomorrow;
  final VoidCallback? onPushToTimeline;
  final VoidCallback? onStartFocus;
  final ValueChanged<List<ChecklistItem>>? onChecklistChanged;

  const PlannerItemCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
    required this.onSnooze,
    this.onEdit,
    this.onDuplicate,
    this.onPushTomorrow,
    this.onPushToTimeline,
    this.onStartFocus,
    this.onChecklistChanged,
  });

  @override
  State<PlannerItemCard> createState() => _PlannerItemCardState();
}

class _PlannerItemCardState extends State<PlannerItemCard> {
  static const double _checkSize = 21;
  static const double _titleLineHeight = 20;
  static const double _contentInset = _checkSize + 10;
  static const double _actionHeight = 28;

  late bool _isExpanded =
      !widget.item.isDone &&
      widget.item.checklist.isNotEmpty &&
      widget.item.checklist.length <= 3;

  ({String label, Color color})? _dayPartInfo(String? rawTime) {
    if (rawTime == null || rawTime.trim().isEmpty) return null;
    final clean = rawTime.trim().toUpperCase();
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$',
    ).firstMatch(clean);
    if (match == null) return null;
    var h = int.tryParse(match.group(1)!) ?? 0;
    final period = match.group(3);
    if (period == 'PM' && h < 12) h += 12;
    if (period == 'AM' && h == 12) h = 0;
    if (h < 12) return (label: 'Morning', color: AppColors.routineMorning);
    if (h < 17) return (label: 'Afternoon', color: AppColors.routineAfternoon);
    return (label: 'Evening', color: AppColors.routineEvening);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final item = widget.item;

    final Color spineColor = item.isOverdue
        ? AppColors.error
        : (item.isDone ? AppColors.success : item.color);

    final Color borderColor;
    if (item.isOverdue) {
      borderColor = AppColors.error.withValues(alpha: 0.45);
    } else if (item.isDone) {
      borderColor = AppColors.success.withValues(alpha: 0.32);
    } else {
      borderColor = palette.divider;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: borderColor),
        boxShadow: palette.isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.025),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
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
                  ? spineColor.withValues(alpha: 0.55)
                  : spineColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheck(palette, item),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: widget.onEdit,
                        borderRadius: AppRadius.radiusXs,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleRow(palette, item),
                            const SizedBox(height: 4),
                            _buildMeta(palette, item),
                            if (item.notes.trim().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              ExpandableTextWidget(
                                text: item.notes.trim(),
                                collapsedMaxLines: 2,
                                characterThreshold: 65,
                                toggleColor: AppColors.moduleTime,
                                style: context.text.bodySmall?.copyWith(
                                  fontSize: 13,
                                  height: 1.38,
                                  color: palette.body,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (!item.isDone && widget.onStartFocus != null) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'Start Focus Sprint',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(7),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            widget.onStartFocus!();
                          },
                          child: Container(
                            width: 26,
                            height: _titleLineHeight + 2,
                            decoration: BoxDecoration(
                              color: AppColors.moduleTime.withValues(
                                alpha: palette.isDark ? 0.18 : 0.11,
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.bolt_rounded,
                                size: 15.5,
                                color: AppColors.moduleTime,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 2),
                    _buildMenu(palette, item),
                  ],
                ),

                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: (_isExpanded && item.checklist.isNotEmpty)
                      ? Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xs,
                            left: _contentInset,
                          ),
                          child: _buildChecklist(palette, item),
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: AppSpacing.xs),
                Divider(height: 1, thickness: 1, color: palette.divider),
                const SizedBox(height: 4),
                _buildActions(palette, item),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Leading check ─────────────────────────────────────────────────────────
  Widget _buildCheck(AppPalette palette, PlannerItemEntity item) {
    final isDone = item.isDone;
    return Semantics(
      checked: isDone,
      button: true,
      child: InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onToggle(!isDone);
        },
        radius: 19,
        child: SizedBox(
          height: _titleLineHeight,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: _checkSize,
              height: _checkSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.moduleTime : AppColors.transparent,
                border: Border.all(
                  color: isDone
                      ? AppColors.moduleTime
                      : (item.isOverdue ? AppColors.error : palette.border),
                  width: 1.8,
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13.5,
                      color: AppColors.textWhite,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  // ── Title + priority ──────────────────────────────────────────────────────
  Widget _buildTitleRow(AppPalette palette, PlannerItemEntity item) {
    final showPriority = item.priority == 'urgent' || item.priority == 'high';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ExpandableTextWidget(
            text: item.title,
            collapsedMaxLines: 2,
            characterThreshold: 60,
            toggleColor: AppColors.moduleTime,
            style: context.text.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.3,
              letterSpacing: -0.2,
              fontWeight: FontWeight.w600,
              color: item.isDone ? palette.caption : palette.heading,
              decoration: item.isDone ? TextDecoration.lineThrough : null,
              decorationColor: palette.caption,
            ),
          ),
        ),
        if (showPriority) ...[
          const SizedBox(width: 6),
          SizedBox(
            height: _titleLineHeight,
            child: Center(
              child: _Pill(
                label: item.priority.toUpperCase(),
                color: item.priorityColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Metadata line ─────────────────────────────────────────────────────────
  Widget _buildMeta(AppPalette palette, PlannerItemEntity item) {
    final metaColor = item.isOverdue ? AppColors.error : palette.caption;
    final dayPart = _dayPartInfo(item.startTime);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!item.isRecurring && item.date.isNotEmpty)
          _MetaItem(
            icon: Icons.calendar_today_rounded,
            label: item.dateDisplay,
            color: metaColor,
          ),
        if (item.timeRange.isNotEmpty)
          _MetaItem(
            icon: Icons.schedule_rounded,
            label: item.timeRange,
            color: metaColor,
          ),
        if (dayPart != null && !item.isDone)
          _Pill(label: dayPart.label, color: dayPart.color),
        if (item.isRecurring)
          _MetaItem(
            icon: Icons.repeat_rounded,
            label: item.recurrenceSummary,
            color: AppColors.moduleTimeDark,
          ),
        if (item.reminderOffsetMinutes > 0)
          _MetaItem(
            icon: Icons.notifications_none_rounded,
            label: '${item.reminderOffsetMinutes}m early',
            color: palette.caption,
          ),
        if (item.checklist.isNotEmpty)
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isExpanded = !_isExpanded);
            },
            borderRadius: AppRadius.radiusXs,
            child: _MetaItem(
              icon: Icons.checklist_rounded,
              label: '${item.checklistDoneCount}/${item.checklist.length}',
              color: AppColors.primary,
              trailing: Icon(
                _isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ),
          ),
        if (item.category.isNotEmpty)
          _Pill(label: item.category, color: item.color),
        if (item.isOverdue)
          const _Pill(label: 'Overdue', color: AppColors.error),
      ],
    );
  }

  // ── Expanded checklist with progress bar ──────────────────────────────────
  Widget _buildChecklist(AppPalette palette, PlannerItemEntity item) {
    final total = item.checklist.length;
    final done = item.checklistDoneCount;
    final progress = total > 0 ? (done / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: palette.surfaceMuted.withValues(
          alpha: palette.isDark ? 0.55 : 0.75,
        ),
        borderRadius: AppRadius.radiusSm,
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppRadius.radiusFull,
                  child: LinearProgressIndicator(
                    minHeight: 3.5,
                    value: progress,
                    backgroundColor: palette.divider,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.moduleTime,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppText(
                '$done/$total',
                style: context.text.labelSmall?.copyWith(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: palette.caption,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final c in item.checklist)
            InkWell(
              borderRadius: AppRadius.radiusXs,
              onTap: () => _setChecklistItem(item, c, !c.isDone),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      c.isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 15.5,
                      color: c.isDone ? AppColors.moduleTime : palette.caption,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: AppText(
                        c.title,
                        style: context.text.bodySmall?.copyWith(
                          fontSize: 12.5,
                          color: c.isDone ? palette.caption : palette.heading,
                          decoration: c.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: palette.caption,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _setChecklistItem(
    PlannerItemEntity item,
    ChecklistItem target,
    bool isDone,
  ) {
    final onChanged = widget.onChecklistChanged;
    if (onChanged == null) return;
    HapticFeedback.selectionClick();
    onChanged(
      item.checklist
          .map((c) => c.id == target.id ? c.copyWith(isDone: isDone) : c)
          .toList(),
    );
  }

  // ── Footer actions ────────────────────────────────────────────────────────
  Widget _buildActions(AppPalette palette, PlannerItemEntity item) {
    final quietStyle = TextButton.styleFrom(
      foregroundColor: palette.body,
      minimumSize: const Size(0, _actionHeight),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: context.text.captionBold.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: _contentInset - 8),
                if (widget.onEdit != null)
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    style: quietStyle,
                    icon: const Icon(Icons.edit_outlined, size: 13.5),
                    label: const AppText('Edit'),
                  ),
                TextButton.icon(
                  onPressed: widget.onSnooze,
                  style: quietStyle,
                  icon: const Icon(Icons.snooze_rounded, size: 13.5),
                  label: const AppText('Snooze +15m', maxLines: 1),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        FilledButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            widget.onToggle(!item.isDone);
          },
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, _actionHeight),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.fromLTRB(9, 0, 11, 0),
            elevation: 0,
            backgroundColor: item.isDone
                ? palette.surfaceMuted
                : AppColors.moduleTime.withValues(
                    alpha: palette.isDark ? 0.22 : 0.13,
                  ),
            foregroundColor: item.isDone
                ? palette.caption
                : (palette.isDark
                      ? AppColors.moduleTimeLight
                      : AppColors.moduleTimeDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: context.text.captionBold.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: Icon(
            item.isDone ? Icons.undo_rounded : Icons.check_rounded,
            size: 14.5,
          ),
          label: AppText(item.isDone ? 'Undo' : 'Mark Done'),
        ),
      ],
    );
  }

  // ── Overflow menu ─────────────────────────────────────────────────────────
  Widget _buildMenu(AppPalette palette, PlannerItemEntity item) {
    return AppDropdownMenu<String>(
      tooltip: 'More actions',
      offset: const Offset(0, 6),
      menuConstraints: const BoxConstraints(minWidth: 168, maxWidth: 215),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            widget.onEdit?.call();
            break;
          case 'focus':
            widget.onStartFocus?.call();
            break;
          case 'snooze':
            widget.onSnooze();
            break;
          case 'duplicate':
            widget.onDuplicate?.call();
            break;
          case 'push_tomorrow':
            widget.onPushTomorrow?.call();
            break;
          case 'push_timeline':
            widget.onPushToTimeline?.call();
            break;
          case 'delete':
            widget.onDelete();
            break;
        }
      },
      items: [
        if (widget.onEdit != null)
          AppDropdownItem(
            value: 'edit',
            icon: Icons.edit_outlined,
            label: 'Edit Reminder',
          ),
        if (widget.onStartFocus != null && !item.isDone)
          AppDropdownItem(
            value: 'focus',
            icon: Icons.bolt_rounded,
            label: 'Focus Sprint',
            tintColor: AppColors.moduleTime,
          ),
        AppDropdownItem(
          value: 'snooze',
          icon: Icons.snooze_rounded,
          label: 'Snooze...',
          tintColor: AppColors.moduleTime,
        ),
        if (widget.onDuplicate != null)
          AppDropdownItem(
            value: 'duplicate',
            icon: Icons.copy_rounded,
            label: 'Duplicate',
          ),
        if (widget.onPushTomorrow != null && !item.isRecurring)
          AppDropdownItem(
            value: 'push_tomorrow',
            icon: Icons.next_plan_outlined,
            label: 'Push to Tomorrow',
          ),
        if (widget.onPushToTimeline != null)
          AppDropdownItem(
            value: 'push_timeline',
            icon: Icons.schedule_send_rounded,
            label: StringConstants.pushToTodayTimeline,
            tintColor: AppColors.primary,
          ),
        const AppDropdownDivider(),
        AppDropdownItem(
          value: 'delete',
          icon: Icons.delete_outline_rounded,
          label: 'Delete Reminder',
          isDestructive: true,
        ),
      ],
      child: SizedBox(
        width: 24,
        height: _titleLineHeight,
        child: Align(
          alignment: Alignment.centerRight,
          child: Icon(Icons.more_horiz_rounded, size: 19, color: palette.icon),
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.5, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: AppText(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final double letterSpacing;

  const _Pill({
    required this.label,
    required this.color,
    this.letterSpacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5.5),
      ),
      child: AppText(
        label,
        style: context.text.labelSmall?.copyWith(
          fontSize: 10.5,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: letterSpacing,
          color: color,
        ),
      ),
    );
  }
}
