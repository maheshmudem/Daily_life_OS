import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dropdown_menu.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerItemCard extends StatefulWidget {
  final PlannerItemEntity item;
  final bool isDark;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onSnooze;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onPushTomorrow;
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
    this.onChecklistChanged,
  });

  @override
  State<PlannerItemCard> createState() => _PlannerItemCardState();
}

class _PlannerItemCardState extends State<PlannerItemCard> {
  bool _isExpanded = false;

  Widget _buildChipBadge({
    required Widget child,
    required Color backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 0.7)
            : null,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: item.isDone
              ? AppColors.success.withValues(alpha: 0.3)
              : (item.isOverdue
                  ? AppColors.error.withValues(alpha: 0.35)
                  : (isDark ? AppColors.darkDivider : AppColors.divider)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: Checkbox(
                    value: item.isDone,
                    activeColor: AppColors.moduleTime,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    onChanged: widget.onToggle,
                  ),
                ),
              ),
              AppSpacing.gapW8,
              Expanded(
                child: InkWell(
                  onTap: widget.onEdit,
                  borderRadius: AppRadius.radiusSm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextHeading
                                    : AppColors.textHeading,
                                decoration:
                                    item.isDone ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (item.priority != 'low' && item.priority != 'medium') ...[
                            AppSpacing.gapW4,
                            _buildChipBadge(
                              backgroundColor: item.priorityColor.withValues(alpha: 0.15),
                              borderColor: item.priorityColor.withValues(alpha: 0.4),
                              child: Text(
                                item.priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: item.priorityColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      AppSpacing.gapH4,
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (item.timeRange.isNotEmpty)
                            _buildChipBadge(
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.surfaceSecondary,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 10,
                                    color: isDark
                                        ? AppColors.darkTextCaption
                                        : AppColors.textCaption,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.timeRange,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextCaption
                                          : AppColors.textCaption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (!item.isRecurring && item.date.isNotEmpty)
                            _buildChipBadge(
                              backgroundColor: isDark
                                  ? AppColors.darkSurfaceSecondary
                                  : AppColors.surfaceSecondary,
                              borderColor: isDark
                                  ? AppColors.darkDivider
                                  : AppColors.divider,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 10,
                                    color: isDark
                                        ? AppColors.darkIconColor
                                        : AppColors.iconColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.dateDisplay,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.darkTextCaption
                                          : AppColors.textCaption,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (item.isRecurring)
                            _buildChipBadge(
                              backgroundColor: AppColors.moduleTime.withValues(alpha: 0.12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.repeat_rounded,
                                      size: 10, color: AppColors.moduleTime),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.recurrenceSummary,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.moduleTime,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (item.category.isNotEmpty)
                            _buildChipBadge(
                              backgroundColor: item.color.withValues(alpha: 0.14),
                              child: Text(
                                item.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: item.color,
                                ),
                              ),
                            ),
                          if (item.reminderOffsetMinutes > 0)
                            _buildChipBadge(
                              backgroundColor: AppColors.warning.withValues(alpha: 0.12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.notifications_active_rounded,
                                      size: 10, color: AppColors.warning),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${item.reminderOffsetMinutes}m early',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (item.isOverdue)
                            _buildChipBadge(
                              backgroundColor: AppColors.error.withValues(alpha: 0.14),
                              borderColor: AppColors.error.withValues(alpha: 0.4),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 10, color: AppColors.error),
                                  SizedBox(width: 3),
                                  Text(
                                    'OVERDUE',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.error,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (item.checklist.isNotEmpty)
                            InkWell(
                              onTap: () => setState(() => _isExpanded = !_isExpanded),
                              child: _buildChipBadge(
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.checklist_rounded,
                                        size: 11, color: AppColors.primary),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${item.checklistDoneCount}/${item.checklist.length}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Icon(
                                      _isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 12,
                                      color: AppColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (item.notes.isNotEmpty) ...[
                        AppSpacing.gapH4,
                        Row(
                          children: [
                            Icon(
                              Icons.notes_rounded,
                              size: 12,
                              color: isDark
                                  ? AppColors.darkIconColor
                                  : AppColors.iconColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.notes,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? AppColors.darkTextCaption
                                      : AppColors.textCaption,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              AppSpacing.gapW4,
              AppDropdownMenu<String>(
                tooltip: 'More actions',
                offset: const Offset(0, 8),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      widget.onEdit?.call();
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
                  const AppDropdownDivider(),
                  AppDropdownItem(
                    value: 'delete',
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete Reminder',
                    isDestructive: true,
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.6)
                        : AppColors.surfaceSecondary.withValues(alpha: 0.6),
                    borderRadius: AppRadius.radiusSm,
                  ),
                  child: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: isDark ? AppColors.darkIconColor : AppColors.iconColor,
                  ),
                ),
              ),
            ],
          ),

          // ── Expanded Checklist Subtasks ──────────────────────────────────
          if (_isExpanded && item.checklist.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.surfaceSecondary,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.checklist.map((c) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: c.isDone,
                            activeColor: AppColors.moduleTime,
                            onChanged: (val) {
                              if (widget.onChecklistChanged != null) {
                                final updated = item.checklist.map((curr) {
                                  if (curr.id == c.id) {
                                    return curr.copyWith(isDone: val ?? false);
                                  }
                                  return curr;
                                }).toList();
                                widget.onChecklistChanged!(updated);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            c.title,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextHeading
                                  : AppColors.textHeading,
                              decoration:
                                  c.isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          AppSpacing.gapH8,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onEdit != null) ...[
                OutlinedButton.icon(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 12),
                  label: const Text('Edit', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size.zero,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                      width: 0.8,
                    ),
                  ),
                ),
                AppSpacing.gapW8,
              ],
              OutlinedButton(
                onPressed: widget.onSnooze,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 0.8,
                  ),
                ),
                child:
                    const Text('Snooze +15m', style: TextStyle(fontSize: 11)),
              ),
              AppSpacing.gapW8,
              FilledButton.tonal(
                onPressed: () => widget.onToggle(!item.isDone),
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  backgroundColor: AppColors.moduleTime.withValues(alpha: 0.15),
                  foregroundColor: AppColors.moduleTime,
                ),
                child: Text(
                  item.isDone ? 'Undo' : 'Mark Done',
                  style:
                      const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
