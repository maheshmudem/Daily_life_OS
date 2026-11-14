import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';

class PomodoroAdvancedConfig {
  final int workMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int totalRounds;
  final int dailyGoalSessions;
  final bool autoStartBreaks;
  final bool autoStartWork;
  final bool strictMode;
  final bool voiceCoach;

  const PomodoroAdvancedConfig({
    required this.workMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
    required this.totalRounds,
    required this.dailyGoalSessions,
    required this.autoStartBreaks,
    required this.autoStartWork,
    required this.strictMode,
    required this.voiceCoach,
  });
}

class PomodoroCustomDurationSheet extends StatefulWidget {
  final int initialWorkMinutes;
  final int initialShortBreakMinutes;
  final int initialLongBreakMinutes;
  final int initialTotalRounds;
  final int initialDailyGoalSessions;
  final bool initialAutoStartBreaks;
  final bool initialAutoStartWork;
  final bool initialStrictMode;
  final bool initialVoiceCoach;
  final bool isDark;
  final void Function(int work, int shortBreak, int longBreak) onSave;
  final ValueChanged<PomodoroAdvancedConfig>? onSaveAdvanced;

  const PomodoroCustomDurationSheet({
    super.key,
    required this.initialWorkMinutes,
    required this.initialShortBreakMinutes,
    required this.initialLongBreakMinutes,
    this.initialTotalRounds = 4,
    this.initialDailyGoalSessions = 4,
    this.initialAutoStartBreaks = false,
    this.initialAutoStartWork = false,
    this.initialStrictMode = false,
    this.initialVoiceCoach = false,
    required this.isDark,
    required this.onSave,
    this.onSaveAdvanced,
  });

