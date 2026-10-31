import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';

/// Interactive one-tap habit bubble with streak badge and smooth completion state.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDone
              ? tintColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark
                    ? AppColors.darkCardBackground
                    : AppColors.cardBackground),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isDone
                ? tintColor.withValues(alpha: 0.6)
                : (isDark ? AppColors.darkDivider : AppColors.divider),
            width: isDone ? 1.5 : 1,
          ),
          boxShadow: isDone
              ? [
                  BoxShadow(
                    color: tintColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Bubble with Status Indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: isDone
                      ? tintColor
                      : tintColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  child: Icon(
                    isDone ? Icons.check_rounded : icon,
                    size: 18,
                    color: isDone ? Colors.white : tintColor,
                  ),
                ),
                if (isDone)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Habit Name
            Text(
              title,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isDone ? FontWeight.w700 : FontWeight.w600,
                color: isDone
                    ? (isDark
                          ? AppColors.darkTextHeading
                          : AppColors.textHeading)
                    : (isDark ? AppColors.darkTextBody : AppColors.textBody),
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 4),

            // Streak Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceSecondary
                    : AppColors.surfaceSecondary,
                borderRadius: AppRadius.radiusSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 10)),
                  const SizedBox(width: 2),
                  Text(
                    '${streakDays}d',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextCaption
                          : AppColors.textCaption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
