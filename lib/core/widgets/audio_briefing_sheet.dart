import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../../di/injection_container.dart';
import '../../features/money/domain/usecases/get_transactions_and_budget_usecase.dart';
import '../../features/today_hub/data/datasources/today_hub_local_datasource.dart';
import '../../features/today_hub/domain/entities/habit_entity.dart';
import '../../features/today_hub/domain/entities/timeline_item_entity.dart';
import '../services/tts/tts_service.dart';

class AudioBriefingSheet extends StatefulWidget {
  final String userName;
  final List<HabitEntity>? habits;
  final List<TimelineItemEntity>? timelineItems;
  final DailySpendSnapshot? spendSnapshot;

  const AudioBriefingSheet({
    super.key,
    this.userName = 'Aarav',
    this.habits,
    this.timelineItems,
    this.spendSnapshot,
  });

  static Future<void> show(
    BuildContext context, {
    String userName = 'Aarav',
    List<HabitEntity>? habits,
    List<TimelineItemEntity>? timelineItems,
    DailySpendSnapshot? spendSnapshot,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AudioBriefingSheet(
        userName: userName,
        habits: habits,
        timelineItems: timelineItems,
        spendSnapshot: spendSnapshot,
      ),
    );
  }

  @override
  State<AudioBriefingSheet> createState() => _AudioBriefingSheetState();
}

