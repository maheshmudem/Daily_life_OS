import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../../core/widgets/habit_bubble_widget.dart';
import '../../../../core/widgets/staggered_fade_slide.dart';
import '../../../quick_capture/presentation/widgets/quick_capture_sheet.dart';
import '../../../../core/widgets/safe_spend_meter_widget.dart';
import '../../../../di/injection_container.dart';
import '../../../command_palette/presentation/widgets/global_command_palette_sheet.dart';
import '../../../money/domain/usecases/get_transactions_and_budget_usecase.dart';
import '../../../navigation/presentation/widgets/os_quick_launch_dock.dart';
import '../../../profile/domain/entities/user_profile_entity.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../profile/presentation/widgets/profile_settings_sheet.dart';
import '../../../profile/presentation/widgets/user_avatar_widget.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/timeline_item_entity.dart';
import '../bloc/today_hub_bloc.dart';
import '../widgets/audio_briefing_sheet.dart';
import '../widgets/evening_wrap_up_sheet.dart';
import '../widgets/habit_detail_sheet.dart';
import '../widgets/habit_editor_sheet.dart';
import '../widgets/manage_habits_sheet.dart';
import '../widgets/timeline_editor_sheet.dart';

class TodayHubPage extends StatelessWidget {
  final ValueChanged<int>? onNavigateToTab;
  final ValueChanged<QuickCaptureMode>? onOpenQuickCapture;

  const TodayHubPage({
    super.key,
    this.onNavigateToTab,
    this.onOpenQuickCapture,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TodayHubBloc>()..add(const LoadTodayHub()),
      child: _TodayHubView(
        onNavigateToTab: onNavigateToTab,
        onOpenQuickCapture: onOpenQuickCapture,
      ),
    );
  }
}

