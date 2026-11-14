import 'dart:async';
import 'package:daily_life_os/core/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/theme_context.dart';
import '../../../../core/constants/string_constants.dart';
import '../../../../core/services/tts/tts_service.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../di/injection_container.dart';
import '../../../money/domain/usecases/get_transactions_and_budget_usecase.dart';
import '../../../planner/domain/entities/planner_item_entity.dart';
import '../../../planner/domain/usecases/get_planner_items_usecase.dart';
import '../../domain/entities/habit_entity.dart';
import '../../domain/entities/timeline_item_entity.dart';
import '../../domain/usecases/get_habits_usecase.dart';
import '../../domain/usecases/get_today_timeline_usecase.dart';

/// Represents a structured section of Today's Audio Briefing.
class AudioBriefingSection {
  final String id;
  final String title;
  final String badgeText;
  final String spokenScript;
  final List<String> activityHighlights;
  final IconData icon;
  final Color accentColor;

  const AudioBriefingSection({
    required this.id,
    required this.title,
    required this.badgeText,
    required this.spokenScript,
    required this.activityHighlights,
    required this.icon,
    required this.accentColor,
  });
}

class AudioBriefingSheet extends StatefulWidget {
  final String userName;
  final bool autoPlay;
  final List<HabitEntity>? habits;
  final List<TimelineItemEntity>? timelineItems;
  final List<PlannerItemEntity>? plannerItems;
  final DailySpendSnapshot? spendSnapshot;

  const AudioBriefingSheet({
    super.key,
    this.userName = 'Aarav',
    this.autoPlay = true,
    this.habits,
    this.timelineItems,
    this.plannerItems,
    this.spendSnapshot,
  });

  static Future<void> show(
    BuildContext context, {
    String userName = 'Aarav',
    bool autoPlay = true,
    List<HabitEntity>? habits,
    List<TimelineItemEntity>? timelineItems,
    List<PlannerItemEntity>? plannerItems,
    DailySpendSnapshot? spendSnapshot,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) => AudioBriefingSheet(
        userName: userName,
        autoPlay: autoPlay,
        habits: habits,
        timelineItems: timelineItems,
        plannerItems: plannerItems,
        spendSnapshot: spendSnapshot,
      ),
    );
  }

  @override
  State<AudioBriefingSheet> createState() => _AudioBriefingSheetState();
}

class _AudioBriefingSheetState extends State<AudioBriefingSheet> {
  late final AppTtsService _tts;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _speed = 1.0;

  /// `-1` means playing/viewing the full combined briefing across all sections;
  /// `0..sections.length - 1` means focused on a specific activity section.
  int _activeSectionIndex = -1;

  List<HabitEntity>? _habits;
  List<TimelineItemEntity>? _timelineItems;
  List<PlannerItemEntity>? _plannerItems;
  DailySpendSnapshot? _spendSnapshot;
  late List<AudioBriefingSection> _sections;

