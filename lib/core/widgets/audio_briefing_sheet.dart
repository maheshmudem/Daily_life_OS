import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
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
      'Here is your Daily Life OS morning melody briefing. ',
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

    buffer.write('Stay inspired, stay in rhythm, and have a harmonious, productive day! 🎵');
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: AppRadius.topXxl,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              borderRadius: AppRadius.radiusFull,
            ),
          ),
          const SizedBox(height: 16),

          // Shreya Ghoshal Melodic Voice Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.radiusFull,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note_rounded, size: 14, color: Colors.white),
                SizedBox(width: 5),
                Text(
                  'SHREYA GHOSHAL MELODIC VOICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Audio Title & Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_external_on_rounded,
                  color: Color(0xFFEC4899),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Personal Audio Briefing',
                style: AppTextStyles.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Melodic Audio Wave Bars (Pink to Purple Gradient)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(18, (i) {
              return AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final height = _isPlaying
                      ? 10.0 +
                          (32.0 *
                              ((_animController.value + (i * 0.11)) % 1.0))
                      : 6.0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.2),
                    width: 3.5,
                    height: height,
                    decoration: BoxDecoration(
                      gradient: _isPlaying
                          ? LinearGradient(
                              colors: [
                                Color.lerp(
                                  const Color(0xFFEC4899),
                                  const Color(0xFF8B5CF6),
                                  i / 18,
                                )!,
                                const Color(0xFF8B5CF6),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            )
                          : null,
                      color: _isPlaying ? null : AppColors.divider,
                      borderRadius: AppRadius.radiusFull,
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 20),

          // Live Transcript Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceSecondary
                  : AppColors.surfaceSecondary,
              borderRadius: AppRadius.radiusLg,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
              ),
            ),
            child: Text(
              _briefingScript,
              style: TextStyle(
                fontSize: 13,
                height: 1.55,
                color: isDark ? AppColors.darkTextBody : AppColors.textBody,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Controls Row (Speed, Replay, Play/Pause, Stop, Close)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () {
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
                },
                child: Text(
                  '${_speed}x',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFFEC4899),
                  ),
                ),
              ),
              IconButton(
                iconSize: 32,
                tooltip: 'Replay from start',
                icon: const Icon(Icons.replay_rounded),
                onPressed: _replay,
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  iconSize: 32,
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  color: Colors.white,
                  onPressed: () async {
                    if (_isPlaying) {
                      await _pause();
                    } else {
                      await _playOrResume();
                    }
                  },
                ),
              ),
              IconButton(
                iconSize: 32,
                tooltip: 'Stop audio',
                icon: const Icon(Icons.stop_rounded),
                onPressed: _stop,
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _stop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
