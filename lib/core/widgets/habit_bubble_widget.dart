import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';

/// Compact interactive habit row designed for unified grouped cards.
///
/// Layout (2–3 lines, ~58–76dp tall):
/// ```
/// [check] [icon]  Title                               🔥 14d
///                 Category · Status · 🔔 07:00        ●●●●●●○
///                 One-line description (optional)
/// ```
/// - Tactile circular check indicator on the left toggles completion directly
/// - Vibrant squircle tinted icon
/// - Title wraps to at most 2 lines
/// - Single metadata line: category, status / schedule, reminder time
/// - Trailing column stacks the streak pill over the 7-day consistency dots
/// - Tapping the row (or long-pressing) opens the detail sheet
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

    // Short status copy keeps the single meta line from truncating on
    // 360dp phones at default font scale.
    final statusText = isDone
        ? 'Done today'
        : isSkipped
        ? 'Skipped today'
        : (scheduleLabel != null && scheduleLabel!.isNotEmpty
              ? scheduleLabel!
              : 'Tap to mark done');
    final statusColor = isDone
        ? AppColors.success
        : isSkipped
        ? AppColors.warning
        : palette.caption;
    final hasCategory = category != null && category!.isNotEmpty;
    final hasReminder =
        reminderEnabled && reminderTime != null && reminderTime!.isNotEmpty;
    final hasDots = recentWeekDots != null && recentWeekDots!.isNotEmpty;

    final metaStyle = text.labelSmall?.copyWith(
      fontSize: 11.5,
      height: 1.3,
      fontWeight: FontWeight.w500,
      color: palette.caption,
    );

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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                      right: 10,
                      top: 2,
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
                  decoration: BoxDecoration(
                    color: tintColor.withValues(
                      alpha: palette.isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: tintColor),
                ),
                const SizedBox(width: 10),

                // 3. Title + single metadata line
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                          fontSize: 14.5,
                          height: 1.25,
                          letterSpacing: -0.25,
                          fontWeight: FontWeight.w700,
                          color: isDone ? palette.caption : palette.heading,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: palette.caption,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(
                          children: [
                            if (hasCategory) ...[
                              TextSpan(
                                text: category,
                                style: metaStyle?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: tintColor,
                                ),
                              ),
                              const TextSpan(text: ' · '),
                            ],
                            TextSpan(
                              text: statusText,
                              style: metaStyle?.copyWith(
                                fontWeight: isDone || isSkipped
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: statusColor,
                              ),
                            ),
                            if (hasReminder) ...[
                              const TextSpan(text: ' · '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  Icons.notifications_active_outlined,
                                  size: 12,
                                  color: palette.caption,
                                ),
                              ),
                              TextSpan(
                                text: ' $reminderTime',
                                style: metaStyle?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: metaStyle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 4. Trailing: streak pill stacked over the 7-day dots
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StreakBadge(days: streakDays),
                    if (hasDots) ...[
                      const SizedBox(height: 5),
                      _MiniWeekDots(
                        dots: recentWeekDots!,
                        accentColor: tintColor,
                      ),
                    ],
                  ],
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
                  : palette.border.withValues(alpha: 0.9),
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
    final color = active ? flameColor : palette.caption;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? flameColor.withValues(alpha: palette.isDark ? 0.18 : 0.10)
            : palette.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '${days}d',
            style: context.text.labelMedium?.copyWith(
              fontSize: 11.5,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
