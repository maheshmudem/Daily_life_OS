import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';

/// Focus / Break / Long-break segmented control. Shares its geometry with
/// the Reminders status segments (44px tall, 12px radius).
class PomodoroModeSelector extends StatelessWidget {
  final int selectedIndex;
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final ValueChanged<int> onModeSelected;
  final bool isDark;

  const PomodoroModeSelector({
    super.key,
    required this.selectedIndex,
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.onModeSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildSegment(0, Icons.bolt_rounded, 'Focus (${workMinutes}m)'),
          _buildSegment(
            1,
            Icons.coffee_rounded,
            'Break (${shortBreakMinutes}m)',
          ),
          _buildSegment(
            2,
            Icons.weekend_rounded,
            'Long (${longBreakMinutes}m)',
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    final activeColor = index == 0
        ? AppColors.moduleTime
        : (index == 1 ? AppColors.success : AppColors.moduleNotes);
    final color = isSelected
        ? activeColor
        : (isDark ? AppColors.darkTextCaption : AppColors.textCaption);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onModeSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkCardBackground : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                AppSpacing.gapW4,
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark
                              ? AppColors.darkTextHeading
                              : AppColors.textHeading)
                        : color,
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
