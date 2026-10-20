import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/audio_briefing_sheet.dart';
import '../../../../core/widgets/habit_bubble_widget.dart';
import '../../../../core/widgets/quick_capture_sheet.dart';
import '../../../../core/widgets/safe_spend_meter_widget.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/timeline_item_entity.dart';
import '../bloc/today_hub_bloc.dart';

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

class _TodayHubView extends StatelessWidget {
  const _TodayHubView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffoldBackground : AppColors.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<TodayHubBloc, TodayHubState>(
          builder: (context, state) {
            if (state is TodayHubLoading || state is TodayHubInitial) {
              return const _LoadingView();
            }
            if (state is TodayHubError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is TodayHubLoaded) {
              return _LoadedView(state: state, isDark: isDark);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ── Loading skeleton (preserves layout during fetch) ─────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const AppShimmerLoader.card(height: 60),
        const SizedBox(height: 16),
        const AppShimmerLoader.card(height: 130),
        const SizedBox(height: 16),
        const AppShimmerLoader.card(height: 90),
        const SizedBox(height: 16),
        const AppShimmerLoader.card(height: 128),
        const SizedBox(height: 16),
        const AppShimmerLoader.card(height: 200),
      ],
    );
  }
}

// ── Loaded view (identical UI to original static version) ────────────────────
class _LoadedView extends StatelessWidget {
  final TodayHubLoaded state;
  final bool isDark;

  const _LoadedView({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Top App Bar with Live Header & Audio Briefing Pill
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY • ${DateTime.now().day} ${_monthAbbr(DateTime.now().month).toUpperCase()}',
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Good ${_greeting()}, Alex',
                      style: AppTextStyles.headingMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
                      ),
                    ),
                  ],
                ),
                // "Play My Day" Audio Briefing Pill
                GestureDetector(
                  onTap: () => AudioBriefingSheet.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: AppRadius.radiusFull,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up_rounded, size: 16, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          StringConstants.playBriefing,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Hero Overview Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecorations.heroPrimaryGradient,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: AppRadius.radiusFull,
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Daily Life OS Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${state.completedHabits}/${state.habits.length} Habits Done',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Time, Money & Mind in Sync',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${state.completedHabits} routines completed • ${state.timelineItems.where((t) => !t.isDone).length} tasks pending',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Daily Safe-to-Spend Meter
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SafeSpendMeterWidget(
              spentToday: 450,
              dailySafeLimit: 1200,
              daysRemaining: 12,
              monthlyBudget: 35000,
              onLogExpense: () => QuickCaptureSheet.show(
                context,
                mode: QuickCaptureMode.text,
              ),
            ),
          ),
        ),

        // Habit & Micro-Routine Strip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        StringConstants.habitsAndRoutines,
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        '${state.completedHabits}/${state.habits.length} completed',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 128,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.habits.length,
                    separatorBuilder: (context, index) => AppSpacing.gapW12,
                    itemBuilder: (context, index) {
                      final habit = state.habits[index];
                      return _HabitBubble(habit: habit);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Chronological Timeline Feed
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      StringConstants.timelineFeed,
                      style: AppTextStyles.titleMedium,
                    ),
                    Text(
                      'Sorted by time',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...state.timelineItems.map(
                  (item) => _TimelineTile(item: item, isDark: isDark),
                ),
              ],
            ),
          ),
        ),

        // 60-Second Evening Wrap-Up Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 90, top: 4),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceSecondary : AppColors.surfaceSecondary,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.moduleVault.withValues(alpha: 0.15),
                      borderRadius: AppRadius.radiusMd,
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: AppColors.moduleVault,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          StringConstants.eveningWrapUpTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          StringConstants.eveningWrapUpSubtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Evening Wrap-Up opens automatically at 9:30 PM.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.moduleVault,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                    ),
                    child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  String _monthAbbr(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}

// ── Habit bubble (BLoC-aware) ─────────────────────────────────────────────────
class _HabitBubble extends StatelessWidget {
  final HabitEntity habit;
  const _HabitBubble({required this.habit});

  @override
  Widget build(BuildContext context) {
    return HabitBubbleWidget(
      title: habit.title,
      icon: habit.icon,
      streakDays: habit.streakDays,
      isDone: habit.isDoneToday,
      tintColor: habit.color,
      onTap: () => context.read<TodayHubBloc>().add(ToggleHabit(habit.id)),
    );
  }
}

// ── Timeline tile (BLoC-aware) ────────────────────────────────────────────────
class _TimelineTile extends StatelessWidget {
  final TimelineItemEntity item;
  final bool isDark;
  const _TimelineTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = item.color;
    final isDone = item.isDone;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDone ? color.withValues(alpha: 0.3) : (isDark ? AppColors.darkDivider : AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusSm,
            ),
            child: Text(
              item.time,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                  ),
                ),
              ],
            ),
          ),

          // Action button
          TextButton(
            onPressed: () =>
                context.read<TodayHubBloc>().add(ToggleTimelineItem(item.id)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              isDone ? 'Undo' : item.action,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDone ? AppColors.textCaption : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
