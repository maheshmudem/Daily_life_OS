import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/countdown_item_entity.dart';

/// Countdown card. Mirrors [PlannerItemCard]'s grid: leading visual, content
/// column, then a divider and an action row aligned to the content column.
class CountdownCard extends StatelessWidget {
  static const double _avatarSize = 44;
  static const double _contentInset = _avatarSize + AppSpacing.sm;

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
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusMd,
                ),
                child: Icon(
                  // ignore: non_const_argument_for_const_parameter
                  IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: color,
                  size: 22,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: headingColor,
                      ),
                    ),
                    AppSpacing.gapH4,
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: captionColor,
                            ),
                            AppSpacing.gapW4,
                            Text(
                              _formatDate(item.date),
                              style: TextStyle(
                                fontSize: 12,
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
              AppSpacing.gapW8,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(left: _contentInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.notes.isNotEmpty) ...[
                  AppSpacing.gapH12,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: AppColors.moduleNotes,
                        ),
                      ),
                      AppSpacing.gapW8,
                      Expanded(
                        child: Text(
                          item.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDark
                                ? AppColors.darkTextBody
                                : AppColors.textBody,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                AppSpacing.gapH12,
                Divider(height: 1, thickness: 1, color: dividerColor),
                AppSpacing.gapH12,
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onAddToPlanner,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 34),
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
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusSm,
                          ),
                          textStyle: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(
                          Icons.event_available_rounded,
                          size: 16,
                        ),
                        label: const Text('Add to Planner'),
                      ),
                    ),
                    AppSpacing.gapW8,
                    _SquareIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit countdown',
                      color: isDark
                          ? AppColors.darkTextBody
                          : AppColors.textBody,
                      isDark: isDark,
                      onPressed: onEdit,
                    ),
                    AppSpacing.gapW8,
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
      icon: Icon(icon, size: 18),
      color: color,
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 34),
        minimumSize: const Size(40, 34),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.border,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.radiusXs,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
