import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/app_dropdown_menu.dart';
import '../../domain/entities/planner_item_entity.dart';

/// Reminder card used in the Planner list.
///
/// Layout (all cards share the same grid so lists line up vertically):
///   [check] Title ................................ [priority] [⋯]
///           meta · meta · meta
///           notes
///           ───────────────────────────────────────────────
///           [ Edit ] [ Snooze +15m ] [ Mark Done ]
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
  static const double _checkSize = 20;
  static const double _titleLineHeight = 20;
  static const double _contentInset = _checkSize + 10;

  bool _isExpanded = false;

  bool get _isDark => widget.isDark;
  Color get _headingColor =>
      _isDark ? AppColors.darkTextHeading : AppColors.textHeading;
  Color get _captionColor =>
      _isDark ? AppColors.darkTextCaption : AppColors.textCaption;
  Color get _dividerColor =>
      _isDark ? AppColors.darkDivider : AppColors.divider;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    final Color borderColor;
    if (item.isOverdue) {
      borderColor = AppColors.error.withValues(alpha: 0.4);
    } else if (item.isDone) {
      borderColor = AppColors.success.withValues(alpha: 0.3);
    } else {
      borderColor = _dividerColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDark
            ? AppColors.darkCardBackground
            : AppColors.cardBackground,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: borderColor, width: 0.85),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCheck(item),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: widget.onEdit,
                  borderRadius: AppRadius.radiusXs,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleRow(item),
                      const SizedBox(height: 4),
                      _buildMeta(item),
                      if (item.notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: _isDark
                                ? AppColors.darkTextBody
                                : AppColors.textBody,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _buildMenu(item),
            ],
          ),

          if (_isExpanded && item.checklist.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: _contentInset),
              child: _buildChecklist(item),
            ),
          ],

          const SizedBox(height: 8),
          Divider(height: 1, thickness: 0.8, color: _dividerColor),
          const SizedBox(height: 8),
          _buildActions(item),
        ],
      ),
    );
  }

  // ── Leading check ─────────────────────────────────────────────────────────
  Widget _buildCheck(PlannerItemEntity item) {
    final isDone = item.isDone;
    return Semantics(
      checked: isDone,
      button: true,
      child: InkResponse(
        onTap: () => widget.onToggle(!isDone),
        radius: 18,
        child: SizedBox(
          height: _titleLineHeight,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: _checkSize,
              height: _checkSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.moduleTime : Colors.transparent,
                border: Border.all(
                  color: isDone
                      ? AppColors.moduleTime
                      : (item.isOverdue
                            ? AppColors.error
                            : (_isDark
                                  ? AppColors.darkBorder
                                  : AppColors.textCaption)),
                  width: 1.8,
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  // ── Title + priority ──────────────────────────────────────────────────────
  Widget _buildTitleRow(PlannerItemEntity item) {
    final showPriority = item.priority == 'urgent' || item.priority == 'high';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              height: _titleLineHeight / 13.5,
              fontWeight: FontWeight.w600,
              color: item.isDone ? _captionColor : _headingColor,
              decoration: item.isDone ? TextDecoration.lineThrough : null,
              decorationColor: _captionColor,
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
  Widget _buildMeta(PlannerItemEntity item) {
    final metaColor = item.isOverdue ? AppColors.error : _captionColor;
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
        if (item.isRecurring)
          _MetaItem(
            icon: Icons.repeat_rounded,
            label: item.recurrenceSummary,
            color: AppColors.moduleTime,
          ),
        if (item.reminderOffsetMinutes > 0)
          _MetaItem(
            icon: Icons.notifications_none_rounded,
            label: '${item.reminderOffsetMinutes}m early',
            color: _captionColor,
          ),
        if (item.checklist.isNotEmpty)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
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

  // ── Expanded checklist ────────────────────────────────────────────────────
  Widget _buildChecklist(PlannerItemEntity item) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: _isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.surfaceSecondary,
        borderRadius: AppRadius.radiusSm,
      ),
      child: Column(
        children: item.checklist.map((c) {
          return InkWell(
            borderRadius: AppRadius.radiusXs,
            onTap: () => _setChecklistItem(item, c, !c.isDone),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: Checkbox(
                      value: c.isDone,
                      activeColor: AppColors.moduleTime,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.radiusXs,
                      ),
                      onChanged: (val) =>
                          _setChecklistItem(item, c, val ?? false),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      c.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: c.isDone ? _captionColor : _headingColor,
                        decoration: c.isDone
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
    onChanged(
      item.checklist
          .map((c) => c.id == target.id ? c.copyWith(isDone: isDone) : c)
          .toList(),
    );
  }

  // ── Footer actions (full card width so left/right edges align strictly) ──
  Widget _buildActions(PlannerItemEntity item) {
    final outlinedStyle = OutlinedButton.styleFrom(
      minimumSize: const Size(0, 28),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      foregroundColor: _isDark ? AppColors.darkTextBody : AppColors.textBody,
      side: BorderSide(
        color: _isDark ? AppColors.darkDivider : AppColors.divider,
        width: 0.85,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );

    return Row(
      children: [
        if (widget.onEdit != null) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onEdit,
              style: outlinedStyle,
              icon: const Icon(Icons.edit_outlined, size: 13),
              label: const Text('Edit'),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onSnooze,
            style: outlinedStyle,
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Snooze +15m'),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FilledButton(
            onPressed: () => widget.onToggle(!item.isDone),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              elevation: 0,
              backgroundColor: item.isDone
                  ? (_isDark
                        ? AppColors.darkSurfaceSecondary
                        : AppColors.surfaceSecondary)
                  : AppColors.moduleTime.withValues(alpha: 0.14),
              foregroundColor: item.isDone
                  ? _captionColor
                  : (_isDark
                        ? AppColors.moduleTimeLight
                        : AppColors.moduleTime),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(item.isDone ? 'Undo' : 'Mark Done'),
          ),
        ),
      ],
    );
  }

  // ── Overflow menu ─────────────────────────────────────────────────────────
  Widget _buildMenu(PlannerItemEntity item) {
    return AppDropdownMenu<String>(
      tooltip: 'More actions',
      offset: const Offset(0, 6),
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
      child: SizedBox(
        width: 24,
        height: _titleLineHeight,
        child: Align(
          alignment: Alignment.centerRight,
          child: Icon(
            Icons.more_horiz_rounded,
            size: 18,
            color: _isDark ? AppColors.darkIconColor : AppColors.iconColor,
          ),
        ),
      ),
    );
  }
}

/// Icon + text metadata used under the title (no box, so the line stays calm).
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
        const SizedBox(width: 3.5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Small tinted label (category, priority, overdue).
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: letterSpacing,
          color: color,
        ),
      ),
    );
  }
}
