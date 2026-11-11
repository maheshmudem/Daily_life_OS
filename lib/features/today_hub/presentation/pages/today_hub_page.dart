import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
import '../../../money/domain/usecases/get_transactions_and_budget_usecase.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/timeline_item_entity.dart';
import '../bloc/today_hub_bloc.dart';
import '../widgets/habit_form_sheet.dart';

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
      backgroundColor: isDark
          ? AppColors.darkScaffoldBackground
          : AppColors.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<TodayHubBloc, TodayHubState>(
          builder: (context, state) {
            if (state is TodayHubLoading || state is TodayHubInitial) {
              return const _LoadingView();
            }
            if (state is TodayHubError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Error: ${state.message}',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.read<TodayHubBloc>().add(
                              const LoadTodayHub(),
                            ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
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

// ── Loaded view with modernized Header, Momentum Ring & Live Glance ──────────
class _LoadedView extends StatelessWidget {
  final TodayHubLoaded state;
  final bool isDark;

  const _LoadedView({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final spendSnapshotFuture = sl.isRegistered<GetDailySpendSnapshotUseCase>()
        ? sl<GetDailySpendSnapshotUseCase>()()
        : null;

    return FutureBuilder<DailySpendSnapshot>(
      future: spendSnapshotFuture,
      builder: (context, snapshot) {
        final spendData = snapshot.data;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar with Avatar, Full Date Format & Audio Briefing Pill
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: _buildHeader(context, spendData),
              ),
            ),

            // Modern Hero Momentum Card with Score Ring & Daily Stats Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildHeroCard(context, spendData),
              ),
            ),

            // Daily Safe-to-Spend Meter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SafeSpendMeterWidget(
                  spentToday: spendData?.spentToday ?? 450,
                  dailySafeLimit: spendData?.dailySafeLimit ?? 1200,
                  daysRemaining: spendData?.daysRemaining ?? 12,
                  monthlyBudget: spendData?.monthlyBudget ?? 35000,
                  onLogExpense: () async {
                    await QuickCaptureSheet.show(context, mode: QuickCaptureMode.text);
                    if (context.mounted) {
                      context.read<TodayHubBloc>().add(const LoadTodayHub());
                    }
                  },
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
                          Row(
                            children: [
                              Text(
                                '${state.completedHabits}/${state.habits.length} completed',
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                borderRadius: AppRadius.radiusFull,
                                onTap: () => HabitFormSheet.show(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.12),
                                    borderRadius: AppRadius.radiusFull,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_rounded,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 11,
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
                        itemCount: state.habits.length + 1,
                        separatorBuilder: (context, index) => AppSpacing.gapW12,
                        itemBuilder: (context, index) {
                          if (index == state.habits.length) {
                            return const _AddHabitCard();
                          }
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
                            color: isDark
                                ? AppColors.darkTextCaption
                                : AppColors.textCaption,
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
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: 84,
                  top: 4,
                ),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSecondary
                        : AppColors.surfaceSecondary,
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
                                color: isDark
                                    ? AppColors.darkTextCaption
                                    : AppColors.textCaption,
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
                              content: Text(
                                'Evening Wrap-Up opens automatically at 9:30 PM.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.moduleVault,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusSm,
                          ),
                        ),
                        child: const Text(
                          'Review',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Header with Avatar, Dynamic Date & Greeting ────────────────────────────
  Widget _buildHeader(BuildContext context, DailySpendSnapshot? spendData) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM').format(now).toUpperCase();

    return Row(
      children: [
        // Profile Avatar Monogram with glowing border & active indicator
        Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkScaffoldBackground
                        : AppColors.scaffoldBackground,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),

        // Date & Dynamic Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _greetingIcon(),
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'TODAY • $formattedDate',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Good ${_greeting()}, Aarav',
                style: AppTextStyles.headingMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  fontSize: 20,
                  color: isDark
                      ? AppColors.darkTextHeading
                      : AppColors.textHeading,
                ),
              ),
            ],
          ),
        ),

        // "Play My Day" Audio Briefing Pill
        GestureDetector(
          onTap: () => AudioBriefingSheet.show(
            context,
            userName: 'Aarav',
            habits: state.habits,
            timelineItems: state.timelineItems,
            spendSnapshot: spendData,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(
                alpha: isDark ? 0.2 : 0.1,
              ),
              borderRadius: AppRadius.radiusFull,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
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
    );
  }

  // ── Hero Momentum Card with Score Ring & Daily Stats Bar ───────────────────
  Widget _buildHeroCard(BuildContext context, DailySpendSnapshot? spendData) {
    final totalHabits = state.habits.length;
    final completedHabits = state.completedHabits;
    final totalTimeline = state.timelineItems.length;
    final completedTimeline = state.timelineItems.where((t) => t.isDone).length;
    final pendingTimeline = totalTimeline - completedTimeline;

    final totalGoals = totalHabits + totalTimeline;
    final completedGoals = completedHabits + completedTimeline;
    final momentumScore = totalGoals > 0
        ? ((completedGoals / totalGoals) * 100).round()
        : 0;

    String momentumLabel;
    if (momentumScore == 100) {
      momentumLabel = 'Peak Flow 🌟';
    } else if (momentumScore >= 65) {
      momentumLabel = 'High Momentum 🔥';
    } else if (momentumScore >= 35) {
      momentumLabel = 'On Track ⚡';
    } else if (momentumScore > 0) {
      momentumLabel = 'Building Pace 🌱';
    } else {
      momentumLabel = 'Ready to Win 🎯';
    }

    final safeSpendText = spendData != null
        ? '₹${spendData.dailySafeLimit.toStringAsFixed(0)}'
        : '₹1,200';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDecorations.heroPrimaryGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: AppRadius.radiusFull,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  momentumLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Middle: Text Info & Momentum Score Ring
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      '${state.completedHabits} routines completed • $pendingTimeline tasks pending',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Visual Progress Track
                    ClipRRect(
                      borderRadius: AppRadius.radiusFull,
                      child: LinearProgressIndicator(
                        value: totalGoals > 0 ? (completedGoals / totalGoals) : 0.0,
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Circular Momentum Score Ring
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: totalGoals > 0 ? (completedGoals / totalGoals) : 0.0,
                        strokeWidth: 6.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$momentumScore%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'MOMENTUM',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom: Live Daily Glance Stats Bar
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: AppRadius.radiusLg,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGlanceMetric(
                  icon: Icons.repeat_rounded,
                  value: '${state.completedHabits}/${state.habits.length}',
                  label: 'Habits Done',
                ),
                Container(
                  height: 26,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                _buildGlanceMetric(
                  icon: Icons.checklist_rounded,
                  value: '$pendingTimeline left',
                  label: 'Tasks Pending',
                ),
                Container(
                  height: 26,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                _buildGlanceMetric(
                  icon: Icons.shield_rounded,
                  value: safeSpendText,
                  label: 'Safe Spend',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlanceMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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

  IconData _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.nightlight_round;
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
      onLongPress: () => HabitFormSheet.show(context, habit: habit),
    );
  }
}

// ── Add habit card ────────────────────────────────────────────────────────────
class _AddHabitCard extends StatelessWidget {
  const _AddHabitCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => HabitFormSheet.show(context),
      child: Container(
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceSecondary.withValues(alpha: 0.5)
              : AppColors.surfaceSecondary.withValues(alpha: 0.6),
          borderRadius: AppRadius.radiusLg,
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.primary.withValues(alpha: 0.14),
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add Habit',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.darkTextHeading : AppColors.textHeading,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'New Routine',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color:
                    isDark ? AppColors.darkTextCaption : AppColors.textCaption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: isDone
              ? color.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkDivider : AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Time badge (fixed width so every title starts on the same line)
          Container(
            width: 72,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 5),
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
                fontFeatures: const [FontFeature.tabularFigures()],
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
                    color: isDark
                        ? AppColors.darkTextHeading
                        : AppColors.textHeading,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextCaption
                        : AppColors.textCaption,
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
