import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../domain/entities/planner_item_entity.dart';

class PomodoroFocusCard extends StatefulWidget {
  final int focusModeIndex;
  final int currentRound;
  final int totalRounds;
  final double timerProgress;
  final String formattedTime;
  final bool isTimerRunning;
  final String linkedTask;
  final VoidCallback onToggleTimer;
  final VoidCallback onResetTimer;
  final VoidCallback onSkipSession;
  final VoidCallback onChangeTask;

  // Extended Focus 2.0 optional props
  final String focusCategory;
  final int estimatedPomodoros;
  final int completedTaskPomodoros;
  final bool strictMode;
  final String selectedAmbience;
  final PlannerItemEntity? linkedPlannerItem;
  final ValueChanged<ChecklistItem>? onToggleSubtask;
  final VoidCallback? onMarkTaskDone;
  final ValueChanged<int>? onAddMinutes;
  final VoidCallback? onFinishStopwatch;
  final VoidCallback? onOpenZenMode;

  const PomodoroFocusCard({
    super.key,
    required this.focusModeIndex,
    required this.currentRound,
    required this.totalRounds,
    required this.timerProgress,
    required this.formattedTime,
    required this.isTimerRunning,
    required this.linkedTask,
    required this.onToggleTimer,
    required this.onResetTimer,
    required this.onSkipSession,
    required this.onChangeTask,
    this.focusCategory = 'Deep Work',
    this.estimatedPomodoros = 4,
    this.completedTaskPomodoros = 2,
    this.strictMode = false,
    this.selectedAmbience = 'Mute',
    this.linkedPlannerItem,
    this.onToggleSubtask,
    this.onMarkTaskDone,
    this.onAddMinutes,
    this.onFinishStopwatch,
    this.onOpenZenMode,
  });

  @override
  State<PomodoroFocusCard> createState() => _PomodoroFocusCardState();
}

