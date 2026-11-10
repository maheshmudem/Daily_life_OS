import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../domain/entities/habit_entity.dart';
import '../bloc/today_hub_bloc.dart';
import 'habit_detail_sheet.dart';
import 'habit_editor_sheet.dart';

class ManageHabitsSheet extends StatefulWidget {
  const ManageHabitsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<TodayHubBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const FractionallySizedBox(
          heightFactor: 0.90,
          child: ManageHabitsSheet(),
        ),
      ),
    );
  }

  @override
  State<ManageHabitsSheet> createState() => _ManageHabitsSheetState();
}

class _ManageHabitsSheetState extends State<ManageHabitsSheet> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Morning',
    'Health',
    'Deep Work',
    'Mindfulness',
    'Evening',
    'General',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: palette.border, width: 0.8)),
      ),
      child: BlocBuilder<TodayHubBloc, TodayHubState>(
        builder: (context, state) {
          final habits = state is TodayHubLoaded
              ? state.habits
              : <HabitEntity>[];
          final completedToday = habits.where((h) => h.isDoneToday).length;
          final skippedToday = habits
              .where((h) => h.isSkippedToday && !h.isDoneToday)
              .length;
          final weeklyScore = state is TodayHubLoaded
              ? (state.overallWeeklyConsistency * 100).round()
              : 0;
          final longestStreak = state is TodayHubLoaded
              ? state.longestActiveStreak
              : 0;

          final filtered = habits.where((h) {
            final matchCat =
                _selectedCategory == 'All' ||
                h.category.toLowerCase() == _selectedCategory.toLowerCase();
            final q = _searchQuery.trim().toLowerCase();
            final matchSearch =
                q.isEmpty ||
                h.title.toLowerCase().contains(q) ||
                h.description.toLowerCase().contains(q) ||
                h.category.toLowerCase().contains(q);
            return matchCat && matchSearch;
          }).toList();

          return Column(
            children: [
              // 1. Drag Handle + Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: palette.border,
                        borderRadius: AppRadius.radiusFull,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: palette.isDark ? 0.22 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.repeat_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Habits & Micro-Routines Studio',
                                softWrap: true,
                                style: text.titleMedium?.copyWith(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: palette.heading,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${habits.length} routines • $completedToday done • ${skippedToday > 0 ? "$skippedToday skipped • " : ""}$weeklyScore% 7d consistency',
                                softWrap: true,
                                style: text.labelSmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: palette.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () {
                            final bloc = context.read<TodayHubBloc>();
                            HabitEditorSheet.show(
                              context,
                              onSave: (newHabit) {
                                bloc.add(AddHabit(newHabit));
                              },
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 8,
                            ),
                            minimumSize: const Size(0, 34),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text(
                            'New Habit',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Summary KPI Strip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StudioMetric(
                          label: 'Completed',
                          value: '$completedToday/${habits.length}',
                          color: AppColors.success,
                        ),
                      ),
                      Container(width: 1, height: 22, color: palette.border),
                      Expanded(
                        child: _StudioMetric(
                          label: '7-Day Rate',
                          value: '$weeklyScore%',
                          color: AppColors.primary,
                        ),
                      ),
                      Container(width: 1, height: 22, color: palette.border),
                      Expanded(
                        child: _StudioMetric(
                          label: 'Top Streak',
                          value: '${longestStreak}d',
                          color: AppColors.focusPomodoro,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 3. Search & Category Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 16,
                            color: palette.caption,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              onChanged: (val) =>
                                  setState(() => _searchQuery = val),
                              style: text.bodySmall?.copyWith(
                                color: palette.heading,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Search habits, cues, or categories...',
                                hintStyle: text.labelSmall?.copyWith(
                                  color: palette.caption,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 28,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final active = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : palette.surfaceMuted,
                                borderRadius: AppRadius.radiusFull,
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : palette.border,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: text.labelSmall?.copyWith(
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active ? Colors.white : palette.body,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: palette.border),

              // 4. Habits List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome_mosaic_outlined,
                                size: 36,
                                color: palette.caption,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No habits match your filter',
                                style: text.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: palette.heading,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create a new micro-routine or reset your search filters.',
                                textAlign: TextAlign.center,
                                style: text.bodySmall?.copyWith(
                                  color: palette.caption,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final h = filtered[index];
                          return _ManageHabitCard(habit: h);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudioMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StudioMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: text.titleSmall?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: text.labelSmall?.copyWith(
                fontSize: 11,
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

class _ManageHabitCard extends StatelessWidget {
  final HabitEntity habit;

  const _ManageHabitCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final accent = habit.color;
    final weeklyRate = (habit.weeklyCompletionRate * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Check Circle + Icon Badge + Full Unclipped Title, Description & Metadata
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Complete toggle button
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<TodayHubBloc>().add(ToggleHabit(habit.id));
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: habit.isDoneToday
                          ? AppColors.success
                          : Colors.transparent,
                      border: Border.all(
                        color: habit.isDoneToday
                            ? AppColors.success
                            : palette.border,
                        width: 1.6,
                      ),
                    ),
                    child: habit.isDoneToday
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: palette.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(habit.icon, color: accent, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => HabitDetailSheet.show(context, habit),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        softWrap: true,
                        style: text.titleMedium?.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: habit.isDoneToday
                              ? palette.caption
                              : palette.heading,
                          decoration: habit.isDoneToday
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: palette.caption,
                        ),
                      ),
                      if (habit.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          habit.description.trim(),
                          softWrap: true,
                          style: text.bodySmall?.copyWith(
                            fontSize: 12.5,
                            height: 1.3,
                            color: palette.caption,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.card,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: palette.border,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              habit.scheduleLabel,
                              style: text.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: palette.body,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                size: 13,
                                color: AppColors.focusPomodoro,
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  '${habit.streakDays}d streak · $weeklyRate% 7d',
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: palette.caption,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, thickness: 0.8, color: palette.border),
          const SizedBox(height: 8),

          // 2. Bottom Action Bar: Analytics, Skip, Reminder, Edit, Delete (Zero Overflow)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              InkWell(
                onTap: () => HabitDetailSheet.show(context, habit),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(
                      alpha: palette.isDark ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insights_rounded, size: 14, color: accent),
                        const SizedBox(width: 4),
                        Text(
                          'Analytics & 30d Log',
                          style: text.labelSmall?.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: habit.isSkippedToday
                        ? 'Unskip Today'
                        : 'Skip Today',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.read<TodayHubBloc>().add(SkipHabit(habit.id));
                    },
                    icon: Icon(
                      Icons.fast_forward_rounded,
                      size: 18,
                      color: habit.isSkippedToday
                          ? AppColors.warning
                          : palette.caption,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: habit.reminderEnabled
                        ? 'Reminder: ${habit.reminderTime ?? "On"}'
                        : 'Enable Reminder',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      context.read<TodayHubBloc>().add(
                        UpdateHabit(
                          habit.copyWith(
                            reminderEnabled: !habit.reminderEnabled,
                            reminderTime: habit.reminderTime ?? '08:00 AM',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      habit.reminderEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 18,
                      color: habit.reminderEnabled ? accent : palette.caption,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Edit Habit',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      final bloc = context.read<TodayHubBloc>();
                      HabitEditorSheet.show(
                        context,
                        existing: habit,
                        onSave: (updated) => bloc.add(UpdateHabit(updated)),
                        onDelete: () => bloc.add(DeleteHabit(habit.id)),
                      );
                    },
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: palette.heading,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Delete Habit',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final bloc = context.read<TodayHubBloc>();
                      final confirmed = await ConfirmationDialog.show(
                        context,
                        title: 'Delete Habit?',
                        message:
                            'Are you sure you want to delete "${habit.title}"?',
                        confirmLabel: 'Delete',
                      );
                      if (confirmed == true && context.mounted) {
                        bloc.add(DeleteHabit(habit.id));
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