class _TodayHubView extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;
  final ValueChanged<QuickCaptureMode>? onOpenQuickCapture;

  const _TodayHubView({this.onNavigateToTab, this.onOpenQuickCapture});

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
    required UserProfileEntity profile,
    List<HabitEntity>? habits,
    List<TimelineItemEntity>? timelineItems,
    DailySpendSnapshot? spendSnapshot,
  }) {
    if (profile.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    AudioBriefingSheet.show(
      context,
      userName: profile.displayName,
      autoPlay: profile.autoPlayAudioBriefing,
      habits: habits,
      timelineItems: timelineItems,
      spendSnapshot: spendSnapshot,
    );
  }

  Widget _buildWithProfile(BuildContext context, UserProfileEntity profile) {
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

            final tintBg = AppColors.primary.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark
                  ? 0.22
                  : 0.10,
            );

            return FeatureScaffold(
              title: '${_getTimeGreeting()}, ${profile.displayName}',
              subtitle: formattedDate,
              onTitleTap: () => ProfileSettingsSheet.show(context),
              actionsEndPadding: AppSpacing.pageGutter,
              leading: Tooltip(
                message: StringConstants.profileTooltip,
                child: UserAvatarWidget(
                  key: const ValueKey('today_profile_avatar_button'),
                  profile: profile,
                  size: 36,
                  borderRadius: 11,
                  onTap: () => ProfileSettingsSheet.show(context),
                ),
              ),
              actions: [
                FeatureIconButton(
                  key: const ValueKey('today_spotlight_button'),
                  backgroundColor: tintBg,
                  borderColor: Colors.transparent,
                  icon: Icons.search_rounded,
                  tooltip: StringConstants.spotlightSearchTooltip,
                  color: AppColors.primary,
                  onPressed: () => GlobalCommandPaletteSheet.show(
                    context,
                    onNavigateTab: (idx) => widget.onNavigateToTab?.call(idx),
                    onOpenQuickCapture: (mode) {
                      if (widget.onOpenQuickCapture != null) {
                        widget.onOpenQuickCapture!(mode);
                      } else {
                        QuickCaptureSheet.show(context, mode: mode);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FeatureIconButton(
                  icon: Icons.auto_awesome_rounded,
                  backgroundColor: tintBg,
                  borderColor: Colors.transparent,
                  tooltip: 'Manage Habits & Micro-Routines',
                  color: AppColors.primary,
                  onPressed: () => ManageHabitsSheet.show(context),
                ),
                const SizedBox(width: 8),
                FeatureIconButton(
                  icon: Icons.volume_up_rounded,
                  backgroundColor: tintBg,
                  borderColor: Colors.transparent,
                  tooltip: StringConstants.playBriefing,
                  color: AppColors.primary,
                  onPressed: () => _playAudioBriefing(
                    context,
                    profile: profile,
                    habits: state is TodayHubLoaded ? state.habits : null,
                    timelineItems: state is TodayHubLoaded
                        ? state.timelineItems
                        : null,
                    spendSnapshot: spend,
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
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 10),
                          _TimelineUnifiedCard(items: loaded.timelineItems),
                        ],
                      );

                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageGutter,
                          AppSpacing.sm,
                          AppSpacing.pageGutter,
                          110,
                        ),
                        children: [
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1080),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Unified Momentum & Glance Card
                                  StaggeredFadeSlide(
                                    index: 0,
                                    child: _MomentumSummaryCard(
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
                                  ),
                                  const SizedBox(height: AppSpacing.sm),

                                  // 1.5. Interactive Today Audio Brief Section
                                  if (profile.showAudioBriefCard) ...[
                                    StaggeredFadeSlide(
                                      index: 1,
                                      child: _AudioBriefSectionCard(
                                        habitsDone: habitsDone,
                                        habitsTotal: habitsTotal,
                                        pendingTasks: pendingTasks,
                                        remainingSafe: remainingSafe,
                                        onTap: () => _playAudioBriefing(
                                          context,
                                          profile: profile,
                                          habits: loaded.habits,
                                          timelineItems: loaded.timelineItems,
                                          spendSnapshot: spend,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],

                                  // 2. Safe-to-Spend Meter
                                  if (profile.showSafeSpendCard) ...[
                                    StaggeredFadeSlide(
                                      index: 2,
                                      child: SafeSpendMeterWidget(
                                        spentToday: spentToday,
                                        dailySafeLimit: safeDailyLimit,
                                        daysRemaining: daysRemaining,
                                        monthlyBudget: monthlyBudget,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                  ],

                                  // 2.5. Cross-Module Quick-Launch OS Dock
                                  if (profile.showQuickLaunchDock) ...[
                                    StaggeredFadeSlide(
                                      index: 3,
                                      child: OsQuickLaunchDock(
                                        onOpenSpotlight: () =>
                                            GlobalCommandPaletteSheet.show(
                                              context,
                                              onNavigateTab: (idx) => widget
                                                  .onNavigateToTab
                                                  ?.call(idx),
                                              onOpenQuickCapture: (mode) {
                                                if (widget.onOpenQuickCapture !=
                                                    null) {
                                                  widget.onOpenQuickCapture!(
                                                    mode,
                                                  );
                                                } else {
                                                  QuickCaptureSheet.show(
                                                    context,
                                                    mode: mode,
                                                  );
                                                }
                                              },
                                            ),
                                        onNavigateTab: (idx) =>
                                            widget.onNavigateToTab?.call(idx),
                                        onQuickCapture: (mode) {
                                          if (widget.onOpenQuickCapture !=
                                              null) {
                                            widget.onOpenQuickCapture!(mode);
                                          } else {
                                            QuickCaptureSheet.show(
                                              context,
                                              mode: mode,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],

                                  // 3 & 4. Habits & Timeline (2-column on wide screens, stacked on mobile)
                                  if (isWide)
                                    StaggeredFadeSlide(
                                      index: 4,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: habitsSection),
                                          const SizedBox(width: AppSpacing.lg),
                                          Expanded(child: timelineSection),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    StaggeredFadeSlide(
                                      index: 4,
                                      child: habitsSection,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    StaggeredFadeSlide(
                                      index: 5,
                                      child: timelineSection,
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.lg),

                                  // 5. Evening Wrap-Up Banner
                                  if (profile.showEveningWrapUpCard)
                                    StaggeredFadeSlide(
                                      index: 6,
                                      child: _EveningWrapUpCard(
                                        spentToday: spentToday,
                                        safeDailyLimit: safeDailyLimit,
                                      ),
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

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<ProfileBloc>()) {
      return _buildWithProfile(context, const UserProfileEntity());
    }
    return BlocBuilder<ProfileBloc, ProfileState>(
      bloc: sl<ProfileBloc>(),
      builder: (context, profileState) =>
          _buildWithProfile(context, profileState.profile),
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

    return Row(
      children: [
        Expanded(
          child: Text(
            StringConstants.habitsAndRoutines,
            softWrap: true,
            style: text.titleMedium?.copyWith(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: palette.heading,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: 'Manage Habits & Routines',
          child: InkWell(
            onTap: onManageHabits,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: palette.border),
              ),
              child: Icon(Icons.tune_rounded, size: 15, color: palette.heading),
            ),
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onAddHabit,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  'Add',
                  style: text.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceMuted.withValues(
                alpha: palette.isDark ? 0.45 : 0.65,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(17),
              ),
              border: Border(
                bottom: BorderSide(color: palette.divider, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.insights_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$weeklyPct% consistency · Best ${state.longestActiveStreak}d',
                        softWrap: true,
                        style: text.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.body,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _CountPill(
                      text:
                          '${state.completedHabits}/${state.habits.length} done',
                      color: AppColors.primary,
                    ),
                    if (state.skippedHabits > 0) ...[
                      const SizedBox(width: 4),
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
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
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
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                        color: palette.divider,
                      ),
                  ],
                ],
              ),
            ),
            if (filteredHabits.length > 5)
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 6),
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

    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                StringConstants.timelineFeed,
                softWrap: true,
                style: text.titleMedium?.copyWith(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: palette.heading,
                ),
              ),
              _CountPill(
                text: pendingTasks == 0
                    ? 'All done'
                    : '$pendingTasks remaining',
                color: pendingTasks == 0
                    ? AppColors.success
                    : AppColors.moduleTime,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: onAddTask,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: AppColors.moduleTime.withValues(
                alpha: palette.isDark ? 0.22 : 0.12,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_rounded,
                  size: 15,
                  color: AppColors.moduleTime,
                ),
                const SizedBox(width: 3),
                Text(
                  'Task',
                  style: text.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.moduleTime,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final pct = (progress * 100).round();
    final next = nextPriorityTask;

    // Gradient hero: the screen's single focal point. Ring + headline on top,
    // a frosted three-metric strip below. Fixed height, nothing expandable.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.heroPrimaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MomentumRing(progress: progress),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'DAILY MOMENTUM',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: Colors.white.withValues(alpha: 0.74),
                            ),
                          ),
                        ),
                        if (longestStreak > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 11.5,
                                  color: Color(0xFFFBBF24),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${longestStreak}d streak',
                                  style: text.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _getMotivationMessage(pct),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontSize: 16.5,
                        height: 1.25,
                        letterSpacing: -0.3,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Next · ${next.time} · ${next.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    label: 'Habits Done',
                    value: '$habitsDone / $habitsTotal',
                  ),
                ),
                const _HeroMetricDivider(),
                Expanded(
                  child: _HeroMetric(
                    label: 'Tasks Pending',
                    value: '$pendingTasks left',
                  ),
                ),
                const _HeroMetricDivider(),
                Expanded(
                  child: _HeroMetric(
                    label: 'Safe Spend',
                    value: CurrencyUtils.format(remainingSafe, decimals: 0),
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

class _MomentumRing extends StatelessWidget {
  final double progress;

  const _MomentumRing({required this.progress});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: progress),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animVal, _) {
        return SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: CircularProgressIndicator(
                  value: animVal,
                  strokeWidth: 6.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.22),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${(animVal * 100).round()}%',
                style: context.text.labelLarge?.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              value,
              style: text.titleSmall?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: Colors.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              label,
              style: text.labelSmall?.copyWith(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.76),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricDivider extends StatelessWidget {
  const _HeroMetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white.withValues(alpha: 0.22),
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
      padding: EdgeInsets.zero,
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
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                      color: palette.divider,
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
    final hasAction = !item.isDone && item.action.trim().isNotEmpty;
    final metaStyle = text.labelSmall?.copyWith(
      fontSize: 11,
      height: 1.3,
      letterSpacing: -0.1,
      fontWeight: FontWeight.w500,
      color: palette.caption,
    );

    // Two-line row: title, then `time · category · action` on one meta line.
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
            vertical: 11,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Check circle
              AnimatedContainer(
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
              const SizedBox(width: 10),

              // 2. Category icon badge
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: palette.isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 17, color: tint),
              ),
              const SizedBox(width: 10),

              // 3. Title + single meta line (time · category · status/action)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontSize: 14.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.25,
                        color: item.isDone ? palette.caption : palette.heading,
                        decoration: item.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: palette.caption,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: item.time,
                                  style: metaStyle?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: item.isDone
                                        ? palette.caption
                                        : palette.body,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                TextSpan(text: ' · ${item.category}'),
                                if (item.isDone)
                                  TextSpan(
                                    text: ' · Done',
                                    style: metaStyle?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.success,
                                    ),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: metaStyle,
                          ),
                        ),
                        if (hasAction) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: tint.withValues(
                                alpha: palette.isDark ? 0.18 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              item.action,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall?.copyWith(
                                fontSize: 10,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: tint,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // 4. Menu button, centered with row
              IconButton(
                tooltip: 'Edit Task',
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
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
        vertical: 13,
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: palette.isDark ? 0.25 : 0.12,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.nights_stay_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    StringConstants.eveningWrapUpTitle,
                    maxLines: 1,
                    style: text.titleMedium?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.25,
                      color: palette.heading,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  StringConstants.eveningWrapUpSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.3,
                    color: palette.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: palette.isDark ? 0.20 : 0.10,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.primary,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TODAY'S AUDIO BRIEFING SECTION CARD
// ============================================================================
class _AudioBriefSectionCard extends StatelessWidget {
  final int habitsDone;
  final int habitsTotal;
  final int pendingTasks;
  final double remainingSafe;
  final VoidCallback onTap;

  const _AudioBriefSectionCard({
    required this.habitsDone,
    required this.habitsTotal,
    required this.pendingTasks,
    required this.remainingSafe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;

    // Compact "now playing" strip: waveform tile · title + one-line summary ·
    // round play button. The whole card is the tap target.
    return FeatureCard(
      key: const ValueKey('today_audio_brief_section'),
      borderColor: AppColors.primary.withValues(
        alpha: palette.isDark ? 0.35 : 0.22,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.graphic_eq_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  StringConstants.audioBriefSectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: palette.heading,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$habitsDone/$habitsTotal habits · $pendingTasks tasks left · '
                    '${CurrencyUtils.format(remainingSafe, decimals: 0)} safe',
                    maxLines: 1,
                    style: text.bodySmall?.copyWith(
                      fontSize: 12,
                      height: 1.3,
                      color: palette.caption,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 21,
            ),
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