  @override
  void initState() {
    super.initState();
    _habits = widget.habits;
    _timelineItems = widget.timelineItems;
    _plannerItems = widget.plannerItems;
    _spendSnapshot = widget.spendSnapshot;

    _sections = _buildSections();

    _tts = getAppTtsService();
    _tts.setCallbacks(
      onStart: () {
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _isPaused = false;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isPaused = false;
          });
        }
      },
      onError: (msg) {
        debugPrint('TTS Error: $msg');
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isPaused = false;
          });
        }
      },
    );

    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_playOrResume());
        }
      });
    }
    unawaited(_loadDynamicDataIfNeeded());
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Future<void> _loadDynamicDataIfNeeded() async {
    try {
      var updated = false;
      if (_habits == null && sl.isRegistered<GetHabitsUseCase>()) {
        _habits = await sl<GetHabitsUseCase>()();
        updated = true;
      }
      if (_timelineItems == null &&
          sl.isRegistered<GetTodayTimelineUseCase>()) {
        _timelineItems = await sl<GetTodayTimelineUseCase>()();
        updated = true;
      }
      if (_plannerItems == null && sl.isRegistered<GetPlannerItemsUseCase>()) {
        final now = DateTime.now();
        final todayIso =
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        _plannerItems = await sl<GetPlannerItemsUseCase>()(todayIso);
        updated = true;
      }
      if (_spendSnapshot == null &&
          sl.isRegistered<GetDailySpendSnapshotUseCase>()) {
        _spendSnapshot = await sl<GetDailySpendSnapshotUseCase>()();
        updated = true;
      }
      if (updated && mounted) {
        setState(() {
          _sections = _buildSections();
        });
        if (_isPlaying) {
          await _tts.speak(_activeScript, rate: _speed);
        }
      }
    } catch (e) {
      debugPrint('AudioBriefingSheet dynamic load error: $e');
    }
  }

  List<AudioBriefingSection> _buildSections() {
    final habits = _habits ?? const <HabitEntity>[];
    final timeline = _timelineItems ?? const <TimelineItemEntity>[];
    final planner = _plannerItems ?? const <PlannerItemEntity>[];
    final spend = _spendSnapshot;

    final habitsDone = habits.where((h) => h.isDoneToday).toList();
    final habitsPending = habits
        .where((h) => !h.isDoneToday && !h.isSkippedToday)
        .toList();
    final timelineDone = timeline.where((t) => t.isDone).toList();
    final timelinePending = timeline.where((t) => !t.isDone).toList();
    final todayPlannerTasks = planner
        .where((p) => (p.isToday || p.isOverdue || p.isRecurring) && !p.isDone)
        .toList();

    final totalActivities = habits.length + timeline.length;
    final completedActivities = habitsDone.length + timelineDone.length;
    final completionPct = totalActivities > 0
        ? ((completedActivities / totalActivities) * 100).round()
        : 0;

    int topStreak = 0;
    HabitEntity? topStreakHabit;
    for (final h in habits) {
      if (h.streakDays > topStreak) {
        topStreak = h.streakDays;
        topStreakHabit = h;
      }
    }

    // 1. Overview Section
    final overviewScript = StringBuffer()
      ..write(
        'Good ${_greeting()}, ${widget.userName}! Here is your complete Daily Life OS briefing for today. ',
      );
    if (totalActivities > 0) {
      overviewScript.write(
        'You have completed $completedActivities of $totalActivities daily activities, putting your momentum at $completionPct percent. ',
      );
    } else {
      overviewScript.write(
        'Your day is open and ready for new habits and scheduled focus blocks. ',
      );
    }
    if (topStreakHabit != null && topStreak > 0) {
      overviewScript.write(
        'Your longest active streak is ${topStreakHabit.title} at $topStreak days.',
      );
    }

    final overviewHighlights = <String>[
      '$completionPct% daily completion ($completedActivities/$totalActivities activities done)',
      if (topStreakHabit != null && topStreak > 0)
        'Top streak: ${topStreakHabit.title} ($topStreak days)'
      else
        'Complete a habit today to start a new streak',
      '${habitsPending.length} habits & ${timelinePending.length} timeline tasks remaining today',
    ];

    // 2. Habits & Micro-Routines Section
    final habitsScript = StringBuffer();
    final habitHighlights = <String>[];
    if (habits.isNotEmpty) {
      habitsScript.write(
        'In Habits and Micro-Routines, you have completed ${habitsDone.length} out of ${habits.length} habits today. ',
      );
      if (habitsDone.isNotEmpty) {
        final doneNames = habitsDone.take(3).map((h) => h.title).join(', ');
        habitsScript.write('Completed so far: $doneNames. ');
        habitHighlights.add(
          'Completed (${habitsDone.length}): ${habitsDone.map((h) => h.title).join(', ')}',
        );
      }
      if (habitsPending.isNotEmpty) {
        final pendingNames = habitsPending
            .take(4)
            .map((h) => h.title)
            .join(', ');
        habitsScript.write('Remaining for today: $pendingNames.');
        for (final h in habitsPending.take(4)) {
          habitHighlights.add(
            'Pending: ${h.title} (${h.category} • ${h.streakDays}d streak)',
          );
        }
      } else {
        habitsScript.write(
          'Every single habit for today is complete. Outstanding consistency!',
        );
        habitHighlights.add('All daily habits are completed for today!');
      }
    } else {
      habitsScript.write(
        'You currently have 3 active daily routines with hydration leading on a 12-day streak.',
      );
      habitHighlights.add('No custom habits added yet — tap Add on Today Hub');
    }

    // 3. Today's Schedule & Planner Tasks Section
    final scheduleScript = StringBuffer();
    final scheduleHighlights = <String>[];
    if (timeline.isNotEmpty || todayPlannerTasks.isNotEmpty) {
      if (timelinePending.isNotEmpty) {
        final nextItem = timelinePending.first;
        scheduleScript.write(
          'On Today\'s Timeline, you have ${timelinePending.length} upcoming items and ${timelineDone.length} completed. '
          'Your next scheduled activity is ${nextItem.title} at ${nextItem.time} under ${nextItem.category}. ',
        );
        for (final item in timelinePending.take(4)) {
          scheduleHighlights.add(
            '${item.time} • ${item.title} (${item.category})',
          );
        }
      } else if (timeline.isNotEmpty) {
        scheduleScript.write(
          'All ${timeline.length} scheduled timeline activities for today are completed! ',
        );
        scheduleHighlights.add(
          'All ${timeline.length} timeline items completed today',
        );
      }

      if (todayPlannerTasks.isNotEmpty) {
        final topTask = todayPlannerTasks.first;
        scheduleScript.write(
          'In your Planner, you also have ${todayPlannerTasks.length} active reminder${todayPlannerTasks.length == 1 ? '' : 's'}, starting with ${topTask.title}.',
        );
        for (final p in todayPlannerTasks.take(3)) {
          final timeTag = p.timeRange.isNotEmpty ? '${p.timeRange} • ' : '';
          scheduleHighlights.add(
            'Planner: $timeTag${p.title} (${p.priority.toUpperCase()})',
          );
        }
      }
    } else {
      scheduleScript.write(
        'Your schedule is clear right now, with no pending timeline blocks or reminders.',
      );
      scheduleHighlights.add('No pending timeline tasks scheduled for today');
    }

    // 4. Safe-to-Spend & Money Pulse Section
    final moneyScript = StringBuffer();
    final moneyHighlights = <String>[];
    final spentToday = spend?.spentToday ?? 1140.0;
    final safeLimit = (spend != null && spend.dailySafeLimit > 0)
        ? spend.dailySafeLimit
        : 1500.0;
    final daysRemaining = spend?.daysRemaining ?? 15;
    final monthlyBudget = spend?.monthlyBudget ?? 40000.0;
    final safeLeft = (safeLimit - spentToday).clamp(0.0, safeLimit);

    if (safeLeft > 0) {
      moneyScript.write(
        'For your Money Pulse, you have ${CurrencyUtils.format(safeLeft)} safe to spend today, '
        'with ${CurrencyUtils.format(spentToday)} spent so far out of your ${CurrencyUtils.format(safeLimit)} daily limit, '
        'and $daysRemaining days remaining in this budget cycle.',
      );
    } else {
      moneyScript.write(
        'For your Money Pulse, you have spent ${CurrencyUtils.format(spentToday)} today, reaching your ${CurrencyUtils.format(safeLimit)} daily safe-to-spend limit. '
        'Consider pausing non-essential expenses for the rest of the day.',
      );
    }
    moneyHighlights.add(
      'Safe to spend today: ${CurrencyUtils.format(safeLeft)} (Limit ${CurrencyUtils.format(safeLimit)})',
    );
    moneyHighlights.add('Spent today: ${CurrencyUtils.format(spentToday)}');
    moneyHighlights.add(
      'Monthly budget: ${CurrencyUtils.format(monthlyBudget)} ($daysRemaining days left)',
    );

    return [
      AudioBriefingSection(
        id: 'overview',
        title: StringConstants.audioBriefOverviewTitle,
        badgeText: '$completionPct% Done',
        spokenScript: overviewScript.toString(),
        activityHighlights: overviewHighlights,
        icon: Icons.bolt_rounded,
        accentColor: AppColors.primary,
      ),
      AudioBriefingSection(
        id: 'habits',
        title: StringConstants.audioBriefHabitsTitle,
        badgeText: '${habitsDone.length}/${habits.length} Done',
        spokenScript: habitsScript.toString(),
        activityHighlights: habitHighlights,
        icon: Icons.repeat_rounded,
        accentColor: AppColors.secondary,
      ),
      AudioBriefingSection(
        id: 'schedule',
        title: StringConstants.audioBriefScheduleTitle,
        badgeText: '${timelinePending.length} Pending',
        spokenScript: scheduleScript.toString(),
        activityHighlights: scheduleHighlights,
        icon: Icons.event_note_rounded,
        accentColor: AppColors.moduleTime,
      ),
      AudioBriefingSection(
        id: 'money',
        title: StringConstants.audioBriefMoneyTitle,
        badgeText: '${CurrencyUtils.format(safeLeft)} Safe',
        spokenScript: moneyScript.toString(),
        activityHighlights: moneyHighlights,
        icon: Icons.account_balance_wallet_rounded,
        accentColor: AppColors.moduleMoney,
      ),
    ];
  }

  String get _fullBriefingScript {
    final joined = _sections.map((s) => s.spokenScript).join(' ');
    return '$joined Stay focused and have a productive day!';
  }

  String get _activeScript {
    if (_activeSectionIndex >= 0 && _activeSectionIndex < _sections.length) {
      return _sections[_activeSectionIndex].spokenScript;
    }
    return _fullBriefingScript;
  }

  Future<void> _playOrResume() async {
    if (_isPaused) {
      await _tts.resume();
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isPaused = false;
        });
      }
    } else {
      await _tts.speak(_activeScript, rate: _speed);
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isPaused = false;
        });
      }
    }
  }

  Future<void> _speakSection(int index) async {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _activeSectionIndex = index;
      _isPlaying = true;
      _isPaused = false;
    });
    await _tts.stop();
    await _tts.speak(_activeScript, rate: _speed);
  }

  Future<void> _pause() async {
    await _tts.pause();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isPaused = true;
      });
    }
  }

  Future<void> _replay() async {
    unawaited(HapticFeedback.lightImpact());
    await _tts.stop();
    await _tts.speak(_activeScript, rate: _speed);
    if (mounted) {
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isPaused = false;
      });
    }
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  String get _statusLabel {
    if (_isPlaying) return StringConstants.audioBriefStatusPlaying;
    if (_isPaused) return StringConstants.audioBriefStatusPaused;
    return StringConstants.audioBriefStatusReady;
  }

  void _cycleSpeed() {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.25;
      } else if (_speed == 1.25) {
        _speed = 1.5;
      } else {
        _speed = 1.0;
      }
    });
    unawaited(_tts.setRate(_speed));
  }

  String get _speedLabel =>
      _speed == _speed.roundToDouble() ? '${_speed.toInt()}x' : '${_speed}x';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final media = MediaQuery.of(context);
    const accent = AppColors.primary;

    return Container(
      key: const ValueKey('audio_briefing_sheet'),
      constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xs,
        AppSpacing.pageGutter,
        AppSpacing.md + media.padding.bottom,
      ),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: AppRadius.topXl,
        border: Border.all(color: palette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
          AppSpacing.gapH16,

          // Header: icon · title/subtitle · close
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.textWhite,
                  size: 22,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.titleLarge(
                      StringConstants.audioBriefingSheetTitle,
                      color: palette.heading,
                    ),
                    const SizedBox(height: 2),
                    AppText.caption(
                      StringConstants.audioBriefingSheetSubtitle,
                      color: palette.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: 22,
                  color: palette.caption,
                ),
                onPressed: () {
                  unawaited(_stop());
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          AppSpacing.gapH16,

          // Status & Mode Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm + 4,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                // Equalizer bars (deterministic finite animation)
                SizedBox(
                  height: 18,
                  child: Row(
                    children: List.generate(8, (i) {
                      final activeHeight = 6.0 + ((i * 5) % 12);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 3),
                        width: 3,
                        height: _isPlaying ? activeHeight : 4.0,
                        decoration: BoxDecoration(
                          color: _isPlaying ? accent : palette.divider,
                          borderRadius: AppRadius.radiusFull,
                        ),
                      );
                    }),
                  ),
                ),
                AppSpacing.gapW8,
                Expanded(
                  child: AppText.captionBold(
                    _activeSectionIndex == -1
                        ? '$_statusLabel • All Activities'
                        : '$_statusLabel • ${_sections[_activeSectionIndex].title}',
                    softWrap: true,
                    color: _isPlaying ? accent : palette.caption,
                  ),
                ),
                if (_activeSectionIndex != -1)
                  InkWell(
                    onTap: () => _speakSection(-1),
                    borderRadius: AppRadius.radiusFull,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(
                          alpha: palette.isDark ? 0.22 : 0.12,
                        ),
                        borderRadius: AppRadius.radiusFull,
                      ),
                      child: AppText(
                        StringConstants.audioBriefPlayAll,
                        style: text.labelSmall?.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AppSpacing.gapH8,
          AppText(
            StringConstants.audioBriefTapSectionHint,
            style: text.labelSmall?.copyWith(
              fontSize: 11,
              color: palette.caption,
            ),
          ),
          AppSpacing.gapH8,

          // Scrollable Interactive Activity Briefing Sections
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < _sections.length; index++) ...[
                    if (index > 0) AppSpacing.gapH8,
                    _BriefingActivitySectionCard(
                      section: _sections[index],
                      isFocused: _activeSectionIndex == index,
                      isPlaying:
                          _isPlaying &&
                          (_activeSectionIndex == index ||
                              (_activeSectionIndex == -1 && index == 0)),
                      onTap: () => _speakSection(index),
                    ),
                  ],
                ],
              ),
            ),
          ),
          AppSpacing.gapH16,

          // Transport controls: speed left, replay/play/stop centred
          Row(
            children: [
              SizedBox(
                width: 58,
                child: TextButton(
                  key: const ValueKey('audio_briefing_speed_button'),
                  onPressed: _cycleSpeed,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(58, 38),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: palette.surfaceMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusFull,
                      side: BorderSide(color: palette.border),
                    ),
                  ),
                  child: AppText.titleSmall(
                    _speedLabel,
                    color: palette.heading,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Replay from start',
                iconSize: 24,
                color: palette.caption,
                icon: const Icon(Icons.replay_rounded),
                onPressed: _replay,
              ),
              AppSpacing.gapW12,
              SizedBox(
                width: 54,
                height: 54,
                child: IconButton.filled(
                  key: const ValueKey('audio_briefing_play_pause_button'),
                  tooltip: _isPlaying ? 'Pause' : 'Play',
                  style: IconButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: AppColors.textWhite,
                  ),
                  iconSize: 28,
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  onPressed: () async {
                    if (_isPlaying) {
                      await _pause();
                    } else {
                      await _playOrResume();
                    }
                  },
                ),
              ),
              AppSpacing.gapW12,
              IconButton(
                tooltip: 'Stop',
                iconSize: 24,
                color: palette.caption,
                icon: const Icon(Icons.stop_rounded),
                onPressed: _stop,
              ),
              const Spacer(),
              SizedBox(
                width: 58,
                child: IconButton(
                  tooltip: StringConstants.audioBriefPlayAll,
                  onPressed: () => _speakSection(-1),
                  icon: Icon(
                    Icons.playlist_play_rounded,
                    color: _activeSectionIndex == -1 ? accent : palette.caption,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BriefingActivitySectionCard extends StatelessWidget {
  final AudioBriefingSection section;
  final bool isFocused;
  final bool isPlaying;
  final VoidCallback onTap;

  const _BriefingActivitySectionCard({
    required this.section,
    required this.isFocused,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.text;
    final tint = section.accentColor;

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        key: ValueKey('audio_brief_section_${section.id}'),
        onTap: onTap,
        borderRadius: AppRadius.radiusMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: isFocused
                ? tint.withValues(alpha: palette.isDark ? 0.14 : 0.07)
                : palette.surfaceMuted.withValues(
                    alpha: palette.isDark ? 0.55 : 0.75,
                  ),
            borderRadius: AppRadius.radiusMd,
            border: Border.all(
              color: isFocused ? tint : palette.border,
              width: isFocused ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: tint.withValues(
                        alpha: palette.isDark ? 0.24 : 0.14,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(section.icon, size: 16, color: tint),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppText(
                      section.title,
                      softWrap: true,
                      style: text.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.heading,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tint.withValues(
                        alpha: palette.isDark ? 0.22 : 0.12,
                      ),
                      borderRadius: AppRadius.radiusFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPlaying
                              ? Icons.volume_up_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 12,
                          color: tint,
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          section.badgeText,
                          style: text.labelSmall?.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: tint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppText.bodyMedium(
                section.spokenScript,
                fontSize: 12.5,
                height: 1.45,
                color: palette.body,
              ),
              if (section.activityHighlights.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: section.activityHighlights.map((item) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: palette.border, width: 0.8),
                      ),
                      child: AppText(
                        item,
                        style: text.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: palette.heading,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
