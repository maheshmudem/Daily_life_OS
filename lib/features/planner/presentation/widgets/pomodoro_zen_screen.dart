import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../config/theme/theme_context.dart';
import '../../domain/entities/planner_item_entity.dart';

/// Full-Screen Immersive Zen Focus Chamber inspired by Forest, Tide, and Endel.
/// Provides a distraction-free environment with breathing ambient rings,
/// soundscape controls, subtask toggles, and quick brain-dump capture.
class PomodoroZenScreen extends StatefulWidget {
  final int initialFocusModeIndex;
  final int currentRound;
  final int totalRounds;
  final int initialSecondsRemaining;
  final int totalModeSeconds;
  final bool initialIsRunning;
  final String linkedTask;
  final String focusCategory;
  final String initialAmbience;
  final double initialVolume;
  final PlannerItemEntity? linkedPlannerItem;
  final List<Map<String, dynamic>> ambienceOptions;
  final ValueChanged<ChecklistItem>? onToggleSubtask;
  final ValueChanged<String>? onCaptureDistraction;
  final ValueChanged<String>? onAmbienceChanged;
  final ValueChanged<double>? onVolumeChanged;
  final void Function(int secondsRemaining, bool isRunning) onSyncBack;

  const PomodoroZenScreen({
    super.key,
    required this.initialFocusModeIndex,
    required this.currentRound,
    required this.totalRounds,
    required this.initialSecondsRemaining,
    required this.totalModeSeconds,
    required this.initialIsRunning,
    required this.linkedTask,
    required this.focusCategory,
    required this.initialAmbience,
    required this.initialVolume,
    this.linkedPlannerItem,
    required this.ambienceOptions,
    this.onToggleSubtask,
    this.onCaptureDistraction,
    this.onAmbienceChanged,
    this.onVolumeChanged,
    required this.onSyncBack,
  });

  static Future<void> show(
    BuildContext context, {
    required int focusModeIndex,
    required int currentRound,
    required int totalRounds,
    required int secondsRemaining,
    required int totalModeSeconds,
    required bool isRunning,
    required String linkedTask,
    required String focusCategory,
    required String selectedAmbience,
    required double ambienceVolume,
    PlannerItemEntity? linkedPlannerItem,
    required List<Map<String, dynamic>> ambienceOptions,
    ValueChanged<ChecklistItem>? onToggleSubtask,
    ValueChanged<String>? onCaptureDistraction,
    ValueChanged<String>? onAmbienceChanged,
    ValueChanged<double>? onVolumeChanged,
    required void Function(int secondsRemaining, bool isRunning) onSyncBack,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: PomodoroZenScreen(
              initialFocusModeIndex: focusModeIndex,
              currentRound: currentRound,
              totalRounds: totalRounds,
              initialSecondsRemaining: secondsRemaining,
              totalModeSeconds: totalModeSeconds,
              initialIsRunning: isRunning,
              linkedTask: linkedTask,
              focusCategory: focusCategory,
              initialAmbience: selectedAmbience,
              initialVolume: ambienceVolume,
              linkedPlannerItem: linkedPlannerItem,
              ambienceOptions: ambienceOptions,
              onToggleSubtask: onToggleSubtask,
              onCaptureDistraction: onCaptureDistraction,
              onAmbienceChanged: onAmbienceChanged,
              onVolumeChanged: onVolumeChanged,
              onSyncBack: onSyncBack,
            ),
          );
        },
      ),
    );
  }

  @override
  State<PomodoroZenScreen> createState() => _PomodoroZenScreenState();
}

