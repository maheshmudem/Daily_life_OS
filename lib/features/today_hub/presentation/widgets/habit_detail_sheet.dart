import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../domain/entities/habit_entity.dart';
import '../bloc/today_hub_bloc.dart';
import 'habit_editor_sheet.dart';

class HabitDetailSheet extends StatelessWidget {
  final int habitId;
  final HabitEntity initialHabit;

  const HabitDetailSheet({
    super.key,
    required this.habitId,
    required this.initialHabit,
  });

  static Future<void> show(BuildContext context, HabitEntity habit) {
    final bloc = context.read<TodayHubBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: HabitDetailSheet(habitId: habit.id, initialHabit: habit),
      ),
    );
  }

  static String _isoDate(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TodayHubBloc, TodayHubState>(
      builder: (context, state) {
        HabitEntity habit = initialHabit;
        if (state is TodayHubLoaded) {
          final found = state.habits.where((h) => h.id == habitId);
          if (found.isEmpty) {
            // Habit was deleted
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            });
          } else {
            habit = found.first;
          }
        }

        final palette = context.palette;
        final text = context.text;
        final accent = habit.color;
        final weeklyPct = (habit.weeklyCompletionRate * 100).round();
        final monthlyPct = (habit.monthlyCompletionRate * 100).round();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Last 7 days (oldest to newest: 6 days ago -> today)
        final last7Days = List.generate(
          7,
          (i) => today.subtract(Duration(days: 6 - i)),
        );

        // Last 30 days (oldest to newest: 29 days ago -> today)
        final last30Days = List.generate(
          30,
          (i) => today.subtract(Duration(days: 29 - i)),
        );

        return Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: palette.border, width: 0.8)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Top Header with Icon, Category, Schedule & Edit/Delete Actions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: palette.isDark ? 0.22 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(habit.icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(
                                    alpha: palette.isDark ? 0.18 : 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  habit.category,
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                  ),
                                ),
                              ),
                              Text(
                                habit.scheduleLabel,
                                softWrap: true,
                                style: text.labelSmall?.copyWith(
                                  fontSize: 11.5,
                                  color: palette.caption,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            habit.title,
                            style: text.titleMedium?.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: palette.heading,
                            ),
                          ),
                          if (habit.description.trim().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              habit.description.trim(),
                              style: text.bodySmall?.copyWith(
                                color: palette.caption,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit Habit',
                      onPressed: () {
                        final bloc = context.read<TodayHubBloc>();
                        HabitEditorSheet.show(
                          context,
                          existing: habit,
                          onSave: (updated) {
                            bloc.add(UpdateHabit(updated));
                          },
                          onDelete: () {
                            bloc.add(DeleteHabit(habit.id));
                          },
                        );
                      },
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: palette.heading,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Delete Habit',
                      onPressed: () async {
                        final bloc = context.read<TodayHubBloc>();
                        final confirmed = await ConfirmationDialog.show(
                          context,
                          title: 'Delete Habit?',
                          message:
                              'Are you sure you want to delete "${habit.title}"? This action cannot be undone.',
                          confirmLabel: 'Delete',
                        );
                        if (confirmed == true && context.mounted) {
                          Navigator.of(context).pop();
                          bloc.add(DeleteHabit(habit.id));
                        }
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Today Quick Action Buttons (Mark Completed / Skip Today)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: FilledButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          context.read<TodayHubBloc>().add(
                            ToggleHabit(habit.id),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: habit.isDoneToday
                              ? AppColors.success
                              : accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        icon: Icon(
                          habit.isDoneToday
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 18,
                        ),
                        label: Text(
                          habit.isDoneToday
                              ? 'Completed Today'
                              : 'Mark Completed',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.read<TodayHubBloc>().add(SkipHabit(habit.id));
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: habit.isSkippedToday
                              ? AppColors.warning
                              : palette.heading,
                          side: BorderSide(
                            color: habit.isSkippedToday
                                ? AppColors.warning
                                : palette.border,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        icon: Icon(
                          habit.isSkippedToday
                              ? Icons.fast_forward_rounded
                              : Icons.snooze_rounded,
                          size: 16,
                        ),
                        label: Text(
                          habit.isSkippedToday ? 'Skipped' : 'Skip Today',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. 4-KPI Stat Strip (Current Streak, Best Streak, 7D Rate, 30D Rate)
                Row(
                  children: [
                    Expanded(
                      child: _StatMiniTile(
                        label: 'Current Streak',
                        value: '${habit.streakDays}d',
                        icon: Icons.local_fire_department_rounded,
                        color: AppColors.focusPomodoro,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatMiniTile(
                        label: 'Best Streak',
                        value: '${habit.effectiveBestStreak}d',
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatMiniTile(
                        label: '7-Day Rate',
                        value: '$weeklyPct%',
                        icon: Icons.bolt_rounded,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatMiniTile(
                        label: '30-Day Rate',
                        value: '$monthlyPct%',
                        icon: Icons.insights_rounded,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 4. Interactive 7-Day Weekly Completion Tracker
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'LAST 7 DAYS (TAP ANY DAY TO TOGGLE)',
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: palette.caption,
                      ),
                    ),
                    Text(
                      '$weeklyPct% weekly score',
                      style: text.labelSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: last7Days.map((day) {
                      final iso = _isoDate(day);
                      final isToday = iso == _isoDate(today);
                      final done = habit.isCompletedOn(day);
                      final skipped = habit.isSkippedOn(day);
                      final dayName = DateFormat('E').format(day);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.read<TodayHubBloc>().add(
                            ToggleHabitDate(id: habit.id, isoDate: iso),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isToday ? 'Today' : dayName,
                              style: text.labelSmall?.copyWith(
                                fontSize: 10.5,
                                fontWeight: isToday
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isToday ? accent : palette.caption,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? AppColors.success
                                    : skipped
                                    ? AppColors.warning.withValues(alpha: 0.2)
                                    : palette.card,
                                border: Border.all(
                                  color: done
                                      ? AppColors.success
                                      : skipped
                                      ? AppColors.warning
                                      : isToday
                                      ? accent
                                      : palette.border,
                                  width: isToday && !done ? 1.6 : 1.2,
                                ),
                              ),
                              child: Center(
                                child: done
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : skipped
                                    ? const Icon(
                                        Icons.fast_forward_rounded,
                                        size: 14,
                                        color: AppColors.warning,
                                      )
                                    : Text(
                                        '${day.day}',
                                        style: text.labelSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: palette.body,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // 5. 30-Day Monthly Consistency Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '30-DAY MONTHLY CONSISTENCY',
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: palette.caption,
                      ),
                    ),
                    Text(
                      '${last30Days.where(habit.isCompletedOn).length}/30 days',
                      style: text.labelSmall?.copyWith(
                        color: palette.caption,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: last30Days.map((day) {
                      final iso = _isoDate(day);
                      final done = habit.isCompletedOn(day);
                      final skipped = habit.isSkippedOn(day);
                      return Tooltip(
                        message:
                            '${DateFormat('MMM d').format(day)}: ${done
                                ? "Completed"
                                : skipped
                                ? "Skipped"
                                : "Missed"}',
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<TodayHubBloc>().add(
                              ToggleHabitDate(id: habit.id, isoDate: iso),
                            );
                          },
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: done
                                  ? accent
                                  : skipped
                                  ? AppColors.warning.withValues(alpha: 0.25)
                                  : palette.card,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: done
                                    ? accent
                                    : skipped
                                    ? AppColors.warning
                                    : palette.border,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: done
                                    ? Colors.white
                                    : skipped
                                    ? AppColors.warning
                                    : palette.caption,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // 6. Reminder & Notification Quick Toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        habit.reminderEnabled
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_outlined,
                        size: 20,
                        color: habit.reminderEnabled ? accent : palette.caption,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Habit Reminder & Alert',
                              style: text.labelLarge?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: palette.heading,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              habit.reminderEnabled &&
                                      habit.reminderTime != null
                                  ? 'Active daily at ${habit.reminderTime}'
                                  : 'Notifications off for this habit',
                              style: text.labelSmall?.copyWith(
                                color: habit.reminderEnabled
                                    ? accent
                                    : palette.caption,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final bloc = context.read<TodayHubBloc>();
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (picked != null && context.mounted) {
                            final hour12 = picked.hourOfPeriod == 0
                                ? 12
                                : picked.hourOfPeriod;
                            final h = hour12.toString().padLeft(2, '0');
                            final m = picked.minute.toString().padLeft(2, '0');
                            final suffix = picked.period == DayPeriod.pm
                                ? 'PM'
                                : 'AM';
                            bloc.add(
                              UpdateHabit(
                                habit.copyWith(
                                  reminderEnabled: true,
                                  reminderTime: '$h:$m $suffix',
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          habit.reminderTime ?? 'Set Time',
                          style: text.labelMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Switch.adaptive(
                        value: habit.reminderEnabled,
                        activeTrackColor: accent,
                        onChanged: (enabled) {
                          context.read<TodayHubBloc>().add(
                            UpdateHabit(
                              habit.copyWith(
                                reminderEnabled: enabled,
                                reminderTime:
                                    enabled && habit.reminderTime == null
                                    ? '08:00 AM'
                                    : habit.reminderTime,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatMiniTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatMiniTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: text.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: palette.heading,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: text.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: palette.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
