import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../core/widgets/audio_briefing_sheet.dart';
import '../../../../core/widgets/feature_scaffold.dart';
import '../../../../core/widgets/habit_bubble_widget.dart';
import '../../../../core/widgets/quick_capture_sheet.dart';
import '../../../../core/widgets/safe_spend_meter_widget.dart';
import '../../../../di/injection_container.dart';
import '../../../money/domain/usecases/get_transactions_and_budget_usecase.dart';
import '../../domain/entities/timeline_item_entity.dart';
import '../bloc/today_hub_bloc.dart';

/// Bottom inset so the last card clears the floating Quick-Capture bar.
const double _kFloatingBarClearance = 96;

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

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  static FeatureStatus _statusOf(TodayHubState state) {
    if (state is TodayHubLoaded) return FeatureStatus.content;
    if (state is TodayHubError) return FeatureStatus.error;
    return FeatureStatus.loading;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return BlocBuilder<TodayHubBloc, TodayHubState>(
      builder: (context, state) {
        final loaded = state is TodayHubLoaded ? state : null;

        return FeatureScaffold(
          title: 'Good ${_greeting()}, Aarav',
          subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.isDark
                  ? AppColors.darkPrimaryContainer
                  : AppColors.primaryContainer,
            ),
            child: Text(
              'A',
              style: context.text.titleMedium?.copyWith(
                color: palette.isDark
                    ? AppColors.primaryLight
                    : AppColors.primaryDark,
              ),
            ),
          ),
          actionsEndPadding: AppSpacing.pageGutter,
          actions: [
            FeatureIconButton(
              icon: Icons.graphic_eq_rounded,
              tooltip: StringConstants.playBriefing,
              color: AppColors.primary,
              onPressed: () => AudioBriefingSheet.show(
                context,
                userName: 'Aarav',
                habits: loaded?.habits,
                timelineItems: loaded?.timelineItems,
              ),
            ),
          ],
          status: _statusOf(state),
          errorMessage: state is TodayHubError ? state.message : null,
          onRetry: () => context.read<TodayHubBloc>().add(const LoadTodayHub()),
          loading: const _TodayLoadingView(),
          builder: (_) => _TodayContent(state: loaded!),
        );
      },
    );
  }
}

// ── Loading skeleton mirroring the real layout ───────────────────────────────
class _TodayLoadingView extends StatelessWidget {
  const _TodayLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.sm,
        AppSpacing.pageGutter,
        AppSpacing.xl,
      ),
      children: [
        const AppShimmerLoader.card(height: 168),
        AppSpacing.gapH16,
        const AppShimmerLoader.card(height: 116),
        AppSpacing.gapH24,
        const AppShimmerLoader(width: 140, height: 16),
        AppSpacing.gapH8,
        const AppShimmerLoader.card(height: 200),
        AppSpacing.gapH24,
        const AppShimmerLoader(width: 120, height: 16),
        AppSpacing.gapH8,
        const AppShimmerLoader.card(height: 240),
      ],
    );
  }
}

// ── Loaded content ───────────────────────────────────────────────────────────
class _TodayContent extends StatelessWidget {
  final TodayHubLoaded state;

  const _TodayContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final spendFuture = sl.isRegistered<GetDailySpendSnapshotUseCase>()
        ? sl<GetDailySpendSnapshotUseCase>()()
        : null;

    return FutureBuilder<DailySpendSnapshot>(
      future: spendFuture,
      builder: (context, snapshot) {
        final spend = snapshot.data;
        final pendingTasks = state.timelineItems.where((t) => !t.isDone).length;

        return ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.sm,
            AppSpacing.pageGutter,
            _kFloatingBarClearance,
          ),
          children: [
            // 1. Daily progress overview
            _OverviewCard(state: state, spend: spend),
            AppSpacing.gapH16,

            // 2. Safe-to-spend
            SafeSpendMeterWidget(
              spentToday: spend?.spentToday ?? 450,
              dailySafeLimit: spend?.dailySafeLimit ?? 1200,
              daysRemaining: spend?.daysRemaining ?? 12,
              monthlyBudget: spend?.monthlyBudget ?? 35000,
              onLogExpense: () async {
                await QuickCaptureSheet.show(
                  context,
                  mode: QuickCaptureMode.text,
                );
                if (context.mounted) {
                  context.read<TodayHubBloc>().add(const LoadTodayHub());
                }
              },
            ),
            AppSpacing.gapH24,

            // 3. Habits & routines - cohesive grouped card
            FeatureSectionHeader(
              title: StringConstants.habitsAndRoutines,
              trailingText:
                  '${state.completedHabits} of ${state.habits.length} done',
            ),
            AppSpacing.gapH8,
            if (state.habits.isEmpty)
              FeatureCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xl,
                ),
                child: Center(
                  child: Text('No habits yet', style: context.text.bodySmall),
                ),
              )
            else
              FeatureCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _HabitTopProgressBar(
                      done: state.completedHabits,
                      total: state.habits.length,
                    ),
                    for (var i = 0; i < state.habits.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 54),
                      HabitBubbleWidget(
                        title: state.habits[i].title,
                        icon: state.habits[i].icon,
                        streakDays: state.habits[i].streakDays,
                        isDone: state.habits[i].isDoneToday,
                        tintColor: state.habits[i].color,
                        onTap: () => context.read<TodayHubBloc>().add(
                          ToggleHabit(state.habits[i].id),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            AppSpacing.gapH24,
            // 4. Timeline
            FeatureSectionHeader(
              title: StringConstants.timelineFeed,
              trailingText: pendingTasks == 0
                  ? 'All done'
                  : '$pendingTasks remaining',
            ),
            AppSpacing.gapH8,
            _TimelineCard(items: state.timelineItems),
            AppSpacing.gapH24,

            // 5. Evening wrap-up
            const _EveningWrapUpCard(),
          ],
        );
      },
    );
  }
}