class _PomodoroZenScreenState extends State<PomodoroZenScreen>
    with SingleTickerProviderStateMixin {
  late int _seconds;
  late int _totalSeconds;
  late bool _isRunning;
  late String _ambience;
  late double _volume;
  Timer? _localTimer;
  late AnimationController _breathController;
  final TextEditingController _thoughtController = TextEditingController();
  int _quoteIndex = 0;

  static const List<Map<String, String>> _focusQuotes = [
    {
      'quote':
          'Clarity about what matters provides clarity about what does not.',
      'author': 'Cal Newport — Deep Work',
    },
    {
      'quote':
          'You do not rise to the level of your goals. You fall to the level of your systems.',
      'author': 'James Clear — Atomic Habits',
    },
    {
      'quote': 'Concentrate all your thoughts upon the work at hand.',
      'author': 'Alexander Graham Bell',
    },
    {
      'quote':
          'One Pomodoro at a time turns overwhelming mountains into simple steps.',
      'author': 'Francesco Cirillo',
    },
  ];

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSecondsRemaining;
    _totalSeconds = math.max(1, widget.totalModeSeconds);
    _isRunning = widget.initialIsRunning;
    _ambience = widget.initialAmbience;
    _volume = widget.initialVolume;
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (_isRunning) {
      _breathController.repeat(reverse: true);
      _startTick();
    }
  }

  void _startTick() {
    _localTimer?.cancel();
    final isStopwatch = widget.initialFocusModeIndex == 3;
    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (isStopwatch) {
          _seconds++;
        } else if (_seconds > 0) {
          _seconds--;
        } else {
          _isRunning = false;
          _breathController.stop();
          timer.cancel();
        }
      });
    });
  }

  void _toggleRun() {
    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _breathController.repeat(reverse: true);
        _startTick();
      } else {
        _localTimer?.cancel();
        _breathController.stop();
        _breathController.value = 0.0;
      }
    });
  }

  void _addBoostMinutes(int mins) {
    setState(() {
      _seconds += mins * 60;
      _totalSeconds = math.max(_totalSeconds, _seconds);
    });
  }

  void _exitZen() {
    _localTimer?.cancel();
    widget.onSyncBack(_seconds, _isRunning);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _localTimer?.cancel();
    _breathController.dispose();
    _thoughtController.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.initialFocusModeIndex) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.moduleNotes;
      case 3:
        return AppColors.moduleVault;
      case 0:
      default:
        return AppColors.moduleTime;
    }
  }

  String _formatTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    if (widget.initialFocusModeIndex == 3) {
      return (_seconds % 3600) / 3600.0;
    }
    return ((_totalSeconds - _seconds) / _totalSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = context.text;
    final accent = _accentColor;
    final quote = _focusQuotes[_quoteIndex % _focusQuotes.length];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _exitZen();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.floatingBarBackground,
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.25),
              radius: 1.15,
              colors: [
                accent.withValues(alpha: 0.22),
                AppColors.floatingBarBackground,
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  // 1. Header Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: AppRadius.radiusFull,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.self_improvement_rounded,
                              size: 14,
                              color: accent,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ZEN FOCUS CHAMBER • ROUND ${widget.currentRound}/${widget.totalRounds}',
                              style: AppTextStyles.overline.copyWith(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _exitZen,
                        tooltip: 'Exit Zen Mode',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(
                          Icons.fullscreen_exit_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Linked Task Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: AppRadius.radiusFull,
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 15, color: accent),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.linkedTask,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.2),
                            borderRadius: AppRadius.radiusFull,
                          ),
                          child: Text(
                            widget.focusCategory,
                            style: textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 3. Large Breathing Zen Dial
                  SizedBox(
                    width: 236,
                    height: 236,
                    child: AnimatedBuilder(
                      animation: _breathController,
                      builder: (context, child) {
                        final pulse = _isRunning
                            ? _breathController.value
                            : 0.0;
                        return CustomPaint(
                          painter: _ZenDialPainter(
                            progress: _progress,
                            pulse: pulse,
                            accentColor: accent,
                            isRunning: _isRunning,
                          ),
                          child: child,
                        );
                      },
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(_seconds),
                              style: AppTextStyles.timerHero.copyWith(
                                color: Colors.white,
                                fontSize: 52,
                                letterSpacing: -1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isRunning
                                  ? 'Breathe deeply • Stay present'
                                  : 'Paused in Zen Chamber',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // 4. Primary Controls + Quick Boosts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.initialFocusModeIndex != 3) ...[
                        _buildZenPillButton(
                          label: '+1m',
                          onTap: () => _addBoostMinutes(1),
                        ),
                        const SizedBox(width: 10),
                      ],
                      FilledButton.icon(
                        onPressed: _toggleRun,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(156, 48),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.radiusFull,
                          ),
                        ),
                        icon: Icon(
                          _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 22,
                        ),
                        label: Text(
                          _isRunning ? 'Pause Sprint' : 'Resume Sprint',
                          style: AppTextStyles.buttonLabel.copyWith(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (widget.initialFocusModeIndex != 3) ...[
                        const SizedBox(width: 10),
                        _buildZenPillButton(
                          label: '+5m',
                          onTap: () => _addBoostMinutes(5),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 5. Soundscape Mixer Strip
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: AppRadius.radiusMd,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Zen Soundscape Mixer',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _ambience == 'Mute'
                                  ? 'Muted'
                                  : '$_ambience • ${(_volume * 100).round()}%',
                              style: textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.ambienceOptions.map((opt) {
                            final name = opt['name'] as String;
                            final icon = opt['icon'] as IconData;
                            final selected = _ambience == name;
                            return InkWell(
                              onTap: () {
                                setState(() => _ambience = name);
                                widget.onAmbienceChanged?.call(name);
                              },
                              borderRadius: AppRadius.radiusFull,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? accent.withValues(alpha: 0.22)
                                      : Colors.white.withValues(alpha: 0.06),
                                  borderRadius: AppRadius.radiusFull,
                                  border: Border.all(
                                    color: selected
                                        ? accent
                                        : Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 13,
                                      color: selected ? accent : Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      name,
                                      style: textTheme.labelSmall?.copyWith(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_ambience != 'Mute') ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.volume_down_rounded,
                                size: 16,
                                color: Colors.white60,
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: accent,
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                    trackHeight: 3,
                                  ),
                                  child: Slider(
                                    value: _volume,
                                    onChanged: (v) {
                                      setState(() => _volume = v);
                                      widget.onVolumeChanged?.call(v);
                                    },
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.volume_up_rounded,
                                size: 16,
                                color: Colors.white60,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6. Quick Brain-Dump Distraction Capture Pad
                  if (widget.onCaptureDistraction != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            size: 16,
                            color: accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _thoughtController,
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontSize: 12.5,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: false,
                                hintText:
                                    'Park a distracting thought without leaving flow...',
                                hintStyle: textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onSubmitted: (val) => _submitThought(),
                            ),
                          ),
                          IconButton(
                            onPressed: _submitThought,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.add_circle_rounded,
                              color: accent,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 7. Motivational Quote Footer (tap to cycle)
                  GestureDetector(
                    onTap: () => setState(() => _quoteIndex++),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Text(
                            '"${quote['quote']}"',
                            textAlign: TextAlign.center,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            quote['author']!,
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.45),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  void _submitThought() {
    final text = _thoughtController.text.trim();
    if (text.isEmpty) return;
    widget.onCaptureDistraction?.call(text);
    _thoughtController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Parked thought: "$text"'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildZenPillButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
        minimumSize: const Size(52, 42),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionBold.copyWith(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ZenDialPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final Color accentColor;
  final bool isRunning;

  const _ZenDialPainter({
    required this.progress,
    required this.pulse,
    required this.accentColor,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 14;

    if (isRunning) {
      final outerAura = Paint()
        ..color = accentColor.withValues(alpha: 0.08 + 0.12 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 + 12 * pulse;
      canvas.drawCircle(center, radius, outerAura);
    }

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0.001) {
      final sweep = 2 * math.pi * progress;
      final arcPaint = Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ZenDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.isRunning != isRunning;
  }
}
