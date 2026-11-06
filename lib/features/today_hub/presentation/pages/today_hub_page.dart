import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/expandable_text_widget.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../../core/widgets/habit_bubble_widget.dart';
import '../../../../core/widgets/safe_spend_meter_widget.dart';
import '../../../../di/injection_container.dart';
import '../../../money/domain/usecases/get_transactions_and_budget_usecase.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/timeline_item_entity.dart';
import '../bloc/today_hub_bloc.dart';
import '../widgets/evening_wrap_up_sheet.dart';
import '../widgets/habit_detail_sheet.dart';
import '../widgets/habit_editor_sheet.dart';
import '../widgets/manage_habits_sheet.dart';
import '../widgets/timeline_editor_sheet.dart';

class TodayHubPage extends StatelessWidget {
  const TodayHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TodayHubBloc>()..add(const LoadTodayHub()),
      child: const _TodayHubView(),
    );
  }
}

class _TodayHubView extends StatefulWidget {
  const _TodayHubView();

  @override
  State<_TodayHubView> createState() => _TodayHubViewState();
}

class _TodayHubViewState extends State<_TodayHubView> {
  Future<DailySpendSnapshot>? _spendFuture;

  @override
  void initState() {
    super.initState();
    _refreshSpend();
  }

  void _refreshSpend() {
    if (sl.isRegistered<GetDailySpendSnapshotUseCase>()) {
      _spendFuture = sl<GetDailySpendSnapshotUseCase>()();
    }
  }

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _playAudioBriefing(
    BuildContext context, {
    required int habitsDone,
    required int habitsTotal,
    required int pendingTasks,
    required double remainingSafe,
  }) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.graphic_eq_rounded,
              color: AppColors.voiceWaveform,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Briefing: $habitsDone/$habitsTotal habits done • $pendingTasks tasks ahead • ₹${remainingSafe.toStringAsFixed(0)} safe to spend.',
                style: const TextStyle(fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return BlocBuilder<TodayHubBloc, TodayHubState>(
      builder: (context, state) {
        return FutureBuilder<DailySpendSnapshot>(
          future: _spendFuture,
          builder: (context, snapshot) {
            final spend = snapshot.data;
            final spentToday = spend?.spentToday ?? 1140.0;
            final safeDailyLimit = (spend != null && spend.dailySafeLimit > 0)
                ? spend.dailySafeLimit
                : 1500.0;
            final daysRemaining = spend?.daysRemaining ?? 15;
            final monthlyBudget = spend?.monthlyBudget ?? 40000.0;
            final remainingSafe = (safeDailyLimit - spentToday).clamp(
              0.0,
              safeDailyLimit,
            );

            final habitsDone = state is TodayHubLoaded
                ? state.completedHabits
                : 0;
            final habitsTotal = state is TodayHubLoaded
                ? state.habits.length
                : 0;
            final pendingTasks = state is TodayHubLoaded
                ? state.timelineItems.where((t) => !t.isDone).length
                : 0;

            return FeatureScaffold(
              title: '${_getTimeGreeting()}, Aarav',
              subtitle: formattedDate,
              leading: const _AvatarMonogram(letter: 'A'),
              actions: [
                FeatureIconButton(
                  icon: Icons.auto_awesome_rounded,
                  tooltip: 'Manage Habits & Micro-Routines',
                  color: AppColors.primary,
                  onPressed: () => ManageHabitsSheet.show(context),
                ),
                const SizedBox(width: 6),
                FeatureIconButton(
                  icon: Icons.volume_up_rounded,
                  tooltip: StringConstants.playBriefing,
                  onPressed: () => _playAudioBriefing(
                    context,
                    habitsDone: habitsDone,
                    habitsTotal: habitsTotal,
                    pendingTasks: pendingTasks,
                    remainingSafe: remainingSafe,
                  ),
                ),
              ],
              status: switch (state) {
                TodayHubLoading() || TodayHubInitial() => FeatureStatus.loading,
                TodayHubError() => FeatureStatus.error,
                TodayHubLoaded() => FeatureStatus.content,
                _ => FeatureStatus.loading,
              },
              errorMessage: state is TodayHubError ? state.message : null,
              onRetry: () {
                setState(_refreshSpend);
                context.read<TodayHubBloc>().add(const LoadTodayHub());
              },
              loading: const _TodayHubLoadingView(),
              builder: (context) {
                final loaded = state as TodayHubLoaded;
                final totalTimeline = loaded.timelineItems.length;
                final doneTimeline = totalTimeline - pendingTasks;
                final totalItems = habitsTotal + totalTimeline;
                final completedItems = habitsDone + doneTimeline;
                final progress = totalItems > 0
                    ? (completedItems / totalItems).clamp(0.0, 1.0)
                    : 0.0;

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    setState(_refreshSpend);
                    context.read<TodayHubBloc>().add(const LoadTodayHub());
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 760;

                      final habitsSection = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HabitsSectionHeader(
                            completedCount: habitsDone,
                            totalCount: habitsTotal,
                            onAddHabit: () {
                              final bloc = context.read<TodayHubBloc>();
                              HabitEditorSheet.show(
                                context,
                                onSave: (habit) => bloc.add(AddHabit(habit)),
                              );
                            },
                            onManageHabits: () =>
                                ManageHabitsSheet.show(context),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _HabitsManagementCard(state: loaded),
                        ],
                      );

                      final timelineSection = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TimelineSectionHeader(
                            pendingTasks: pendingTasks,
                            onAddTask: () {
                              final bloc = context.read<TodayHubBloc>();
                              TimelineEditorSheet.show(
                                context,
                                onSave: (item) =>
                                    bloc.add(AddTimelineItem(item)),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          _TimelineUnifiedCard(items: loaded.timelineItems),
                        ],
                      );

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageGutter,
                          AppSpacing.xs,
                          AppSpacing.pageGutter,
                          110,
                        ),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 980),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Unified Momentum & Glance Card
                                  _MomentumSummaryCard(
                                    progress: progress,
                                    habitsDone: habitsDone,
                                    habitsTotal: habitsTotal,
                                    pendingTasks: pendingTasks,
                                    remainingSafe: remainingSafe,
                                    longestStreak: loaded.longestActiveStreak,
                                    nextPriorityTask: loaded.timelineItems
                                        .where((t) => !t.isDone)
                                        .firstOrNull,
                                  ),
                                  const SizedBox(height: AppSpacing.md),

                                  // 2. Safe-to-Spend Meter
                                  SafeSpendMeterWidget(
                                    spentToday: spentToday,
                                    dailySafeLimit: safeDailyLimit,
                                    daysRemaining: daysRemaining,
                                    monthlyBudget: monthlyBudget,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),

                                  // 3 & 4. Habits & Timeline (2-column on wide screens, stacked on mobile)
                                  if (isWide)
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(child: habitsSection),
                                        const SizedBox(width: AppSpacing.lg),
                                        Expanded(child: timelineSection),
                                      ],
                                    )
                                  else ...[
                                    habitsSection,
                                    const SizedBox(height: AppSpacing.lg),
                                    timelineSection,
                                  ],
                                  const SizedBox(height: AppSpacing.lg),

                                  // 5. Evening Wrap-Up Banner
                                  _EveningWrapUpCard(
                                    spentToday: spentToday,
                                    safeDailyLimit: safeDailyLimit,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ============================================================================
// HABITS & MICRO-ROUTINES SECTION HEADER + INTERACTIVE CARD
// ============================================================================
class _HabitsSectionHeader extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final VoidCallback onAddHabit;
  final VoidCallback onManageHabits;

  const _HabitsSectionHeader({
    required this.completedCount,
    required this.totalCount,
    required this.onAddHabit,
    required this.onManageHabits,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: palette.isDark ? 0.22 : 0.12,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.repeat_rounded,
              size: 13.5,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              StringConstants.habitsAndRoutines,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: palette.heading,
              ),
            ),
          ),
          _CountPill(
            text: '$completedCount/$totalCount done',
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onManageHabits,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune_rounded, size: 12, color: palette.heading),
                  const SizedBox(width: 4),
                  Text(
                    'Manage',
                    style: text.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: palette.heading,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onAddHabit,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    'Add',
                    style: text.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitsManagementCard extends StatefulWidget {
  final TodayHubLoaded state;

  const _HabitsManagementCard({required this.state});

  @override
  State<_HabitsManagementCard> createState() => _HabitsManagementCardState();
}

class _HabitsManagementCardState extends State<_HabitsManagementCard> {
  bool _showAllHabits = false;

  List<bool> _computeRecentWeekDots(HabitEntity habit) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return habit.isCompletedOn(d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final palette = context.palette;
    final text = context.text;
    final categories = state.availableCategories;
    final filteredHabits = state.filteredHabits;
    final visibleHabits = _showAllHabits
        ? filteredHabits
        : filteredHabits.take(5).toList();
    final hiddenHabitsCount = filteredHabits.length - 5;
    final weeklyPct = (state.overallWeeklyConsistency * 100).round();

    return FeatureCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Category Filter & Consistency Sub-Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              color: palette.surfaceMuted.withValues(
                alpha: palette.isDark ? 0.45 : 0.65,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              border: Border(
                bottom: BorderSide(color: palette.border, width: 0.7),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '$weeklyPct% 7-day consistency • Best active streak ${state.longestActiveStreak}d',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.body,
                        ),
                      ),
                    ),
                    if (state.skippedHabits > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${state.skippedHabits} skipped',
                          style: text.labelSmall?.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                if (categories.length > 2) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final active =
                            state.selectedHabitCategory.toLowerCase() ==
                            cat.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              context.read<TodayHubBloc>().add(
                                SelectHabitCategory(cat),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.primary
                                    : palette.card,
                                borderRadius: AppRadius.radiusFull,
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : palette.border,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: text.labelSmall?.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: active ? Colors.white : palette.body,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. Habit Rows
          if (filteredHabits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.lg,
              ),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      state.habits.isEmpty
                          ? 'No habits configured yet.'
                          : 'No habits in "${state.selectedHabitCategory}".',
                      style: text.bodyMedium?.copyWith(color: palette.caption),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        if (state.habits.isNotEmpty &&
                            state.selectedHabitCategory != 'All') {
                          context.read<TodayHubBloc>().add(
                            const SelectHabitCategory('All'),
                          );
                        } else {
                          final bloc = context.read<TodayHubBloc>();
                          HabitEditorSheet.show(
                            context,
                            onSave: (habit) => bloc.add(AddHabit(habit)),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        state.habits.isNotEmpty &&
                                state.selectedHabitCategory != 'All'
                            ? 'Show All Categories'
                            : 'Create First Habit',
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  for (var i = 0; i < visibleHabits.length; i++) ...[
                    HabitBubbleWidget(
                      title: visibleHabits[i].title,
                      description: visibleHabits[i].description,
                      icon: visibleHabits[i].icon,
                      streakDays: visibleHabits[i].streakDays,
                      isDone: visibleHabits[i].isDoneToday,
                      isSkipped: visibleHabits[i].isSkippedToday,
                      tintColor: visibleHabits[i].color,
                      category: visibleHabits[i].category,
                      scheduleLabel: visibleHabits[i].scheduleLabel,
                      reminderEnabled: visibleHabits[i].reminderEnabled,
                      reminderTime: visibleHabits[i].reminderTime,
                      recentWeekDots: _computeRecentWeekDots(visibleHabits[i]),
                      onTap: () => context.read<TodayHubBloc>().add(
                        ToggleHabit(visibleHabits[i].id),
                      ),
                      onDetailTap: () =>
                          HabitDetailSheet.show(context, visibleHabits[i]),
                    ),
                    if (i < visibleHabits.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 52,
                        color: palette.border,
                      ),
                  ],
                ],
              ),
            ),
            if (filteredHabits.length > 5)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: TextButton.icon(
                    onPressed: () =>
                        setState(() => _showAllHabits = !_showAllHabits),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      minimumSize: const Size(0, 28),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      _showAllHabits
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                    ),
                    label: Text(
                      _showAllHabits
                          ? 'Show less habits'
                          : 'Show more ($hiddenHabitsCount more habits)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],

          // 3. Bottom Action Footer Bar inside Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: palette.border, width: 0.7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: () {
                      final bloc = context.read<TodayHubBloc>();
                      HabitEditorSheet.show(
                        context,
                        onSave: (habit) => bloc.add(AddHabit(habit)),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add_circle_outline_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'New Habit / Routine',
                              style: text.labelSmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: InkWell(
                    onTap: () => ManageHabitsSheet.show(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Analytics & Schedule',
                              style: text.labelSmall?.copyWith(
                                fontSize: 10.5,
                                color: palette.caption,
                              ),
                            ),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 12,
                            color: palette.caption,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TIMELINE SECTION HEADER + INTERACTIVE CARD
// ============================================================================
class _TimelineSectionHeader extends StatelessWidget {
  final int pendingTasks;
  final VoidCallback onAddTask;

  const _TimelineSectionHeader({
    required this.pendingTasks,
    required this.onAddTask,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.moduleTime.withValues(
                alpha: palette.isDark ? 0.22 : 0.12,
              ),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 13.5,
              color: AppColors.moduleTime,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              StringConstants.timelineFeed,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: palette.heading,
              ),
            ),
          ),
          _CountPill(
            text: pendingTasks == 0 ? 'All done' : '$pendingTasks remaining',
            color: pendingTasks == 0 ? AppColors.success : AppColors.moduleTime,
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onAddTask,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.moduleTime.withValues(
                  alpha: palette.isDark ? 0.22 : 0.12,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    size: 13,
                    color: AppColors.moduleTime,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Task',
                    style: text.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.moduleTime,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// AVATAR MONOGRAM (36x36 for FeatureScaffold leading)
// ============================================================================
class _AvatarMonogram extends StatelessWidget {
  final String letter;

  const _AvatarMonogram({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(11),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}

// ============================================================================
// COUNT PILL (used in section headers)
// ============================================================================
class _CountPill extends StatelessWidget {
  final String text;
  final Color color;

  const _CountPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: AppRadius.radiusFull,
      ),
      child: Text(
        text,
        style: context.text.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ============================================================================
// UNIFIED MOMENTUM & DAILY GLANCE CARD
// ============================================================================
class _MomentumSummaryCard extends StatelessWidget {
  final double progress;
  final int habitsDone;
  final int habitsTotal;
  final int pendingTasks;
  final double remainingSafe;
  final int longestStreak;
  final TimelineItemEntity? nextPriorityTask;

  const _MomentumSummaryCard({
    required this.progress,
    required this.habitsDone,
    required this.habitsTotal,
    required this.pendingTasks,
    required this.remainingSafe,
    this.longestStreak = 0,
    this.nextPriorityTask,
  });

  String _getMotivationMessage(int pct) {
    if (pct >= 80) return 'Outstanding focus today — almost at the finish line';
    if (pct >= 50) return 'Solid momentum — over halfway through your goals';
    return 'Steady start — knock out your next priority task';
  }

  String _getDetailedInsight(int pct) {
    final nextText = nextPriorityTask != null
        ? 'Next priority: "${nextPriorityTask!.title}" at ${nextPriorityTask!.time} (${nextPriorityTask!.category}). '
        : 'All scheduled timeline tasks are completed for today! ';
    final streakText = longestStreak > 0
        ? 'Your longest active habit streak is $longestStreak days — keep the chain unbroken.'
        : 'Complete a habit today to ignite your consistency streak.';
    return '$nextText$streakText';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final pct = (progress * 100).round();

    return FeatureCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, animVal, _) {
                  final animPct = (animVal * 100).round();
                  return SizedBox(
                    width: 52,
                    height: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: animVal,
                            strokeWidth: 5,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: palette.isDark ? 0.22 : 0.12,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Text(
                          '$animPct%',
                          style: text.labelLarge?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: palette.heading,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.md),
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
                            color: AppColors.primary.withValues(
                              alpha: palette.isDark ? 0.20 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'DAILY MOMENTUM',
                            style: text.labelSmall?.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (longestStreak > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.focusPomodoro.withValues(
                                alpha: palette.isDark ? 0.20 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '🔥 ${longestStreak}d Top Streak',
                              style: text.labelSmall?.copyWith(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.focusPomodoro,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _getMotivationMessage(pct),
                      style: text.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.heading,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    ExpandableTextWidget(
                      text: _getDetailedInsight(pct),
                      collapsedMaxLines: 1,
                      characterThreshold: 55,
                      toggleColor: AppColors.primary,
                      style: text.labelSmall?.copyWith(
                        fontSize: 11.5,
                        height: 1.35,
                        color: palette.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, thickness: 1, color: palette.border),
          const SizedBox(height: AppSpacing.sm + 2),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _MetricColumn(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.secondary,
                    label: 'Habits Done',
                    value: '$habitsDone / $habitsTotal',
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                  color: palette.border,
                ),
                Expanded(
                  child: _MetricColumn(
                    icon: Icons.schedule_rounded,
                    color: AppColors.moduleTime,
                    label: 'Tasks Pending',
                    value: '$pendingTasks left',
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  indent: 4,
                  endIndent: 4,
                  color: palette.border,
                ),
                Expanded(
                  child: _MetricColumn(
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.moduleMoney,
                    label: 'Safe Spend',
                    value: '₹${remainingSafe.toStringAsFixed(0)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _MetricColumn({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: text.titleSmall?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: palette.heading,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: text.labelSmall?.copyWith(
                fontSize: 11,
                color: palette.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// UNIFIED TIMELINE CARD (Grouped rows with hairlines + Edit/Delete support)
// ============================================================================
class _TimelineUnifiedCard extends StatefulWidget {
  final List<TimelineItemEntity> items;

  const _TimelineUnifiedCard({required this.items});

  @override
  State<_TimelineUnifiedCard> createState() => _TimelineUnifiedCardState();
}

class _TimelineUnifiedCardState extends State<_TimelineUnifiedCard> {
  bool _showAllItems = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = widget.items;

    if (items.isEmpty) {
      return FeatureCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                'No timeline items scheduled for today.',
                style: context.text.bodyMedium?.copyWith(
                  color: palette.caption,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  final bloc = context.read<TodayHubBloc>();
                  TimelineEditorSheet.show(
                    context,
                    onSave: (item) => bloc.add(AddTimelineItem(item)),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Schedule Today\'s First Task'),
              ),
            ],
          ),
        ),
      );
    }

    final visibleItems = _showAllItems ? items : items.take(5).toList();
    final hiddenCount = items.length - 5;

    return FeatureCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (var i = 0; i < visibleItems.length; i++) ...[
                  _TimelineRowTile(
                    item: visibleItems[i],
                    onToggle: () {
                      context.read<TodayHubBloc>().add(
                        ToggleTimelineItem(visibleItems[i].id),
                      );
                    },
                    onEdit: () {
                      final bloc = context.read<TodayHubBloc>();
                      final current = visibleItems[i];
                      TimelineEditorSheet.show(
                        context,
                        existing: current,
                        onSave: (updated) =>
                            bloc.add(UpdateTimelineItem(updated)),
                        onDelete: () =>
                            bloc.add(DeleteTimelineItem(current.id)),
                      );
                    },
                  ),
                  if (i < visibleItems.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 52,
                      color: palette.border,
                    ),
                ],
              ],
            ),
          ),
          if (items.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: TextButton.icon(
                onPressed: () => setState(() => _showAllItems = !_showAllItems),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.moduleTime,
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  _showAllItems
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                ),
                label: Text(
                  _showAllItems
                      ? 'Show less'
                      : 'Show more ($hiddenCount more tasks)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelineRowTile extends StatelessWidget {
  final TimelineItemEntity item;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _TimelineRowTile({
    required this.item,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final tint = item.color;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onToggle();
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onEdit();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Check circle
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isDone ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: item.isDone ? AppColors.success : palette.border,
                      width: 1.5,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: item.isDone
                        ? const Icon(
                            Icons.check_rounded,
                            key: ValueKey('checked'),
                            size: 14,
                            color: Colors.white,
                          )
                        : const SizedBox.shrink(key: ValueKey('unchecked')),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // 2. Category icon badge
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: palette.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(item.icon, size: 16, color: tint),
              ),
              const SizedBox(width: AppSpacing.sm + 4),

              // 3. Full Title (with Show More if long) + Time/Category subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpandableTextWidget(
                      text: item.title,
                      collapsedMaxLines: 2,
                      characterThreshold: 50,
                      toggleColor: tint,
                      style: text.titleSmall?.copyWith(
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: item.isDone ? palette.caption : palette.heading,
                        decoration: item.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: palette.caption,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.time} • ${item.category}',
                      style: text.labelSmall?.copyWith(
                        fontSize: 11,
                        color: palette.caption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),

              // 4. Status/Action Pill & Menu
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: item.isDone
                            ? AppColors.success.withValues(
                                alpha: palette.isDark ? 0.18 : 0.10,
                              )
                            : tint.withValues(
                                alpha: palette.isDark ? 0.18 : 0.10,
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.isDone ? 'Completed' : item.action,
                        style: text.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: item.isDone ? AppColors.success : tint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: 'Edit Task',
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 16,
                        color: palette.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// EVENING WRAP-UP CARD (Opens Interactive Evening Wrap-Up & Reflection Sheet)
// ============================================================================
class _EveningWrapUpCard extends StatelessWidget {
  final double spentToday;
  final double safeDailyLimit;

  const _EveningWrapUpCard({
    required this.spentToday,
    required this.safeDailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    return FeatureCard(
      borderColor: AppColors.primary.withValues(
        alpha: palette.isDark ? 0.30 : 0.20,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      onTap: () {
        HapticFeedback.selectionClick();
        EveningWrapUpSheet.show(
          context,
          spentToday: spentToday,
          safeDailyLimit: safeDailyLimit,
        );
      },
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: palette.isDark ? 0.25 : 0.14,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.nights_stay_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StringConstants.eveningWrapUpTitle,
                  style: text.titleSmall?.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: palette.heading,
                  ),
                ),
                const SizedBox(height: 3),
                ExpandableTextWidget(
                  text: StringConstants.eveningWrapUpSubtitle,
                  collapsedMaxLines: 2,
                  characterThreshold: 60,
                  toggleColor: AppColors.primary,
                  style: text.labelSmall?.copyWith(
                    fontSize: 11.5,
                    height: 1.35,
                    color: palette.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SHIMMER LOADING STATE
// ============================================================================
class _TodayHubLoadingView extends StatelessWidget {
  const _TodayHubLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        80,
      ),
      children: const [
        AppShimmerLoader.card(height: 110),
        SizedBox(height: AppSpacing.md),
        AppShimmerLoader.card(height: 76),
        SizedBox(height: AppSpacing.lg),
        AppShimmerLoader.card(height: 64),
        SizedBox(height: AppSpacing.sm),
        AppShimmerLoader.card(height: 64),
      ],
    );
  }
}
