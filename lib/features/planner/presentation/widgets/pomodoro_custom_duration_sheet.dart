import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';

class PomodoroCustomDurationSheet extends StatefulWidget {
  final int initialWorkMinutes;
  final int initialShortBreakMinutes;
  final int initialLongBreakMinutes;
  final bool isDark;
  final void Function(int work, int shortBreak, int longBreak) onSave;

  const PomodoroCustomDurationSheet({
    super.key,
    required this.initialWorkMinutes,
    required this.initialShortBreakMinutes,
    required this.initialLongBreakMinutes,
    required this.isDark,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required int workMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    required bool isDark,
    required void Function(int work, int shortBreak, int longBreak) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PomodoroCustomDurationSheet(
        initialWorkMinutes: workMinutes,
        initialShortBreakMinutes: shortBreakMinutes,
        initialLongBreakMinutes: longBreakMinutes,
        isDark: isDark,
        onSave: onSave,
      ),
    );
  }

  @override
  State<PomodoroCustomDurationSheet> createState() =>
      _PomodoroCustomDurationSheetState();
}

class _PomodoroCustomDurationSheetState
    extends State<PomodoroCustomDurationSheet> {
  late int tempWork;
  late int tempShort;
  late int tempLong;

  @override
  void initState() {
    super.initState();
    tempWork = widget.initialWorkMinutes;
    tempShort = widget.initialShortBreakMinutes;
    tempLong = widget.initialLongBreakMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? AppColors.darkCardBackground : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardBg, borderRadius: AppRadius.topXxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? AppColors.darkDivider
                    : AppColors.divider,
                borderRadius: AppRadius.radiusFull,
              ),
            ),
          ),
          AppSpacing.gapH16,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customize Pomodoro Timer',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDurationStepper(
            'Focus Work Sprint',
            tempWork,
            'mins',
            (newVal) => setState(() => tempWork = newVal),
            min: 5,
            max: 120,
            step: 5,
          ),
          const SizedBox(height: 12),
          _buildDurationStepper(
            'Short Break Duration',
            tempShort,
            'mins',
            (newVal) => setState(() => tempShort = newVal),
            min: 1,
            max: 30,
            step: 1,
          ),
          const SizedBox(height: 12),
          _buildDurationStepper(
            'Long Break Duration',
            tempLong,
            'mins',
            (newVal) => setState(() => tempLong = newVal),
            min: 5,
            max: 60,
            step: 5,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.moduleTime,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.radiusMd,
                ),
              ),
              onPressed: () {
                widget.onSave(tempWork, tempShort, tempLong);
                Navigator.of(context).pop();
              },
              child: const Text(
                'Save Timer Settings',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationStepper(
    String title,
    int value,
    String unit,
    ValueChanged<int> onChanged, {
    required int min,
    required int max,
    required int step,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.darkSurfaceSecondary
            : AppColors.surfaceSecondary,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.isDark
                  ? AppColors.darkTextHeading
                  : AppColors.textHeading,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                onPressed: value > min ? () => onChanged(value - step) : null,
              ),
              Text(
                '$value $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.moduleTime,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                onPressed: value < max ? () => onChanged(value + step) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
