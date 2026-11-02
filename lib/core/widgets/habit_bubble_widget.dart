import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/theme_context.dart';

/// Best-in-class habit row designed for unified grouped cards.
///
/// Features:
/// - Tactile circular check indicator on the left
/// - Vibrant squircle tinted icon
/// - Title with strike-through and soft dimming on completion
/// - Subtitle status ('Completed today' or 'Tap to mark done')
/// - Compact streak pill with flame icon and tabular figures
class HabitBubbleWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final int streakDays;
  final bool isDone;
  final Color tintColor;
  final VoidCallback onTap;

  const HabitBubbleWidget({
    super.key,
    required this.title,
    required this.icon,
    required this.streakDays,
    required this.isDone,
    required this.tintColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Semantics(
      button: true,
      toggled: isDone,
      label:
          '$title, $streakDays day streak, ${isDone ? "completed" : "pending"}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                // 1. Tactile check circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: isDone ? AppColors.success : palette.border,
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: AppSpacing.md),

                // 2. Tinted squircle icon badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: tintColor.withValues(
                      alpha: palette.isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: tintColor),
                ),
                const SizedBox(width: AppSpacing.sm + 4),

                // 3. Title + helper subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: isDone ? palette.caption : palette.heading,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: palette.caption,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDone ? 'Completed today' : 'Tap to mark done',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: isDone
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isDone ? AppColors.success : palette.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // 4. Streak badge
                _StreakBadge(days: streakDays),
              ],
            ),
          ),
        ),
      ),
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