  static Future<void> show(
    BuildContext context, {
    required int workMinutes,
    required int shortBreakMinutes,
    required int longBreakMinutes,
    int totalRounds = 4,
    int dailyGoalSessions = 4,
    bool autoStartBreaks = false,
    bool autoStartWork = false,
    bool strictMode = false,
    bool voiceCoach = false,
    required bool isDark,
    required void Function(int work, int shortBreak, int longBreak) onSave,
    ValueChanged<PomodoroAdvancedConfig>? onSaveAdvanced,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PomodoroCustomDurationSheet(
        initialWorkMinutes: workMinutes,
        initialShortBreakMinutes: shortBreakMinutes,
        initialLongBreakMinutes: longBreakMinutes,
        initialTotalRounds: totalRounds,
        initialDailyGoalSessions: dailyGoalSessions,
        initialAutoStartBreaks: autoStartBreaks,
        initialAutoStartWork: autoStartWork,
        initialStrictMode: strictMode,
        initialVoiceCoach: voiceCoach,
        isDark: isDark,
        onSave: onSave,
        onSaveAdvanced: onSaveAdvanced,
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
  late int tempRounds;
  late int tempDailyGoal;
  late bool tempAutoBreaks;
  late bool tempAutoWork;
  late bool tempStrict;
  late bool tempVoiceCoach;

  @override
  void initState() {
    super.initState();
    tempWork = widget.initialWorkMinutes;
    tempShort = widget.initialShortBreakMinutes;
    tempLong = widget.initialLongBreakMinutes;
    tempRounds = widget.initialTotalRounds;
    tempDailyGoal = widget.initialDailyGoalSessions;
    tempAutoBreaks = widget.initialAutoStartBreaks;
    tempAutoWork = widget.initialAutoStartWork;
    tempStrict = widget.initialStrictMode;
    tempVoiceCoach = widget.initialVoiceCoach;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cardBg = palette.card;
    final headingColor = palette.heading;
    final captionColor = palette.caption;

    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadius.topXxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: AppRadius.radiusFull,
                  ),
                ),
              ),
              AppSpacing.gapH12,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Customize Pomodoro Timer',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: headingColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDurationStepper(
                'Focus Work Sprint',
                tempWork,
                'mins',
                (newVal) => setState(() => tempWork = newVal),
                min: 5,
                max: 120,
                step: 5,
              ),
              const SizedBox(height: 8),
              _buildDurationStepper(
                'Short Break Duration',
                tempShort,
                'mins',
                (newVal) => setState(() => tempShort = newVal),
                min: 1,
                max: 30,
                step: 1,
              ),
              const SizedBox(height: 8),
              _buildDurationStepper(
                'Long Break Duration',
                tempLong,
                'mins',
                (newVal) => setState(() => tempLong = newVal),
                min: 5,
                max: 60,
                step: 5,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDurationStepper(
                      'Cycle Rounds',
                      tempRounds,
                      'x',
                      (newVal) => setState(() => tempRounds = newVal),
                      min: 2,
                      max: 8,
                      step: 1,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDurationStepper(
                      'Daily Goal',
                      tempDailyGoal,
                      'sprints',
                      (newVal) => setState(() => tempDailyGoal = newVal),
                      min: 1,
                      max: 16,
                      step: 1,
                      compact: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'FOCUS AUTOMATION & DISCIPLINE',
                style: AppTextStyles.overline.copyWith(
                  color: captionColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildToggleRow(
                icon: Icons.autorenew_rounded,
                iconColor: AppColors.success,
                title: 'Auto-Start Breaks',
                subtitle: 'Begin break timer automatically after each sprint',
                value: tempAutoBreaks,
                onChanged: (v) => setState(() => tempAutoBreaks = v),
              ),
              const SizedBox(height: 6),
              _buildToggleRow(
                icon: Icons.bolt_rounded,
                iconColor: AppColors.moduleTime,
                title: 'Auto-Start Next Sprint',
                subtitle: 'Continuously chain focus sprints after breaks end',
                value: tempAutoWork,
                onChanged: (v) => setState(() => tempAutoWork = v),
              ),
              const SizedBox(height: 6),
              _buildToggleRow(
                icon: Icons.lock_outline_rounded,
                iconColor: AppColors.error,
                title: 'Strict Focus Mode',
                subtitle:
                    'Confirm before resetting or skipping an active sprint',
                value: tempStrict,
                onChanged: (v) => setState(() => tempStrict = v),
              ),
              const SizedBox(height: 6),
              _buildToggleRow(
                icon: Icons.record_voice_over_rounded,
                iconColor: AppColors.primary,
                title: 'Voice Coach Cues',
                subtitle:
                    'Speak encouraging audio prompts on sprint transitions',
                value: tempVoiceCoach,
                onChanged: (v) => setState(() => tempVoiceCoach = v),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.moduleTime,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusMd,
                    ),
                  ),
                  onPressed: () {
                    widget.onSave(tempWork, tempShort, tempLong);
                    widget.onSaveAdvanced?.call(
                      PomodoroAdvancedConfig(
                        workMinutes: tempWork,
                        shortBreakMinutes: tempShort,
                        longBreakMinutes: tempLong,
                        totalRounds: tempRounds,
                        dailyGoalSessions: tempDailyGoal,
                        autoStartBreaks: tempAutoBreaks,
                        autoStartWork: tempAutoWork,
                        strictMode: tempStrict,
                        voiceCoach: tempVoiceCoach,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Save Timer Settings',
                    style: AppTextStyles.buttonLabel.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    bool compact = false,
  }) {
    final palette = context.palette;
    final textTheme = context.text;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: palette.heading,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 19),
                onPressed: value > min ? () => onChanged(value - step) : null,
              ),
              Text(
                '$value $unit',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 12 : 13,
                  color: AppColors.moduleTime,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 19),
                onPressed: value < max ? () => onChanged(value + step) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final palette = context.palette;
    final textTheme = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: AppRadius.radiusMd,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: palette.heading,
                  ),
                ),
                Text(
                  subtitle,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    color: palette.caption,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.moduleTime,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