class _PomodoroFocusCardState extends State<PomodoroFocusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _showSubtasks = false;
  bool _expandLinkedTaskText = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isTimerRunning) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PomodoroFocusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTimerRunning != oldWidget.isTimerRunning) {
      if (widget.isTimerRunning) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  LinearGradient _resolveGradient(int mode) {
    switch (mode) {
      case 1:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF047857), Color(0xFF10B981), Color(0xFF065F46)],
        );
      case 2:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0369A1), Color(0xFF0EA5E9), Color(0xFF0284C7)],
        );
      case 3:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFF4C1D95)],
        );
      case 0:
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFB45309)],
        );
    }
  }

  String _resolveModeLabel(int mode) {
    switch (mode) {
      case 1:
        return '☕ SHORT BREAK';
      case 2:
        return '🌴 LONG BREAK';
      case 3:
        return '♾️ FLOW STOPWATCH';
      case 0:
      default:
        return '⚡ DEEP WORK SPRINT';
    }
  }

  Color _resolveShadowColor(int mode) {
    switch (mode) {
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

  Color _resolveButtonColor(int mode) {
    switch (mode) {
      case 1:
        return const Color(0xFF047857);
      case 2:
        return const Color(0xFF0284C7);
      case 3:
        return const Color(0xFF5B21B6);
      case 0:
      default:
        return AppColors.moduleTimeDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = widget.focusModeIndex;
    final heroGradient = _resolveGradient(mode);
    final modeLabel = _resolveModeLabel(mode);
    final shadowColor = _resolveShadowColor(mode);
    final buttonColor = _resolveButtonColor(mode);
    final isStopwatch = mode == 3;
    final linkedItem = widget.linkedPlannerItem;
    final hasChecklist = linkedItem != null && linkedItem.checklist.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: heroGradient,
        borderRadius: AppRadius.radiusLg,
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Top Bar: Mode Badge, Strict Lock, Round Indicators & Zen Mode Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: AppRadius.radiusFull,
                ),
                child: Text(
                  modeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (widget.strictMode) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: AppRadius.radiusFull,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'STRICT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'Round ${widget.currentRound}/${widget.totalRounds}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                children: List.generate(
                  widget.totalRounds,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: i + 1 == widget.currentRound ? 12 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.radiusFull,
                      color: i < widget.currentRound
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              if (widget.onOpenZenMode != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: widget.onOpenZenMode,
                  borderRadius: AppRadius.radiusFull,
                  child: Tooltip(
                    message: 'Full-Screen Zen Focus',
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 2. Precision CustomPainter Radial Progress Dial + Breathing Pulse
          SizedBox(
            width: 168,
            height: 168,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulseVal = widget.isTimerRunning
                    ? _pulseController.value
                    : 0.0;
                return CustomPaint(
                  painter: _FocusDialPainter(
                    progress: widget.timerProgress.clamp(0.0, 1.0),
                    pulseValue: pulseVal,
                    isRunning: widget.isTimerRunning,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category micro-tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: AppRadius.radiusFull,
                      ),
                      child: Text(
                        widget.focusCategory.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.formattedTime,
                      style: AppTextStyles.timerHero.copyWith(
                        color: Colors.white,
                        fontSize: 36,
                        letterSpacing: -1,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.isTimerRunning
                          ? (isStopwatch
                                ? 'Flow state active...'
                                : (mode == 0
                                      ? 'Stay in the zone...'
                                      : 'Breathe and relax...'))
                          : 'Ready to start',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.selectedAmbience != 'Mute') ...[
                      const SizedBox(height: 5),
                      _buildMiniEqualizerBadge(),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Quick Time Boosts (+1m / +5m) or Finish Flow Session
          if (!isStopwatch && widget.onAddMinutes != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuickAdjustPill(
                    label: '+1m',
                    tooltip: 'Add 1 minute',
                    onTap: () => widget.onAddMinutes!(1),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickAdjustPill(
                    label: '+5m',
                    tooltip: 'Add 5 minutes',
                    onTap: () => widget.onAddMinutes!(5),
                  ),
                  if (widget.onOpenZenMode != null) ...[
                    const SizedBox(width: 8),
                    _buildQuickAdjustPill(
                      label: 'Zen Mode',
                      icon: Icons.self_improvement_rounded,
                      tooltip: 'Enter Full-Screen Zen Mode',
                      onTap: widget.onOpenZenMode!,
                    ),
                  ],
                ],
              ),
            )
          else if (isStopwatch && widget.onFinishStopwatch != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildQuickAdjustPill(
                    label: 'Finish & Log Flow',
                    icon: Icons.check_circle_outline_rounded,
                    tooltip: 'Save elapsed stopwatch session',
                    onTap: widget.onFinishStopwatch!,
                  ),
                  if (widget.onOpenZenMode != null) ...[
                    const SizedBox(width: 8),
                    _buildQuickAdjustPill(
                      label: 'Zen Mode',
                      icon: Icons.self_improvement_rounded,
                      tooltip: 'Enter Full-Screen Zen Mode',
                      onTap: widget.onOpenZenMode!,
                    ),
                  ],
                ],
              ),
            ),

          // 4. Linked Task Capsule + Pomodoro Target Progress
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            child: Column(
              children: [
                GestureDetector(
                  onTap: widget.onChangeTask,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.track_changes_rounded,
                              size: 13,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Focusing on: "${widget.linkedTask}"',
                                maxLines: _expandLinkedTaskText ? null : 2,
                                overflow: _expandLinkedTaskText
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: AppRadius.radiusFull,
                              ),
                              child: Text(
                                '🍅 ${widget.completedTaskPomodoros}/${widget.estimatedPomodoros}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.edit_rounded,
                              size: 12,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                        if (_expandLinkedTaskText &&
                            linkedItem != null &&
                            linkedItem.notes.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            linkedItem.notes,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 11,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (widget.linkedTask.length > 48 ||
                    (linkedItem != null && linkedItem.notes.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: InkWell(
                      onTap: () => setState(
                        () => _expandLinkedTaskText = !_expandLinkedTaskText,
                      ),
                      borderRadius: AppRadius.radiusFull,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expandLinkedTaskText
                                  ? 'Show less'
                                  : 'Show more details',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              _expandLinkedTaskText
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Optional Linked Planner Task Subtasks & Quick Complete Bar
          if (linkedItem != null && !linkedItem.isDone) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (hasChecklist)
                  InkWell(
                    onTap: () => setState(() => _showSubtasks = !_showSubtasks),
                    borderRadius: AppRadius.radiusFull,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: AppRadius.radiusFull,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.checklist_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Subtasks ${linkedItem.checklistDoneCount}/${linkedItem.checklist.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            _showSubtasks
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.onMarkTaskDone != null)
                  InkWell(
                    onTap: widget.onMarkTaskDone,
                    borderRadius: AppRadius.radiusFull,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: AppRadius.radiusFull,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.task_alt_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Complete Task',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: (_showSubtasks && hasChecklist)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2),
                          borderRadius: AppRadius.radiusMd,
                        ),
                        child: Column(
                          children: linkedItem.checklist.map((sub) {
                            return InkWell(
                              onTap: widget.onToggleSubtask != null
                                  ? () => widget.onToggleSubtask!(sub)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      sub.isDone
                                          ? Icons.check_box_rounded
                                          : Icons
                                                .check_box_outline_blank_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        sub.title,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: sub.isDone ? 0.6 : 0.95,
                                          ),
                                          fontSize: 11.5,
                                          decoration: sub.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
          const SizedBox(height: 14),

          // 5. Primary Timer Action Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reset Button
              IconButton.filledTonal(
                onPressed: widget.onResetTimer,
                tooltip: 'Reset Timer',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  fixedSize: const Size.square(38),
                  minimumSize: const Size.square(38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
              ),
              const SizedBox(width: 12),

              // Main Start/Pause Button
              ElevatedButton.icon(
                onPressed: widget.onToggleTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: buttonColor,
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 8,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.radiusFull,
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  widget.isTimerRunning
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 20,
                ),
                label: Text(
                  widget.isTimerRunning ? 'Pause' : 'Start Focus',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Skip Session Button
              IconButton.filledTonal(
                onPressed: widget.onSkipSession,
                tooltip: 'Skip Session',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  fixedSize: const Size.square(38),
                  minimumSize: const Size.square(38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.skip_next_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAdjustPill({
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.radiusFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.radiusFull,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniEqualizerBadge() {
    final v = widget.isTimerRunning ? _pulseController.value : 0.3;
    final heights = [
      4.0 + 6.0 * v,
      9.0 - 4.0 * v,
      5.0 + 5.0 * (1 - v),
      8.0 * v + 3.0,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: AppRadius.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final h in heights)
            Container(
              width: 2,
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          const SizedBox(width: 4),
          Text(
            widget.selectedAmbience,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom dial painter with 60 precision radial tick marks, breathing halo,
/// rounded progress arc, and glowing progress orb tip.
class _FocusDialPainter extends CustomPainter {
  final double progress;
  final double pulseValue;
  final bool isRunning;

  const _FocusDialPainter({
    required this.progress,
    required this.pulseValue,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = math.min(size.width, size.height) / 2;
    final dialRadius = outerRadius - 8;

    // 1. Breathing halo when running
    if (isRunning) {
      final haloPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.06 + (0.10 * pulseValue))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 + (6 * pulseValue);
      canvas.drawCircle(center, dialRadius, haloPaint);
    }

    // 2. 60 Radial Tick Marks around the dial
    const int tickCount = 60;
    final activeTicks = (progress * tickCount).round();
    final tickPaintActive = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final tickPaintInactive = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < tickCount; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / tickCount);
      final isMajor = i % 5 == 0;
      final innerR = dialRadius - (isMajor ? 13.0 : 10.5);
      final outerR = dialRadius - 7.5;
      final p1 = Offset(
        center.dx + innerR * math.cos(angle),
        center.dy + innerR * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerR * math.cos(angle),
        center.dy + outerR * math.sin(angle),
      );
      canvas.drawLine(
        p1,
        p2,
        i <= activeTicks ? tickPaintActive : tickPaintInactive,
      );
    }

    // 3. Track Ring
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5;
    canvas.drawCircle(center, dialRadius, trackPaint);

    // 4. Active Progress Arc
    if (progress > 0.001) {
      final sweepAngle = 2 * math.pi * progress;
      final arcPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: dialRadius),
        -math.pi / 2,
        sweepAngle,
        false,
        arcPaint,
      );

      // 5. Glowing Orb at the leading edge of the progress arc
      final endAngle = -math.pi / 2 + sweepAngle;
      final tipCenter = Offset(
        center.dx + dialRadius * math.cos(endAngle),
        center.dy + dialRadius * math.sin(endAngle),
      );
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipCenter, 7.5, glowPaint);

      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(tipCenter, 4.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FocusDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isRunning != isRunning;
  }
}
