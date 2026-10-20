import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_decorations.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/widgets/app_shimmer_loader.dart';
import '../../../../di/injection_container.dart';
import '../../domain/entities/planner_item_entity.dart';
import '../bloc/planner_bloc.dart';

class PlannerPage extends StatelessWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PlannerBloc>()
        ..add(LoadPlanner(DateTime.now().toIso8601String().substring(0, 10))),
      child: const _PlannerView(),
    );
  }
}

class _PlannerView extends StatefulWidget {
  const _PlannerView();

  @override
  State<_PlannerView> createState() => _PlannerViewState();
}

class _PlannerViewState extends State<_PlannerView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Pomodoro Focus Timer — stays local (pure UI state, not stored)
  int _secondsRemaining = 25 * 60;
  bool _isTimerRunning = false;
  Timer? _timer;
  bool _isWorkSprint = true;

  // Countdowns (static for now — will be DB in next iteration)
  final List<Map<String, dynamic>> _countdowns = [
    {
      'title': "Sarah's 28th Birthday",
      'date': DateTime.now().add(const Duration(days: 5)),
      'icon': Icons.cake_rounded,
      'color': AppColors.moduleNotes,
    },
    {
      'title': 'Car Insurance Renewal',
      'date': DateTime.now().add(const Duration(days: 24)),
      'icon': Icons.directions_car_rounded,
      'color': AppColors.moduleTime,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      setState(() => _isTimerRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _timer?.cancel();
          setState(() {
            _isTimerRunning = false;
            _isWorkSprint = !_isWorkSprint;
            _secondsRemaining = _isWorkSprint ? (25 * 60) : (5 * 60);
          });
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = _isWorkSprint ? (25 * 60) : (5 * 60);
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkScaffoldBackground : AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text(
          StringConstants.navPlanner,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          BlocBuilder<PlannerBloc, PlannerState>(
            builder: (context, state) {
              if (state is PlannerLoaded) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${state.completedCount}/${state.items.length} done',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.moduleTime,
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.moduleTime,
          unselectedLabelColor: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
          indicatorColor: AppColors.moduleTime,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Reminders'),
            Tab(text: 'Pomodoro Focus'),
            Tab(text: 'Countdowns'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRemindersTab(context, isDark),
          _buildFocusTimerTab(isDark),
          _buildCountdownsTab(isDark),
        ],
      ),
    );
  }

  // ── Tab 1: Reminders (DB-backed via PlannerBloc) ─────────────────────────
  Widget _buildRemindersTab(BuildContext context, bool isDark) {
    return BlocBuilder<PlannerBloc, PlannerState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
          children: [
            // Natural Language Quick Add Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
                borderRadius: AppRadius.radiusLg,
                border: Border.all(color: AppColors.moduleTime.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_alarm_rounded, color: AppColors.moduleTime),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Type e.g. "Doctor appointment tomorrow at 4pm"',
                      style: TextStyle(fontSize: 13, color: AppColors.textCaption),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: AppColors.moduleTime),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items from DB
            if (state is PlannerLoading || state is PlannerInitial)
              ...[1, 2, 3].map((_) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: AppShimmerLoader.card(height: 100),
                  ))
            else if (state is PlannerLoaded) ...[
              if (state.items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(
                      'No tasks today. Tap the mic or type above!',
                      style: TextStyle(color: isDark ? AppColors.darkTextCaption : AppColors.textCaption),
                    ),
                  ),
                )
              else
                ...state.items.map((item) => _buildPlannerItemCard(context, item, isDark)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPlannerItemCard(BuildContext context, PlannerItemEntity item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.radiusLg,
        border: Border.all(
          color: item.isDone
              ? AppColors.success.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkDivider : AppColors.divider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: item.isDone,
                activeColor: AppColors.moduleTime,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusSm),
                onChanged: (_) => context.read<PlannerBloc>().add(TogglePlannerItem(item.id)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextHeading : AppColors.textHeading,
                        decoration: item.isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.timeRange.isNotEmpty)
                          Text(
                            item.timeRange,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                            ),
                          ),
                        if (item.category.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.14),
                              borderRadius: AppRadius.radiusSm,
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: item.color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: AppColors.error.withValues(alpha: 0.6), size: 18),
                onPressed: () => context.read<PlannerBloc>().add(DeletePlannerItem(item.id)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Snoozed for 15 minutes.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: const Text('Snooze +15m', style: TextStyle(fontSize: 11)),
              ),
              AppSpacing.gapW8,
              FilledButton.tonal(
                onPressed: () => context.read<PlannerBloc>().add(TogglePlannerItem(item.id)),
                style: FilledButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: AppColors.moduleTime.withValues(alpha: 0.15),
                  foregroundColor: AppColors.moduleTime,
                ),
                child: Text(
                  item.isDone ? 'Undo' : 'Mark Done',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Pomodoro Focus Timer (local UI state — no DB needed) ───────────
  Widget _buildFocusTimerTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 90),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppDecorations.heroTimeGradient,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  _isWorkSprint ? '⚡ DEEP WORK SPRINT' : '☕ SHORT BREAK',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _formatTimer(_secondsRemaining),
                style: AppTextStyles.timerHero.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Linked Task: "Finalize Daily Life OS PRD"',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _toggleTimer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.moduleTimeDark,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.radiusLg),
                    ),
                    icon: Icon(_isTimerRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: Text(
                      _isTimerRunning ? 'Pause' : 'Start Focus',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: _resetTimer,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Focus Settings & Presets', style: AppTextStyles.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPresetChip('25m Work / 5m Break', true, isDark),
            AppSpacing.gapW8,
            _buildPresetChip('50m Deep / 10m Break', false, isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildPresetChip(String label, bool isSelected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.moduleTime.withValues(alpha: 0.15)
            : (isDark ? AppColors.darkCardBackground : AppColors.cardBackground),
        borderRadius: AppRadius.radiusMd,
        border: Border.all(
          color: isSelected ? AppColors.moduleTime : (isDark ? AppColors.darkDivider : AppColors.divider),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.moduleTime : (isDark ? AppColors.darkTextBody : AppColors.textBody),
        ),
      ),
    );
  }

  // ── Tab 3: Countdowns ─────────────────────────────────────────────────────
  Widget _buildCountdownsTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 90),
      children: [
        ..._countdowns.map((cd) {
          final color = cd['color'] as Color;
          final targetDate = cd['date'] as DateTime;
          final daysLeft = targetDate.difference(DateTime.now()).inDays;
          final monthAbbr = _monthAbbr(targetDate.month);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.divider),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Icon(cd['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cd['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        '$monthAbbr ${targetDate.day} (In $daysLeft days)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextCaption : AppColors.textCaption,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: AppRadius.radiusMd,
                  ),
                  child: Text(
                    '${daysLeft}d left',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _monthAbbr(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[m - 1];
  }
}
