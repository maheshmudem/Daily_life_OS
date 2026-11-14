import 'package:flutter/material.dart';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/services.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/widgets/expandable_text_widget.dart';
import '../../domain/entities/countdown_item_entity.dart';

/// Editorial countdown card with urgency progress strip, advance-alert badge,
/// and content-proportional vertical sizing.
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
    final palette = context.palette;
    final textTheme = context.text;
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
      badgeColor = palette.caption;
    }

    // Subtle 60-day proximity bar for upcoming events
    final showProximityBar = daysLeft >= 0 && daysLeft <= 60;
    final proximityValue = daysLeft <= 0
        ? 1.0
        : (1.0 - (daysLeft / 60.0)).clamp(0.08, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: daysLeft == 0 || daysLeft == 1
              ? badgeColor.withValues(alpha: 0.45)
              : palette.divider,
        ),
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
            child: ColoredBox(color: color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 9),
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
                        color: color.withValues(
                          alpha: palette.isDark ? 0.20 : 0.12,
                        ),
                        borderRadius: AppRadius.radiusSm,
                      ),
                      child: Icon(_resolveIcon(item), color: color, size: 19),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExpandableTextWidget(
                            text: item.title,
                            collapsedMaxLines: 2,
                            characterThreshold: 45,
                            toggleColor: color,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14.5,
                              height: 1.3,
                              letterSpacing: -0.2,
                              fontWeight: FontWeight.w600,
                              color: palette.heading,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            spacing: 6,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: palette.caption,
                                    ),
                                    const SizedBox(width: 3.5),
                                    AppText(
                                      _formatDate(item.date),
                                      style: textTheme.labelSmall?.copyWith(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: palette.caption,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _Pill(label: item.category, color: color),
                              if (item.remindAdvance)
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 12.5,
                                  color: palette.caption,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.5,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(
                          alpha: palette.isDark ? 0.20 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText(
                        badgeText,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                if (showProximityBar) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: AppRadius.radiusFull,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      value: proximityValue,
                      backgroundColor: palette.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                    ),
                  ),
                ],

                if (item.notes.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted.withValues(
                        alpha: palette.isDark ? 0.55 : 0.75,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: palette.divider),
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
                          child: ExpandableTextWidget(
                            text: item.notes.trim(),
                            collapsedMaxLines: 2,
                            characterThreshold: 70,
                            toggleColor: AppColors.moduleNotes,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              height: 1.35,
                              color: palette.body,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xs),
                Divider(height: 1, thickness: 1, color: palette.divider),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onAddToPlanner();
                        },
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          elevation: 0,
                          backgroundColor: AppColors.moduleTime.withValues(
                            alpha: palette.isDark ? 0.22 : 0.13,
                          ),
                          foregroundColor: palette.isDark
                              ? AppColors.moduleTimeLight
                              : AppColors.moduleTimeDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          textStyle: context.text.captionBold.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(
                          Icons.event_available_rounded,
                          size: 14.5,
                        ),
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AppText('Add to Planner'),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _SquareIconButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit countdown',
                      color: palette.body,
                      palette: palette,
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _SquareIconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: 'Delete countdown',
                      color: AppColors.error,
                      palette: palette,
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

  IconData _resolveIcon(CountdownItemEntity item) {
    switch (item.category) {
      case 'Birthday':
        return Icons.cake_rounded;
      case 'Anniversary':
        return Icons.favorite_rounded;
      case 'Renewal':
        return Icons.directions_car_rounded;
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Milestone':
        return Icons.flag_rounded;
      case 'Event':
      default:
        return Icons.star_rounded;
    }
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
  final AppPalette palette;
  final VoidCallback onPressed;

  const _SquareIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.palette,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 15.5),
      color: color,
      style: IconButton.styleFrom(
        fixedSize: const Size(34, 30),
        minimumSize: const Size(34, 30),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: palette.divider),
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
