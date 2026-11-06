import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';
import 'expandable_text_widget.dart';

/// Best-in-class interactive habit row designed for unified grouped cards.
///
/// Features:
/// - Tactile circular check indicator on the left (toggles completion with smooth scale animation)
/// - Vibrant squircle tinted icon
/// - Full readable title (wraps up to 2 lines, expandable when long)
/// - Optional expandable description ("Show more / Show less")
/// - Subtitle metadata: category pill, status, reminder time, and 7-day mini consistency dots
/// - Compact streak pill with flame icon and tabular figures
class HabitBubbleWidget extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final int streakDays;
  final bool isDone;
  final bool isSkipped;
  final Color tintColor;
  final VoidCallback onTap;
  final VoidCallback? onDetailTap;
  final String? category;
  final String? scheduleLabel;
  final bool reminderEnabled;
  final String? reminderTime;
  final List<bool>? recentWeekDots;

  const HabitBubbleWidget({
    super.key,
    required this.title,
    this.description,
    required this.icon,
    required this.streakDays,
    required this.isDone,
    required this.tintColor,
    required this.onTap,
    this.isSkipped = false,
    this.onDetailTap,
    this.category,
    this.scheduleLabel,
    this.reminderEnabled = false,
    this.reminderTime,
    this.recentWeekDots,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    final statusText = isDone
        ? 'Completed today'
        : isSkipped
        ? 'Skipped for today'
        : (scheduleLabel != null && scheduleLabel!.isNotEmpty
              ? scheduleLabel!
              : 'Tap to mark done');

    return Semantics(
      button: true,
      toggled: isDone,
      label:
          '$title, $streakDays day streak, ${isDone
              ? "completed"
              : isSkipped
              ? "skipped"
              : "pending"}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            if (onDetailTap != null) {
              onDetailTap!();
            } else {
              onTap();
            }
          },
          onLongPress: onDetailTap != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onDetailTap!();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 11,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tactile check circle (always toggles completion directly)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: AppSpacing.sm + 4,
                      top: 5,
                      bottom: 2,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? AppColors.success
                            : isSkipped
                            ? AppColors.warning.withValues(alpha: 0.16)
                            : Colors.transparent,
                        border: Border.all(
                          color: isDone
                              ? AppColors.success
                              : isSkipped
                              ? AppColors.warning
                              : palette.border,
                          width: 1.5,
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                key: ValueKey('done'),
                                size: 14,
                                color: Colors.white,
                              )
                            : isSkipped
                            ? const Icon(
                                Icons.fast_forward_rounded,
                                key: ValueKey('skip'),
                                size: 13,
                                color: AppColors.warning,
                              )
                            : const SizedBox.shrink(key: ValueKey('empty')),
                      ),
                    ),
                  ),
                ),

                // 2. Tinted squircle icon badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: tintColor.withValues(
                      alpha: palette.isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: tintColor),
                ),
                const SizedBox(width: AppSpacing.sm + 2),

                // 3. Full Title + Metadata Wrap + Optional Expandable Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExpandableTextWidget(
                        text: title,
                        collapsedMaxLines: 2,
                        characterThreshold: 55,
                        toggleColor: tintColor,
                        style: text.titleSmall?.copyWith(
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: isDone ? palette.caption : palette.heading,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: palette.caption,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (category != null && category!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: tintColor.withValues(
                                  alpha: palette.isDark ? 0.16 : 0.10,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                category!,
                                style: text.labelSmall?.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: tintColor,
                                ),
                              ),
                            ),
                          Text(
                            statusText,
                            style: text.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: isDone || isSkipped
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isDone
                                  ? AppColors.success
                                  : isSkipped
                                  ? AppColors.warning
                                  : palette.caption,
                            ),
                          ),
                          if (reminderEnabled &&
                              reminderTime != null &&
                              reminderTime!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 11,
                                  color: palette.caption,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  reminderTime!,
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    color: palette.caption,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          if (recentWeekDots != null &&
                              recentWeekDots!.isNotEmpty)
                            _MiniWeekDots(
                              dots: recentWeekDots!,
                              accentColor: tintColor,
                            ),
                        ],
                      ),
                      if (description != null &&
                          description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ExpandableTextWidget(
                          text: description!.trim(),
                          collapsedMaxLines: 1,
                          characterThreshold: 45,
                          toggleColor: tintColor,
                          style: text.bodySmall?.copyWith(
                            fontSize: 11.5,
                            height: 1.35,
                            color: palette.caption,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),

                // 4. Streak badge & detail chevron
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StreakBadge(days: streakDays),
                      if (onDetailTap != null) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: palette.caption.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniWeekDots extends StatelessWidget {
  final List<bool> dots;
  final Color accentColor;

  const _MiniWeekDots({required this.dots, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < dots.length; i++)
          Container(
            width: 4.5,
            height: 4.5,
            margin: EdgeInsets.only(right: i < dots.length - 1 ? 2.5 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dots[i]
                  ? accentColor
                  : palette.border.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int days;

  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final active = days > 0;
    const flameColor = AppColors.focusPomodoro;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? flameColor.withValues(alpha: palette.isDark ? 0.18 : 0.10)
            : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 13,
            color: active ? flameColor : palette.caption,
          ),
          const SizedBox(width: 3),
          Text(
            '$days',
            style: context.text.labelMedium?.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: active ? flameColor : palette.caption,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 2),
          Text(
            'd',
            style: context.text.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: active ? flameColor : palette.caption,
            ),
          ),
        ],
      ),
    );
  }
}
