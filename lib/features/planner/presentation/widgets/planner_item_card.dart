import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../domain/entities/planner_item_entity.dart';

class PlannerItemCard extends StatelessWidget {
  final PlannerItemEntity item;
  final bool isDark;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onSnooze;

  const PlannerItemCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onToggle,
    required this.onDelete,
    required this.onSnooze,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: item.isDone
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkDivider : AppColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: item.isDone,
                activeColor: AppColors.moduleTime,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                onChanged: onToggle,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading,
                        decoration:
                            item.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.timeRange.isNotEmpty)
                          Text(
                            item.timeRange,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextCaption
                                  : AppColors.textCaption,
                            ),
                          ),
                        if (item.category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.14),
                              borderRadius: AppRadius.radiusSm,
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: item.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error.withValues(alpha: 0.6),
                  size: 18,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onSnooze,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child:
                    const Text('Snooze +15m', style: TextStyle(fontSize: 11)),
              ),
              AppSpacing.gapW8,
              FilledButton.tonal(
                onPressed: () => onToggle(!item.isDone),
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
