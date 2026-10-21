import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../domain/entities/countdown_item_entity.dart';

class CountdownCard extends StatelessWidget {
  final CountdownItemEntity item;
  final bool isDark;
  final VoidCallback onAddToPlanner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CountdownCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onAddToPlanner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(item.colorValue);
    final now = DateTime.now();
    final difference =
        item.date.difference(DateTime(now.year, now.month, now.day));
    final daysLeft = difference.inDays;

    String daysBadgeText;
    Color badgeColor = color;
    if (daysLeft > 1) {
      daysBadgeText = '${daysLeft}d left';
    } else if (daysLeft == 1) {
      daysBadgeText = 'Tomorrow!';
      badgeColor = AppColors.focusPomodoro;
    } else if (daysLeft == 0) {
      daysBadgeText = 'Today! 🎉';
      badgeColor = AppColors.success;
    } else {
      daysBadgeText = '${daysLeft.abs()}d ago';
      badgeColor = AppColors.textCaption;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(
                  // ignore: non_const_argument_for_const_parameter
                  IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark
                            ? AppColors.darkTextHeading
                            : AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _formatDate(item.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: AppRadius.radiusSm,
                          ),
                          child: Text(
                            item.category,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Text(
                  daysBadgeText,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),

          // Optional Notes Preview
          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.surfaceSecondary,
                borderRadius: AppRadius.radiusSm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded,
                      size: 13, color: AppColors.moduleNotes),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkTextCaption
                            : AppColors.textBody,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Action Buttons: Add to Planner, Edit, Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onAddToPlanner,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  foregroundColor: AppColors.moduleTime,
                ),
                icon: const Icon(Icons.calendar_month_rounded, size: 14),
                label: const Text(
                  'Add to Planner',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                color: isDark
                    ? AppColors.darkTextCaption
                    : AppColors.textCaption,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onEdit,
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                color: AppColors.error.withValues(alpha: 0.7),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dayName = days[date.weekday - 1];
    final month = months[date.month - 1];
    return '$dayName, $month ${date.day}, ${date.year}';
  }
}