// ── Overview card: ring + summary + three metrics ────────────────────────────
class _OverviewCard extends StatelessWidget {
  final TodayHubLoaded state;
  final DailySpendSnapshot? spend;

  const _OverviewCard({required this.state, required this.spend});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final palette = context.palette;

    final totalHabits = state.habits.length;
    final doneHabits = state.completedHabits;
    final totalTasks = state.timelineItems.length;
    final doneTasks = state.timelineItems.where((t) => t.isDone).length;
    final pendingTasks = totalTasks - doneTasks;

    final total = totalHabits + totalTasks;
    final done = doneHabits + doneTasks;
    final progress = total > 0 ? done / total : 0.0;
    final score = (progress * 100).round();

    final (String label, IconData statusIcon, Color tone) = switch (score) {
      100 => ('Perfect day', Icons.stars_rounded, AppColors.success),
      >= 65 => ('High momentum', Icons.bolt_rounded, AppColors.success),
      >= 35 => ('On track', Icons.trending_up_rounded, AppColors.primary),
      > 0 => (
        'Building pace',
        Icons.directions_run_rounded,
        AppColors.moduleTime,
      ),
      _ => ('Ready to start', Icons.wb_sunny_outlined, palette.caption),
    };

    return FeatureCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Progress ring
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5.5,
                        strokeCap: StrokeCap.round,
                        backgroundColor: palette.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : palette.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation(
                          score == 100 ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '$score%',
                      style: text.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: palette.heading,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapW16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: tone.withValues(
                          alpha: palette.isDark ? 0.20 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 12, color: tone),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: text.labelSmall?.copyWith(
                              color: tone,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Daily Progress',
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16.5,
                        color: palette.heading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$done of $total daily goals completed',
                      style: text.bodySmall?.copyWith(
                        color: palette.caption,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapH16,
          Row(
            children: [
              _GlanceCapsule(
                dotColor: AppColors.success,
                label: 'Habits Done',
                value: '$doneHabits/$totalHabits',
              ),
              const SizedBox(width: 8),
              _GlanceCapsule(
                dotColor: AppColors.moduleTime,
                label: 'Tasks Pending',
                value: '$pendingTasks',
              ),
              const SizedBox(width: 8),
              _GlanceCapsule(
                dotColor: AppColors.moduleMoney,
                label: 'Safe Spend',
                value: CurrencyUtils.format(spend?.dailySafeLimit ?? 1200),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlanceCapsule extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;

  const _GlanceCapsule({
    required this.dotColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final palette = context.palette;
    final isDark = palette.isDark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : palette.surfaceMuted.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: palette.border.withValues(alpha: isDark ? 0.35 : 0.6),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.heading,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: palette.caption,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Habit progress top line ──────────────────────────────────────────────────
class _HabitTopProgressBar extends StatelessWidget {
  final int done;
  final int total;

  const _HabitTopProgressBar({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final progress = done / total;
    final palette = context.palette;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 3,
        backgroundColor: palette.surfaceMuted,
        valueColor: AlwaysStoppedAnimation(
          done == total ? AppColors.success : AppColors.primary,
        ),
      ),
    );
  }
}

// ── Timeline: one grouped card with inset dividers ───────────────────────────
class _TimelineCard extends StatelessWidget {
  final List<TimelineItemEntity> items;

  const _TimelineCard({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return FeatureCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xl,
        ),
        child: Center(
          child: Text('Nothing scheduled today', style: context.text.bodySmall),
        ),
      );
    }

    return FeatureCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 50),
            _TimelineRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final TimelineItemEntity item;

  const _TimelineRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final palette = context.palette;
    final isDone = item.isDone;
    void toggle() =>
        context.read<TodayHubBloc>().add(ToggleTimelineItem(item.id));

    return InkWell(
      onTap: toggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Check circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.success : Colors.transparent,
                border: Border.all(
                  color: isDone ? AppColors.success : palette.border,
                  width: 1.5,
                ),
              ),
              child: isDone
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            AppSpacing.gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDone ? palette.caption : palette.heading,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: palette.caption,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '${item.time}  ·  ${item.category}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: toggle,
              style: TextButton.styleFrom(
                foregroundColor: isDone ? palette.caption : AppColors.primary,
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: text.labelLarge?.copyWith(fontSize: 13),
              ),
              child: Text(isDone ? 'Undo' : item.action),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Evening wrap-up ──────────────────────────────────────────────────────────
class _EveningWrapUpCard extends StatelessWidget {
  const _EveningWrapUpCard();

  @override
  Widget build(BuildContext context) {
    final text = context.text;

    return FeatureCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.moduleVault.withValues(alpha: 0.12),
              borderRadius: AppRadius.radiusMd,
            ),
            child: const Icon(
              Icons.nightlight_round,
              size: 20,
              color: AppColors.moduleVault,
            ),
          ),
          AppSpacing.gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StringConstants.eveningWrapUpTitle,
                  style: text.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  StringConstants.eveningWrapUpSubtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          AppSpacing.gapW8,
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Evening Wrap-Up opens automatically at 9:30 PM.',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.moduleVault,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: text.labelLarge?.copyWith(fontSize: 13),
            ),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}
