import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';

/// Focus / Break / Long-break / Flow Stopwatch segmented control.
class PomodoroModeSelector extends StatelessWidget {
  final int selectedIndex;
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final ValueChanged<int> onModeSelected;
  final bool isDark;
  final bool showStopwatch;

  const PomodoroModeSelector({
    super.key,
    required this.selectedIndex,
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.onModeSelected,
    required this.isDark,
    this.showStopwatch = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
          width: 0.8,
        ),
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
          if (showStopwatch)
            _buildSegment(3, Icons.all_inclusive_rounded, 'Flow ⏱'),
        ],
      ),
    );
  }

  Widget _buildSegment(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    final Color activeColor;
    switch (index) {
      case 1:
        activeColor = AppColors.success;
        break;
      case 2:
        activeColor = AppColors.moduleNotes;
        break;
      case 3:
        activeColor = AppColors.moduleVault;
        break;
      case 0:
      default:
        activeColor = AppColors.moduleTime;
        break;
    }

    final color = isSelected
        ? activeColor
        : (isDark ? AppColors.darkTextCaption : AppColors.textCaption);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onModeSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.darkCardBackground : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: activeColor.withValues(alpha: isDark ? 0.35 : 0.22),
                    width: 0.85,
                  )
                : null,
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13.5, color: color),
                const SizedBox(width: 3.5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
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