class _AudioBriefingSheetState extends State<AudioBriefingSheet>
    with SingleTickerProviderStateMixin {
  late final AppTtsService _tts;
  bool _isPlaying = false;
  bool _isPaused = false;
  double _speed = 1.0;
  late AnimationController _animController;
  late String _briefingScript;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _briefingScript = _generateMelodicScript(
      userName: widget.userName,
      greeting: _greeting(),
      habits: widget.habits,
      timelineItems: widget.timelineItems,
      spendSnapshot: widget.spendSnapshot,
    );

    _tts = getAppTtsService();
    _tts.setCallbacks(
      onStart: () {
        if (mounted) {
          setState(() {
            _isPlaying = true;
            _isPaused = false;
          });
          _animController.repeat(reverse: true);
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isPaused = false;
          });
          _animController.stop();
        }
      },
      onError: (msg) {
        debugPrint('TTS Error: $msg');
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _isPaused = false;
          });
          _animController.stop();
        }
      },
    );

    _startInitialPlayback();
    _loadDynamicDataIfEmpty();
  }

  Future<void> _startInitialPlayback() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      await _playOrResume();
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  String _generateMelodicScript({
    required String userName,
    required String greeting,
    List<HabitEntity>? habits,
    List<TimelineItemEntity>? timelineItems,
    DailySpendSnapshot? spendSnapshot,
  }) {
    final buffer = StringBuffer();
    buffer.write(
      'Namaste $userName! 🎶 Wishing you a very sweet and bright $greeting. '
      'Here is your Daily Life OS briefing. ',
    );

    // 1. Habits
    if (habits != null && habits.isNotEmpty) {
      final done = habits.where((h) => h.isDoneToday).length;
      final withStreak = habits.where((h) => h.streakDays > 0).toList();
      buffer.write(
        'You have ${habits.length} daily habits, with $done already completed. ',
      );
      if (withStreak.isNotEmpty) {
        withStreak.sort((a, b) => b.streakDays.compareTo(a.streakDays));
        final top = withStreak.first;
        buffer.write(
          'Your ${top.title} is shining bright on an inspiring ${top.streakDays}-day streak! ',
        );
      }
    } else {
      buffer.write(
        'You have 3 active routines with hydration on an inspiring 12-day streak. ',
      );
    }

    // 2. Timeline / Agenda
    if (timelineItems != null && timelineItems.isNotEmpty) {
      final pending = timelineItems.where((t) => !t.isDone).toList();
      if (pending.isNotEmpty) {
        final next = pending.first;
        buffer.write(
          'Your next important moment is ${next.title} at ${next.time}. ',
        );
        if (pending.length > 1) {
          buffer.write('You have ${pending.length} tasks scheduled today. ');
        }
      } else {
        buffer.write(
          'All your scheduled tasks for today are gracefully completed! Wonderful job. ',
        );
      }
    } else {
      buffer.write(
        'Your top priority today is finalizing the project scope by 4 PM. ',
      );
    }

    // 3. Safe-to-Spend Finance
    if (spendSnapshot != null) {
      final safeLeft = spendSnapshot.dailySafeLimit - spendSnapshot.spentToday;
      if (safeLeft > 0) {
        buffer.write(
          'Your daily safe-to-spend budget is ₹${safeLeft.toStringAsFixed(0)}, with ₹${spendSnapshot.spentToday.toStringAsFixed(0)} spent so far. ',
        );
      } else {
        buffer.write(
          'You have reached today\'s spend threshold. Let us take mindful care of our savings today. ',
        );
      }
    } else {
      buffer.write(
        'Your safe-to-spend budget for today is ₹1,200, with 12 peaceful days remaining this month. ',
      );
    }

    buffer.write(
      'Stay inspired, stay in rhythm, and have a harmonious, productive day! 🎵',
    );
    return buffer.toString();
  }

  Future<void> _loadDynamicDataIfEmpty() async {
    if (widget.habits == null && sl.isRegistered<TodayHubLocalDataSource>()) {
      try {
        final ds = sl<TodayHubLocalDataSource>();
        final habits = await ds.getHabits();
        final timeline = await ds.getTodayTimeline();
        DailySpendSnapshot? spend;
        if (sl.isRegistered<GetDailySpendSnapshotUseCase>()) {
          spend = await sl<GetDailySpendSnapshotUseCase>()();
        }
        if (mounted) {
          setState(() {
            _briefingScript = _generateMelodicScript(
              userName: widget.userName,
              greeting: _greeting(),
              habits: habits,
              timelineItems: timeline,
              spendSnapshot: spend,
            );
          });
          if (_isPlaying) {
            await _tts.speak(_briefingScript, rate: _speed);
          }
        }
      } catch (e) {
        debugPrint('Dynamic briefing load exception: $e');
      }
    }
  }

  Future<void> _playOrResume() async {
    if (_isPaused) {
      await _tts.resume();
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isPaused = false;
        });
        _animController.repeat(reverse: true);
      }
    } else {
      await _tts.speak(_briefingScript, rate: _speed);
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _isPaused = false;
        });
        _animController.repeat(reverse: true);
      }
    }
  }

  Future<void> _pause() async {
    await _tts.pause();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isPaused = true;
      });
      _animController.stop();
    }
  }

  Future<void> _replay() async {
    await _tts.stop();
    await _tts.speak(_briefingScript, rate: _speed);
    if (mounted) {
      setState(() {
        _isPlaying = true;
        _isPaused = false;
      });
      _animController.repeat(reverse: true);
    }
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _isPaused = false;
      });
      _animController.stop();
    }
  }

  @override
  void dispose() {
    _tts.dispose();
    _animController.dispose();
    super.dispose();
  }

  String get _statusLabel {
    if (_isPlaying) return 'Playing';
    if (_isPaused) return 'Paused';
    return 'Ready';
  }

  void _cycleSpeed() {
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.25;
      } else if (_speed == 1.25) {
        _speed = 1.5;
      } else {
        _speed = 1.0;
      }
    });
    _tts.setRate(_speed);
  }

  String get _speedLabel =>
      _speed == _speed.roundToDouble() ? '${_speed.toInt()}x' : '${_speed}x';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    const accent = AppColors.primary;

    final headingColor = isDark
        ? AppColors.darkTextHeading
        : AppColors.textHeading;
    final captionColor = isDark
        ? AppColors.darkTextCaption
        : AppColors.textCaption;
    final iconColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;
    final mutedFill = isDark
        ? AppColors.darkSurfaceSecondary
        : AppColors.surfaceSecondary;
    final dividerColor = isDark ? AppColors.darkDivider : AppColors.divider;

    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageGutter,
        AppSpacing.xs,
        AppSpacing.pageGutter,
        AppSpacing.md + media.padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
        borderRadius: AppRadius.topXl,
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
                color: dividerColor,
                borderRadius: AppRadius.radiusFull,
              ),
            ),
          ),
          AppSpacing.gapH16,

          // Header: icon · title/subtitle · close
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: AppRadius.radiusSm,
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Briefing',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your day in under a minute',
                      style: AppTextStyles.caption.copyWith(
                        color: captionColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close_rounded, size: 22, color: iconColor),
                onPressed: () {
                  _stop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          AppSpacing.gapH20,

          // Status row: compact waveform + label
          Row(
            children: [
              SizedBox(
                height: 20,
                child: Row(
                  children: List.generate(12, (i) {
                    return AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        final height = _isPlaying
                            ? 4.0 +
                                  16.0 *
                                      ((_animController.value + i * 0.17) % 1.0)
                            : 4.0;
                        return Container(
                          margin: const EdgeInsets.only(right: 3),
                          width: 3,
                          height: height,
                          decoration: BoxDecoration(
                            color: _isPlaying ? accent : dividerColor,
                            borderRadius: AppRadius.radiusFull,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
              AppSpacing.gapW8,
              Text(
                _statusLabel,
                style: AppTextStyles.captionBold.copyWith(
                  color: _isPlaying ? accent : captionColor,
                ),
              ),
            ],
          ),
          AppSpacing.gapH12,

          // Transcript (scrolls when long)
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxHeight: media.size.height * 0.32),
              decoration: BoxDecoration(
                color: mutedFill,
                borderRadius: AppRadius.radiusMd,
              ),
              child: SingleChildScrollView(
                padding: AppSpacing.edgeInsetsAllMd,
                child: Text(
                  _briefingScript,
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.55,
                    color: isDark ? AppColors.darkTextBody : AppColors.textBody,
                  ),
                ),
              ),
            ),
          ),
          AppSpacing.gapH24,

          // Transport controls: speed left, play/pause centred
          Row(
            children: [
              SizedBox(
                width: 56,
                child: TextButton(
                  onPressed: _cycleSpeed,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(56, 36),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: mutedFill,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.radiusFull,
                    ),
                  ),
                  child: Text(
                    _speedLabel,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: headingColor,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Replay from start',
                iconSize: 26,
                color: iconColor,
                icon: const Icon(Icons.replay_rounded),
                onPressed: _replay,
              ),
              AppSpacing.gapW16,
              SizedBox(
                width: 56,
                height: 56,
                child: IconButton.filled(
                  tooltip: _isPlaying ? 'Pause' : 'Play',
                  style: IconButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                  ),
                  iconSize: 30,
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
              AppSpacing.gapW16,
              IconButton(
                tooltip: 'Stop',
                iconSize: 26,
                color: iconColor,
                icon: const Icon(Icons.stop_rounded),
                onPressed: _stop,
              ),
              const Spacer(),
              const SizedBox(width: 56),
            ],
          ),
        ],
      ),
    );
  }
}
