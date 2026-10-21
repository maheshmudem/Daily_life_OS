import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';

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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCardBackground
            : AppColors.surfaceSecondary,
        borderRadius: AppRadius.radiusFull,
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          _buildPill(0, '⚡ Deep Work (${workMinutes}m)'),
          _buildPill(1, '☕ Break (${shortBreakMinutes}m)'),
          _buildPill(2, '🌴 Long (${longBreakMinutes}m)'),
        ],
      ),
    );
  }

  Widget _buildPill(int index, String label) {
    final isSelected = selectedIndex == index;
    final activeColor = index == 0
        ? AppColors.moduleTime
        : (index == 1 ? AppColors.success : AppColors.moduleNotes);

    return Expanded(
      child: GestureDetector(
        onTap: () => onModeSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: AppRadius.radiusFull,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
