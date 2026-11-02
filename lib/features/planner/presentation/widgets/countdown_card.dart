import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/countdown_item_entity.dart';

/// Compact countdown card with full-width aligned divider and action footer.
class CountdownCard extends StatelessWidget {
  static const double _avatarSize = 38;

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
    final daysLeft = item.date
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;

    final String badgeText;
    Color badgeColor = color;
    if (daysLeft > 1) {
      badgeText = '${daysLeft}d left';
    } else if (daysLeft == 1) {
      badgeText = 'Tomorrow';
      badgeColor = AppColors.focusPomodoro;
    } else if (daysLeft == 0) {
      badgeText = 'Today';
      badgeColor = AppColors.success;
    } else {
      badgeText = '${daysLeft.abs()}d ago';
      badgeColor = AppColors.textCaption;
    }

    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final captionColor = isDark
        ? AppColors.darkTextCaption
        : AppColors.textCaption;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(color: dividerColor, width: 0.85),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  // ignore: non_const_argument_for_const_parameter
                  IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: captionColor,
                            ),
                            const SizedBox(width: 3.5),
                            Text(
                              _formatDate(item.date),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: captionColor,
                              ),
                            ),
                          ],
                        ),
                        _Pill(label: item.category, color: color),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),

          if (item.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 13.5,
                      color: AppColors.moduleNotes,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.notes,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark
                            ? AppColors.darkTextBody
                            : AppColors.textBody,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          Divider(height: 1, thickness: 0.8, color: dividerColor),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddToPlanner,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    elevation: 0,
                    backgroundColor: AppColors.moduleTime.withValues(
                      alpha: 0.14,
                    ),
                    foregroundColor: isDark
                        ? AppColors.moduleTimeLight
                        : AppColors.moduleTime,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.event_available_rounded, size: 14),
                  label: const Text('Add to Planner'),
                ),
              ),
              const SizedBox(width: 6),
              _SquareIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit countdown',
                color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                isDark: isDark,
                onPressed: onEdit,
              ),
              const SizedBox(width: 6),
              _SquareIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete countdown',
                color: AppColors.error,
                isDark: isDark,
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
      'Dec',
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool isDark;
  final VoidCallback onPressed;

  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 15),
      color: color,
      style: IconButton.styleFrom(
        fixedSize: const Size(32, 30),
        minimumSize: const Size(32, 30),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
          width: 0.85,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

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
          color: color,
        ),
      ),
    );
  }
}
