import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/planner_item_entity.dart';

/// Interactive 2×2 Eisenhower Priority Matrix view for the Planner workspace.
///
/// Organizes tasks into 4 actionable quadrants (`Do First · Urgent`,
/// `Schedule · High`, `Focus Plan · Medium`, `Light / Later · Low`) using
/// Daily Life OS semantic colors (`AppColors.error`, `AppColors.focusPomodoro`,
/// `AppColors.primary`, `AppColors.success`) and dynamic content-driven sizing
/// (empty quadrants collapse cleanly instead of wasting vertical height).
class PlannerMatrixView extends StatelessWidget {
  final List<PlannerItemEntity> items;
  final bool isDark;
  final ValueChanged<PlannerItemEntity> onToggle;
  final ValueChanged<PlannerItemEntity> onEdit;
  final ValueChanged<PlannerItemEntity> onStartFocus;
  final ValueChanged<String> onQuickAddWithPriority;

  const PlannerMatrixView({
    super.key,
    required this.items,
    required this.isDark,
    required this.onToggle,
    required this.onEdit,
    required this.onStartFocus,
    required this.onQuickAddWithPriority,
  });

  static String _normalizeQuadrant(String raw) {
    switch (raw) {
      case 'urgent':
      case 'urgent_important':
        return 'urgent';
      case 'high':
      case 'urgent_not_important':
        return 'high';
      case 'low':
      case 'neither':
        return 'low';
      case 'medium':
      case 'important_not_urgent':
      default:
        return 'medium';
    }
  }

  @override
  Widget build(BuildContext context) {
    final doFirst = <PlannerItemEntity>[];
    final schedule = <PlannerItemEntity>[];
    final focusPlan = <PlannerItemEntity>[];
    final later = <PlannerItemEntity>[];

    for (final item in items) {
      switch (_normalizeQuadrant(item.priority)) {
        case 'urgent':
          doFirst.add(item);
        case 'high':
          schedule.add(item);
        case 'low':
          later.add(item);
        case 'medium':
        default:
          focusPlan.add(item);
      }
    }

    final quadrants = [
      _QuadrantConfig(
        priorityKey: 'urgent',
        title: 'Do First',
        subtitle: 'Urgent & Critical',
        accent: AppColors.error,
        icon: Icons.local_fire_department_rounded,
        items: doFirst,
      ),
      _QuadrantConfig(
        priorityKey: 'high',
        title: 'Schedule',
        subtitle: 'High Impact',
        accent: AppColors.focusPomodoro,
        icon: Icons.bolt_rounded,
        items: schedule,
      ),
      _QuadrantConfig(
        priorityKey: 'medium',
        title: 'Focus Plan',
        subtitle: 'Steady Progress',
        accent: AppColors.primary,
        icon: Icons.track_changes_rounded,
        items: focusPlan,
      ),
      _QuadrantConfig(
        priorityKey: 'low',
        title: 'Light / Later',
        subtitle: 'Low Urgency',
        accent: AppColors.success,
        icon: Icons.eco_rounded,
        items: later,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTwoColumn = constraints.maxWidth >= 540;

          if (isTwoColumn) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildQuadrant(context, quadrants[0])),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _buildQuadrant(context, quadrants[1])),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildQuadrant(context, quadrants[2])),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _buildQuadrant(context, quadrants[3])),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < quadrants.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xs),
                _buildQuadrant(context, quadrants[i]),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuadrant(BuildContext context, _QuadrantConfig cfg) {
    final palette = context.palette;
    final textTheme = context.text;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: cfg.items.isNotEmpty
              ? cfg.accent.withValues(alpha: palette.isDark ? 0.34 : 0.26)
              : palette.divider,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quadrant Tinted Header
          Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cfg.accent.withValues(alpha: palette.isDark ? 0.16 : 0.08),
                  cfg.accent.withValues(alpha: palette.isDark ? 0.03 : 0.01),
                ],
              ),
              border: Border(bottom: BorderSide(color: palette.divider)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: cfg.accent.withValues(
                      alpha: palette.isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(cfg.icon, size: 14, color: cfg.accent),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cfg.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                                color: palette.heading,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: cfg.accent.withValues(alpha: 0.14),
                              borderRadius: AppRadius.radiusFull,
                            ),
                            child: Text(
                              '${cfg.items.length}',
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: cfg.accent,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        cfg.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: palette.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Add ${cfg.title} task',
                  child: InkWell(
                    key: ValueKey('matrix_add_${cfg.priorityKey}'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onQuickAddWithPriority(cfg.priorityKey);
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: cfg.accent.withValues(
                          alpha: palette.isDark ? 0.20 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: cfg.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Quadrant Task List or Compact Empty Prompt (sized to content)
          if (cfg.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 10,
              ),
              child: Text(
                'No ${cfg.title.toLowerCase()} tasks — tap + to add',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  color: palette.caption,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  for (var i = 0; i < cfg.items.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        indent: 36,
                        endIndent: 10,
                        color: palette.divider,
                      ),
                    _MatrixTaskTile(
                      item: cfg.items[i],
                      accent: cfg.accent,
                      onToggle: () => onToggle(cfg.items[i]),
                      onEdit: () => onEdit(cfg.items[i]),
                      onStartFocus: () => onStartFocus(cfg.items[i]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuadrantConfig {
  final String priorityKey;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<PlannerItemEntity> items;

  const _QuadrantConfig({
    required this.priorityKey,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.items,
  });
}

class _MatrixTaskTile extends StatelessWidget {
  final PlannerItemEntity item;
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onStartFocus;

  const _MatrixTaskTile({
    required this.item,
    required this.accent,
    required this.onToggle,
    required this.onEdit,
    required this.onStartFocus,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textTheme = context.text;

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkResponse(
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle();
              },
              radius: 16,
              child: Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.only(top: 1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isDone ? accent : Colors.transparent,
                  border: Border.all(
                    color: item.isDone
                        ? accent
                        : accent.withValues(alpha: 0.72),
                    width: 1.7,
                  ),
                ),
                child: item.isDone
                    ? const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: item.isDone ? palette.caption : palette.heading,
                      decoration: item.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2.5),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      if ((item.startTime ?? '').isNotEmpty)
                        Text(
                          item.startTime!,
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: item.isOverdue
                                ? AppColors.error
                                : palette.caption,
                          ),
                        ),
                      Text(
                        item.category,
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: item.color,
                        ),
                      ),
                      if (item.checklist.isNotEmpty)
                        Text(
                          '✓ ${item.checklistDoneCount}/${item.checklist.length}',
                          style: AppTextStyles.captionBold.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.moduleTimeDark,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (!item.isDone) ...[
              const SizedBox(width: 4),
              Tooltip(
                message: 'Start Focus Sprint',
                child: InkWell(
                  borderRadius: AppRadius.radiusXs,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onStartFocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(Icons.bolt_rounded, size: 15, color: accent),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
